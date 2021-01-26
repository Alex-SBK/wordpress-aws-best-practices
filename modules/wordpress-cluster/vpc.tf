provider "aws" {
  region = "us-west-2"
}

# ======= VPC  =======
# At first create VPC for our wordpress application
resource "aws_vpc" "vpc_for_wordpress" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "Wordpress_best_practice_vpc"
  }
}

# ======= PUBLIC SUBNETS ==========
# Now create 2 subnets for
# 2 separate availability Zones in one VPC
# for High availability and so on

# At first get from AWS info about availability zones in current region
# We'll create two subnets in different availability zones

# So we need to know which zones is available:
data "aws_availability_zones" "current_zones_info" {}

# And create the public subnets: A and B
resource "aws_subnet" "subnet_A_public" {
  vpc_id = aws_vpc.vpc_for_wordpress.id
  cidr_block = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.current_zones_info.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "00_Subnet_A_public"
  }
}

resource "aws_subnet" "subnet_B_public" {
  vpc_id = aws_vpc.vpc_for_wordpress.id
  cidr_block = "10.0.21.0/24"
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.current_zones_info.names[1]
  tags = {
    Name = "00_Subnet_B_public"
  }
}

# ======= VPC INTERNET GATEWAY =======
# Next create internet gateway (not NAT Gateway)
# And attach it with our VPC
resource "aws_internet_gateway" "main_gateway_for_wordpress" {
  vpc_id = aws_vpc.vpc_for_wordpress.id
  tags = {
    Name = "IGW_for_wordpress_vpc"
  }
}

# ======= Public route table =======
# Now let's create route table
# with default route to our internet gateway
# for public subnets.
# We want all traffic from all instances in our public subnets
# to go to our default internet gateway (to the Internet)
# So do the next:
resource "aws_route_table" "public_rt_for_public_subnets" {
  vpc_id = aws_vpc.vpc_for_wordpress.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_gateway_for_wordpress.id
  }
  tags = {
    Name = "public_RT"
  }
}

# Making subnets truly public by
# attaching them to our public route table:

# Public Subnet A
resource "aws_route_table_association" "alex-sbk-public-route-association-A" {
  route_table_id = aws_route_table.public_rt_for_public_subnets.id
  subnet_id = aws_subnet.subnet_A_public.id
}
# Public Subnet B
resource "aws_route_table_association" "alex-sbk-public-route-association-B" {
  route_table_id = aws_route_table.public_rt_for_public_subnets.id
  subnet_id = aws_subnet.subnet_B_public.id
}

# ======= PRIVATE SUBNETS (Application Servers)==========
# Now create server subnets for Wordpress Instances

# Private App subnet A
resource "aws_subnet" "subnet_A_private_app" {
  vpc_id = aws_vpc.vpc_for_wordpress.id
  cidr_block = "10.0.12.0/24"
  availability_zone = data.aws_availability_zones.current_zones_info.names[0]
  tags = {
    Name = "01_Subnet_A_private_app"
  }
}
# Private App subnet B
resource "aws_subnet" "subnet_B_private_app" {
  vpc_id = aws_vpc.vpc_for_wordpress.id
  cidr_block = "10.0.22.0/24"
  availability_zone = data.aws_availability_zones.current_zones_info.names[1]
  tags = {
    Name = "02_Subnet_B_private_app"
  }

}

# ======= PRIVATE SUBNETS (DATABASES)==========
# Now create database subnets for Wordpress Databases

# Private Data Subnet A
resource "aws_subnet" "subnet_A_private_data" {
  vpc_id = aws_vpc.vpc_for_wordpress.id
  cidr_block = "10.0.13.0/24"
  availability_zone = data.aws_availability_zones.current_zones_info.names[0]
  tags = {
    Name = "03_Subnet_A_private_data"
  }
}

# Private Data Subnet B
resource "aws_subnet" "subnet_B_private_data" {
  vpc_id = aws_vpc.vpc_for_wordpress.id
  cidr_block = "10.0.23.0/24"
  availability_zone = data.aws_availability_zones.current_zones_info.names[1]
  tags = {
    Name = "04_Subnet_B_private_data "
  }
}

# Create Elastic IP addresses for both public subnets
resource "aws_eip" "ip_of_subnet_A" {
  vpc = true
  tags = {
    Name = "Subnet-A-IP"
  }
}

