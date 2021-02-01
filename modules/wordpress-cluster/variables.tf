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

variable "username" {
  description = "Database root username"
  type = string
  default = "root"
}

variable "dbname" {
  description = "Database name for wordpress"
  type = string
  default = "wordpress_base"
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

variable "pem_key_name" {
  description = "name of pem key for ssh access to bastion and wordpress instances"
  type = string
  default = "oregon.pem"
}