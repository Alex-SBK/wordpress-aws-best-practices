# ------------------------------
# Wordpress initial provisioning
# ------------------------------

# For provisioning we have to generate some files
# And use Ansible for pushing some files to EFS share
# over our Bastion Host:

# Gathering information about bastion public IP
data "aws_instance" "bastion_info" {
  depends_on = [aws_autoscaling_group.bastion-host-auto-scaling-group]
  filter {
    name = "tag:Name"
    values = ["Bastion-host-ASG-node"]
  }
}

# Render a template of ansible inventory file
data "template_file" "inventory" {
  template = file("${path.module}/files/ansible/inventory.tpl")
  vars = {
    bastion_ip = data.aws_instance.bastion_info.public_ip
    path_to_ssh_pem_key = "${path.cwd}/ssh_private_keys/${var.pem_key_name}"
  }
}

# Create local ansible inventory file based on rendered content
resource "local_file" "inventory" {
  filename = "${path.module}/files/ansible/inventory.txt"
  content = data.template_file.inventory.rendered
}

# Render content of wp-config file
data "template_file" "wp-config" {
  template = file("${path.module}/files/misc/wp-config-sample.tpl.php")
  vars = {
    db_port = aws_db_instance.mariadb_wordpress.port
    db_host = aws_db_instance.mariadb_wordpress.address
    db_user = var.username
    db_pass = var.password
    db_name = var.dbname
  }
}

# Create local wp-config.php file for uploading
# it to EFS share over bastion host
# using ansible playbook
resource "local_file" "wp-config" {
  filename = "${path.module}/files/misc/wp-config.php"
  content = data.template_file.wp-config.rendered
}

# Execute our ansible playbook
resource "null_resource" "ansible_provision" {
  depends_on = [
    local_file.inventory,
    local_file.wp-config
  ]
  triggers = {
    template = data.template_file.inventory.rendered
    template = data.template_file.wp-config.rendered
  }
  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/files/ansible/inventory.txt ${path.module}/files/ansible/playbook.yml"
  }
}