resource "aws_eip" "ip_of_subnet_B" {
  vpc = true
  tags = {
    Name = "Subnet-B-IP"
  }
}

# Create NAT gateways in our public subnets
# And bind them with our public IP addresses:
# NAT-gateway it is something like instance
# so it should be situated in some subnet
# And to high availability we'll create two NAT-gateways in
# two separate public subnets:
resource "aws_nat_gateway" "NAT-A-Subnet" {
  allocation_id = aws_eip.ip_of_subnet_A.id
  subnet_id = aws_subnet.subnet_A_public.id
  tags = {
    Name = "Subnet-A-NAT-Gateway"
  }
}

resource "aws_nat_gateway" "NAT-B-Subnet" {
  allocation_id = aws_eip.ip_of_subnet_B.id
  subnet_id = aws_subnet.subnet_B_public.id
  tags = {
    Name = "Subnet-B-NAT-Gateway"
  }
}

# Create private route tables

resource "aws_route_table" "PrivateA-to-NAT-A" {
  vpc_id = aws_vpc.vpc_for_wordpress.id
  depends_on = [
    aws_nat_gateway.NAT-A-Subnet]
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.NAT-A-Subnet.id
  }
  tags = {
    Name = "Private-RT-To-Nat-A"
  }
}

resource "aws_route_table" "PrivateB-to-NAT-B" {
  vpc_id = aws_vpc.vpc_for_wordpress.id
  depends_on = [
    aws_nat_gateway.NAT-B-Subnet]
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.NAT-B-Subnet.id
  }
  tags = {
    Name = "Private-RT-Nat-B"
  }
}

# Associate our private subnets to our NAT gateways

# Private App subnet A
resource "aws_route_table_association" "association-subnet-app-A" {
  route_table_id = aws_route_table.PrivateA-to-NAT-A.id
  subnet_id = aws_subnet.subnet_A_private_app.id
}
# Private App subnet B
resource "aws_route_table_association" "association-subnet-app-B" {
  route_table_id = aws_route_table.PrivateB-to-NAT-B.id
  subnet_id = aws_subnet.subnet_B_private_app.id

}

# Data subnets has no routes to outside!


# ================== BASTION HOST scaling group ==================
# At first create security group for bastion host

resource "aws_security_group" "ssh_access" {
  name = "SSH-Access-For-Bastion-Host"
  description = "SSH-Access-For-Bastion-Host"
  vpc_id = aws_vpc.vpc_for_wordpress.id
  tags = {
    Name = "Bastion-Host-Security-group"
  }
  # Allow incoming SSH packets from anywhere
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port = 0
    protocol = -1
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"]
  }

}

# Create launch config for bastion hosts autoscaling group
resource "aws_launch_configuration" "wp_bastion_host_lc" {
  user_data = file("user_data.sh")
  image_id = "ami-0ac73f33a1888c64a"

  instance_type = "t2.micro"
  name = "Bastion-HOST-LC"

  # this key was previously created by me.
  key_name = "oregon"

  # Using our security group
  security_groups = [
    aws_security_group.ssh_access.id]

  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = false
  }
}

# Now create Auto scaling group for bastion host
resource "aws_autoscaling_group" "bastion-host-auto-scaling-group" {
  name = "bastion-host-ASG"
  launch_configuration = aws_launch_configuration.wp_bastion_host_lc.name
  max_size = 0
  min_size = 0
  vpc_zone_identifier = toset([
    aws_subnet.subnet_A_public.id,
    aws_subnet.subnet_B_public.id
  ])

  tag {
    key = "Name"
    propagate_at_launch = true
    value = "Bastion-host-ASG-node"
  }
}

# ======= CREATING EFS for wordpress VPC ==========
# At first create security group for EFS
resource "aws_security_group" "efs_security_group" {
  name = "EFS_security_group"
  description = "EFS_security_group"
  vpc_id = aws_vpc.vpc_for_wordpress.id
  tags = {
    Name = "EFS_security_group"
  }
  # Allow incoming SSH packets from anywhere
  ingress {
    from_port = 2049
    protocol = "tcp"
    to_port = 2049
    cidr_blocks = [
      "10.0.0.0/16"
    ]
    description = "Our default VPC"
  }
}

