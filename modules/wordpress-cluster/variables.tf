variable "server_port" {
  description = "The port server will use for HTTP requests"
  type = number
  default = 80
}

variable "password" {
  description = "database password"
  type = string
  default = "123456Aa=="
}

variable "bastion_amount" {
  description = "Amount of bastion hosts"
  type = number
  default = 1
}

variable "wordpress_inst_amount" {
  description = "Amount of wordpress instance hosts"
  type = number
  default = 2
}