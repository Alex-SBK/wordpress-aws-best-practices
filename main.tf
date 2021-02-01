module "wordpress-cluster" {
  source = "./modules/wordpress-cluster"
  bastion_amount = 1
  wordpress_inst_amount = 2
  dbname = "wordpress_base"
  server_port = 80
  username = "rhombus"
  password = "123456Aa##"
  pem_key_name = "oregon.pem"
}