# Now create EFS filesystem
resource "aws_efs_file_system" "wordpress_efs" {
  creation_token = "efs-wordpress"
  tags = {
    Name = "wordpress-EFS"
  }
}
//# remember the ID of this EFS
//# for using it in bootstrap scripts:
//output "efs-id" {
//  value = aws_efs_file_system.wordpress_efs.id
//}

# Now create EFS mount targets for both subnets:
# For A subnet private app:
resource "aws_efs_mount_target" "wordpress_target_subnet_A_private_app" {
  file_system_id = aws_efs_file_system.wordpress_efs.id
  subnet_id = aws_subnet.subnet_A_private_app.id
}
# For B subnet private app:
resource "aws_efs_mount_target" "wordpress_target_subnet_B_private_app" {
  file_system_id = aws_efs_file_system.wordpress_efs.id
  subnet_id = aws_subnet.subnet_B_private_app.id
}

# ======= Creating Application Load Balancer (ALB) for wordpress scaling group =======

# At fist create security group for access to wordpress web application:
# For allowing 80 and 443 ports:
resource "aws_security_group" "web_access" {
  description = "Give incoming Access for 80 and 443 port"
  vpc_id = aws_vpc.vpc_for_wordpress.id
  tags = {
    Name = "Allow incoming HTTP and HTTPS connections"
  }
  # Allow incoming HTTP packets from anywhere
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "Allow incoming HTTP connections from anywhere"
  }
  # Allow incoming HTTPS packets from anywhere
  ingress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "Allow incoming HTTPS connections from anywhere"
  }
  # Allow all outbound requests:
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}


# Now create ALB itself:
resource "aws_lb" "wordpress_ALB" {
  name = "wordpress-app-load-balancer"
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.web_access.id
  ]
  subnets = [
    aws_subnet.subnet_A_public.id,
    aws_subnet.subnet_B_public.id
  ]
}

# Next: define LISTENER:
resource "aws_lb_listener" "wordpress_http" {
  load_balancer_arn = aws_lb.wordpress_ALB.arn
  port = 80
  protocol = "HTTP"
  # by default, return simple 404 page
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = "404"
    }
  }
}

# Next we have to create a target group for our ALB and ASG :)
resource "aws_lb_target_group" "wordpress_lb_target_group" {
  name = "wordpress-TG"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.vpc_for_wordpress.id
  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "wordpress" {
  listener_arn = aws_lb_listener.wordpress_http.arn
  priority = 100
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.wordpress_lb_target_group.arn
  }
  condition {
    path_pattern {
      values = ["*"]
    }

  }
}

# ======= CREATING AUTOSCALING group for wordpress ASG ==========
# Next: create launch config for wordpress instances autoscaling group:
resource "aws_launch_configuration" "wordpress_node_lc" {
  image_id = "ami-0a36eb8fadc976275"

  instance_type = "t2.micro"
  name = "Wordpress-node-LC"

  # this key was previously created by me.
  key_name = "oregon"

  # Using next security groups:
  security_groups = [
    aws_security_group.ssh_access.id,
    aws_security_group.web_access.id
  ]

  # In this initial script we'll do the next:
  # 1) setup apache
  # 2) mount efs target
  # 3) install wordpress
  user_data = templatefile("initial_shell_script.sh", {
    efs_id = aws_efs_file_system.wordpress_efs.id
  })

  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = false
  }
}

# Now create ASG for wordpress instances:
resource "aws_autoscaling_group" "wordpress_auto_scaling_group" {
  name = "wordpress-instances-ASG"
  launch_configuration = aws_launch_configuration.wordpress_node_lc.name
  max_size = 0
  min_size = 0
  vpc_zone_identifier = toset([
    aws_subnet.subnet_A_private_app.id,
    aws_subnet.subnet_B_private_app.id
  ])

  tag {
    key = "Name"
    propagate_at_launch = true
    value = "Wordpress-ASG-node"
  }
  target_group_arns = [
    aws_lb_target_group.wordpress_lb_target_group.arn]
  depends_on = [aws_lb_target_group.wordpress_lb_target_group]
}

output "lb_dns_name" {
  value = aws_lb.wordpress_ALB.dns_name
}