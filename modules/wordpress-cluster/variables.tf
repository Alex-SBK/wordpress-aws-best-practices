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

variable "subnets" {
  description = "Map of subnets parameters"
  type = map

  default = {
    subnetdA = {
      cidr_block = "10.0.11.0/24"
      name = "SubnetA"
      av_zone_index = 0
    }
    subnetB = {
      cidr_block = "10.0.21.0/24"
      name = "SubnetB"
      av_zone_index = 1
    }
  }

}