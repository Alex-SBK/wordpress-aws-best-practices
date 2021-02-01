# This is dns name for our Application Load Balancer!
output "lb_dns_name" {
  value = aws_lb.wordpress_ALB.dns_name
}

output "bastion_host_public_IP" {
  value = data.aws_instance.bastion_info.public_ip
}

output "database_address" {
  value = aws_db_instance.mariadb_wordpress.address
}
