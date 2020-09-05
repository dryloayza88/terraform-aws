output "alb_dns_name" {
  value       = aws_lb.lb_example.dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  val = aws
  value       = aws_autoscaling_group.autoscaling_group_example.name
  description = "The name of the Auto Scaling group"
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
  description = "The ID of the Security group attached to the load balancer"
}