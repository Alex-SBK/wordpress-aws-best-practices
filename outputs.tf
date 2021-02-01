output "ALB_adress" {
  value = module.wordpress-cluster.lb_dns_name
}

output "Bastion_Host_ip" {
  value = module.wordpress-cluster.bastion_host_public_IP
}

output "database_address" {
  value = module.wordpress-cluster.database_address
}