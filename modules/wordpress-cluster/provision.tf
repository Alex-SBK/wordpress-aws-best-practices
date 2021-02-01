data "aws_instance" "bastion_info" {
  depends_on = [aws_autoscaling_group.bastion-host-auto-scaling-group]
  filter {
    name = "tag:Name"
    values = ["Bastion-host-ASG-node"]
  }
}

data "template_file" "inventory" {
  template = file("./files/ansible/inventory.tpl")
  vars = {
    bastion_ip = data.aws_instance.bastion_info.public_ip
  }
}

resource "local_file" "inventory" {
  filename = "./files/ansible/inventory.txt"
  content = data.template_file.inventory.rendered
}

data "template_file" "wp-config" {
  template = file("./files/misc/wp-config-sample.tpl.php")
  vars = {
    db_port = aws_db_instance.mariadb_wordpress.port
    db_host = aws_db_instance.mariadb_wordpress.address
    db_user = var.username
    db_pass = var.password
    db_name = var.dbname
  }
}

resource "local_file" "wp-config" {
  filename = "./files/misc/wp-config.php"
  content = data.template_file.wp-config.rendered
}

resource "null_resource" "ansible_provision" {
  depends_on = [
    local_file.inventory,
    local_file.wp-config
  ]
  provisioner "local-exec" {
    command = "ansible-playbook ./files/ansible/playbook.yml"
  }
}