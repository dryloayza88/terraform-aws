terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state-diego2"
    key = "stage/services/webserver-cluster/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt = true
  }
}

locals {
  http_port     = 80
  any_port      = 0
  any_protocol  = "-1"
  tcp_protocol  = "tcp"
  all_ips       = "0.0.0.0/0"
}

resource "aws_security_group" "instance_security_group" {
  name = "${var.cluster_name}-instance"
  ingress {
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }
}


resource "aws_launch_configuration" "launch_configuration_example" {
  image_id = "ami-0c55b159cbfafe1f0"
  instance_type = var.instance_type
  security_groups = [aws_security_group.instance_security_group.id]
  user_data = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default_vpc.id
}

resource "aws_autoscaling_group" "autoscaling_group_example" {
  launch_configuration  = aws_launch_configuration.launch_configuration_example.name
  vpc_zone_identifier   = data.aws_subnet_ids.default.ids
  target_group_arns = [aws_lb_target_group.asg_lb_target_group.arn]
  health_check_type = "ELB"

  max_size              = var.max_size
  min_size              = var.min_size

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = var.cluster_name
  }
}

resource "aws_lb" "lb_example" {
  name = "${var.cluster_name}-alb"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb_security_group.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb_example.arn
  port = local.http_port
  protocol = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port = local.http_port
  to_port = local.http_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "egress"
  security_group_id = aws_security_group.alb.id

  from_port = local.http_port
  to_port = local.http_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_lb_target_group" "asg_lb_target_group" {
  name = "terraform-asg-example"
  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default_vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg_lb_listener_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg_lb_target_group.arn
  }
  condition {}
}

data "terraform_remote_state" "db" {
  backend = "s3"
  config {
    bucket  = var.db_remote_state_bucket
    key     = var.db_remote_state_key
    region  = "us-east-1"
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh"

  vars = {
    server_port = 80
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }
}

