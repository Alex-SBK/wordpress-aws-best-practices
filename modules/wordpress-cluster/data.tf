# So we need to know which zones is available:
data "aws_availability_zones" "current_zones_info" {}

data "aws_instance" "bastion_info" {
  depends_on = [aws_autoscaling_group.bastion-host-auto-scaling-group]

  filter {
    name = "tag:Name"
    values = ["Bastion-host-ASG-node"]
  }
}