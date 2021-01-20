variable "wordpress_instance_security_group_name" {
  description = "The name of the security group for the EC2 wordpress Instances"
  type        = string
  default     = "Alex-SBK-security-group"
}

variable "server_port" {
  description = "The port server will use for HTTP requests"
  type = number
  default = 80
}

