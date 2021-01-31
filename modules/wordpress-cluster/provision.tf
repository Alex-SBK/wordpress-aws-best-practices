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

resource "null_resource" "ansible_provision" {
  depends_on = [local_file.inventory]
  provisioner "local-exec" {
    command = "ansible-playbook ./files/ansible/playbook.yml"
  }

}