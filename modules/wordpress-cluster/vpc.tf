provider "aws" {
  region = "us-west-2"
}

# ----------
#    VPC
# ----------

# At first create VPC for our wordpress application
resource "aws_vpc" "vpc_for_wordpress" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  instance_tenancy = "default"
  tags = {
    Name = "Wordpress_best_practice_vpc"
  }
}

# ---------------------------------
#      << PUBLIC SUBNETS >>
# ---------------------------------

# Now create A and B subnets for
# 2 separate availability Zones in one VPC
# for High availability and so on

# At first get from AWS info about availability zones in current region
# We'll create two subnets in different availability zones


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

# ------------------------------------
#      << VPC INTERNET GATEWAY >>
# ------------------------------------

# Next create internet gateway (not NAT Gateway!)
# And attach it with our VPC
resource "aws_internet_gateway" "main_gateway_for_wordpress" {
  vpc_id = aws_vpc.vpc_for_wordpress.id
  tags = {
    Name = "IGW_for_wordpress_vpc"
  }
}

# ----------------------------------
#      << PUBLIC ROUTE TABLE >>
# ----------------------------------

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



# -------------------------------------------------------
#      << PRIVATE SUBNETS (Application Servers) >>
# -------------------------------------------------------

# Now create the server subnets for Wordpress Instances
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



# ---------------------------------------------
#      << PRIVATE SUBNETS (DATABASES) >>
# ---------------------------------------------

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


# -----------------------------------
# Auto scaling group for BASTION HOST
# -----------------------------------

# Create launch config for bastion hosts autoscaling group
resource "aws_launch_configuration" "wp_bastion_host_lc" {
  depends_on = [aws_efs_mount_target.subnet_B_private_app]
   user_data = templatefile("bastion_boot_start.sh", {
    efs_id = aws_efs_file_system.wordpress_efs.id
  })
  image_id = "ami-0a36eb8fadc976275"
  instance_type = "t2.micro"
  name = "Bastion-HOST-LC"

  # this key was previously created by me.
  key_name = "oregon"

  # Using our security group
  security_groups = [
    aws_security_group.efs_security_group.id]

  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = false
  }

}

# Now create Auto scaling group for bastion host
resource "aws_autoscaling_group" "bastion-host-auto-scaling-group" {

  name = "bastion-host-ASG"
  launch_configuration = aws_launch_configuration.wp_bastion_host_lc.name
  max_size = var.bastion_amount
  min_size = var.bastion_amount
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
# --------------------------------------------------------------------
# Creating Application Load Balancer (ALB) for wordpress scaling group
# --------------------------------------------------------------------
# Now create ALB itself:
resource "aws_lb" "wordpress_ALB" {
  name = "wordpress-app-load-balancer"
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.web_access.id
  ]
  # use public networks!
  # Otherwise, outside users will not have access to your load balancer
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
    path = "/index.php"
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

# ------------------------------------------
# Create AUTOSCALING group for wordpress ASG
# ------------------------------------------

# Next: create launch config for wordpress instances autoscaling group:
resource "aws_launch_configuration" "wordpress_node_lc" {
  depends_on = [
    aws_efs_mount_target.subnet_B_private_app,
    aws_efs_mount_target.subnet_A_private_app
  ]
  image_id = "ami-0a36eb8fadc976275"
  instance_type = "t2.micro"
  name = "Wordpress-node-LC"

  # this key was previously created by me.
  key_name = "oregon"

  # Using next security groups:
  security_groups = [
    aws_security_group.efs_security_group.id
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
  name = "wordpress-ASG"
  launch_configuration = aws_launch_configuration.wordpress_node_lc.name
  max_size = var.wordpress_inst_amount
  min_size = var.wordpress_inst_amount
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

# --------------------------------
# ======= AWS RDS Database =======
# --------------------------------

//# Create database subnet group:
//resource "aws_db_subnet_group" "wordpress_db_subn_group" {
//  subnet_ids = [
//    aws_subnet.subnet_A_private_data.id
//  ]
//  name = "wordpressgrp"
//  tags = {
//    Name = "wordpress-sbnе-grp"
//  }
//}
//
//# Create security group for RDS
//resource "aws_security_group" "wordpress_maria_database" {
//  name = "wordpress_DB_SG"
//  description = "managed by terraform for wordpress database"
//  vpc_id = aws_vpc.vpc_for_wordpress.id
//  tags = {
//    Name = "wrdpss_maria_db_SG"
//  }
//
//  ingress {
//    from_port = 3306
//    protocol = "tcp"
//    to_port = 3306
//    cidr_blocks = ["0.0.0.0/0"]
//    security_groups = [aws_security_group.web_access.id]
//   }
//  ingress {
//    protocol    = "icmp"
//    from_port   = -1
//    to_port     = -1
//    cidr_blocks = [aws_vpc.vpc_for_wordpress.cidr_block]
//    description = "PING from inside"
//  }
//  egress {
//    from_port = 0
//    protocol = "-1"
//    to_port = 0
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//}
//
//resource "aws_db_instance" "mariadb_wordpress" {
//  allocated_storage = 20
//  storage_type = "gp2"
//  engine = "mariadb"
//  engine_version = "10.1.14"
//  instance_class = "db.t2.micro"
//  name = "mariadb"
//  username = "root"
//  password = var.password
//  vpc_security_group_ids = [aws_security_group.wordpress_maria_database.id]
//  db_subnet_group_name = aws_db_subnet_group.wordpress_db_subn_group.name
//  skip_final_snapshot = true
//}



