variable "cluster_name" {
  description = "The name to use to namespace all the resources in the cluster"
  type        = string
  default     = "webservers-stage"
}

variable "db_remote_state_bucket" {
  description = "The name of the s3 buckets used for the database's remote state storage"
  type        = string
}

variable "db_remote_state_key" {
  description = "The name of the key in s3 bucket used for the database's remote state storage"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 instances to run"
  type        = string
}

variable "min_size" {
  description = "The minimum number of EC instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "The maximum number of EC instances in the ASG"
  type        = number
}