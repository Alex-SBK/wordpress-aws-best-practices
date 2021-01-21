 # At first create VPC for our wordpress application

resource "aws_vpc" "alex_sbk_vpc_for_wordpress" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "alex_sbk_vpc_for_wordpress_best_practice"
  }
}

 # Next create gateway
 # And attach it with our VPC
resource "aws_internet_gateway" "alex_sbk_gateway_for_worpress" {
  vpc_id = aws_vpc.alex_sbk_vpc_for_wordpress.id
  tags = {
    Name = "alex_sbk_igw_for_wordpress"
  }
}

 # ======= PUBLIC SUBNETS ==========

 # Now cteare 2 subnets for
 # 2 separate Aviability Zones in one VPC
 # for hight Aviability and so on

 # At first get info about Avalibility zones in current region
 data "aws_availability_zones" "current_zones_info" {

 }
 # And create the public subnets: A and B

 resource "aws_subnet" "alex_sbk_wordpress_subnetA_public" {

  vpc_id = aws_vpc.alex_sbk_vpc_for_wordpress.id
   cidr_block = "10.0.11.0/24"
   availability_zone = data.aws_availability_zones.current_zones_info.names[0]
  tags = {
    Name = "Alex-Sbk-wordpress-subnet-SubnetA_public"
  }
}

 resource "aws_subnet" "alex_sbk_wordpress_subnetB_public" {

   vpc_id = aws_vpc.alex_sbk_vpc_for_wordpress.id
   cidr_block = "10.0.21.0/24"
   availability_zone = data.aws_availability_zones.current_zones_info.names[1]
   tags = {
     Name = "Alex-Sbk-wordpress-subnet-SubnetB_public"
   }
 }

 # Now let's create route table
 # with default route for public subnets
 resource "aws_route_table" "alex-sbk-public_route_table_for_public_subnets" {
   vpc_id = aws_vpc.alex_sbk_vpc_for_wordpress.id
   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.alex_sbk_gateway_for_worpress.id
   }
   tags = {
     Name = "alex-sbk-public_route_table_for_public_subnets"
   }
 }

 # Make subnets really public
 # By adding public routes
 resource "aws_route_table_association" "alex-sbk-public-route-assotiation-A" {
   route_table_id = aws_route_table.alex-sbk-public_route_table_for_public_subnets.id
   subnet_id = aws_subnet.alex_sbk_wordpress_subnetA_public.id
 }
 resource "aws_route_table_association" "alex-sbk-public-route-assotiation-B" {
   route_table_id = aws_route_table.alex-sbk-public_route_table_for_public_subnets.id
   subnet_id = aws_subnet.alex_sbk_wordpress_subnetB_public.id
 }

 # ======= PRIVATE SUBNETS (SERVER)==========
 # Now create server subnets for Wordpress Instance

 resource "aws_subnet" "alex_sbk_wordpress_subnetA_private_app" {
   vpc_id = aws_vpc.alex_sbk_vpc_for_wordpress.id
   cidr_block = "10.0.12.0/24"
   availability_zone = data.aws_availability_zones.current_zones_info.names[0]
   tags = {
     Name = "Alex_sbk_wordpress_subnetA_private_app"
   }
 }
 resource "aws_subnet" "alex_sbk_wordpress_subnetB_private_app" {
   vpc_id = aws_vpc.alex_sbk_vpc_for_wordpress.id
   cidr_block = "10.0.22.0/24"
   availability_zone = data.aws_availability_zones.current_zones_info.names[0]
   tags = {
     Name = "Alex_sbk_wordpress_subnetB_private_app"
   }
 }

 # ======= PRIVATE SUBNETS (DATABASES)==========
 # Now create server subnets for Wordpress Instance

 # Now create server subnets for Wordpress Instance

 resource "aws_subnet" "alex_sbk_wordpress_subnetA_private_data" {
   vpc_id = aws_vpc.alex_sbk_vpc_for_wordpress.id
   cidr_block = "10.0.13.0/24"
   availability_zone = data.aws_availability_zones.current_zones_info.names[0]
   tags = {
     Name = "Alex_sbk_wordpress_subnetA_private_data"
   }
 }
 resource "aws_subnet" "alex_sbk_wordpress_subnetB_private_data" {
   vpc_id = aws_vpc.alex_sbk_vpc_for_wordpress.id
   cidr_block = "10.0.23.0/24"
   availability_zone = data.aws_availability_zones.current_zones_info.names[1]
   tags = {
     Name = "Alex_sbk_wordpress_subnetB_private_data "
   }
 }

 # Create Elastic IP adresses for both public subnets
 resource "aws_eip" "ip_of_subnet_A" {
   vpc = true
   tags = {
     Name = "Subnet-A-Nat-IP"
   }
 }

 resource "aws_eip" "ip_of_subnet_B" {
   vpc = true
   tags = {
     Name = "Subnet-B-Nat-IP"
   }
 }

 # Create NAT gateways for public subnets
 resource "aws_nat_gateway" "NAT-A-Subnet" {
   allocation_id = aws_eip.ip_of_subnet_A.id
   subnet_id = aws_subnet.alex_sbk_wordpress_subnetA_public.id
   tags = {
     Name = "SubnetA-NAT-Gateway"
   }
 }

 resource "aws_nat_gateway" "NAT-B-Subnet" {
   allocation_id = aws_eip.ip_of_subnet_B.id
   subnet_id = aws_subnet.alex_sbk_wordpress_subnetB_public.id
   tags = {
     Name = "SubnetB-NAT-Gateway"
   }
 }

 # Create private route tables
 resource "aws_route_table" "PrivateA-to-NAT-A" {
   vpc_id = aws_vpc.alex_sbk_vpc_for_wordpress.id
   depends_on = [aws_nat_gateway.NAT-A-Subnet]
   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_nat_gateway.NAT-A-Subnet.id
   }
   tags = {
     Name = "alex-sbk-private_route_table_for_subnetA-Private"
   }
 }

 resource "aws_route_table" "PrivateB-to-NAT-B" {
   vpc_id = aws_vpc.alex_sbk_vpc_for_wordpress.id
   depends_on = [aws_nat_gateway.NAT-B-Subnet]
   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_nat_gateway.NAT-B-Subnet.id
   }
   tags = {
     Name = "alex-sbk-private_route_table_for_subnetB-Private"
   }
 }

 # Associate our private subnets to NAT gateways
 resource "aws_route_table_association" "assotiation-subnet-app-A" {
   route_table_id = aws_route_table.PrivateA-to-NAT-A.id
   subnet_id = aws_subnet.alex_sbk_wordpress_subnetA_private_app.id
 }

 resource "aws_route_table_association" "assotiation-subnet-app-B" {
   route_table_id = aws_route_table.PrivateB-to-NAT-B.id
   subnet_id = aws_subnet.alex_sbk_wordpress_subnetB_private_app.id
 }

 # ================== BASTION HOST!! ==================
 # At first create security group

 resource "aws_security_group" "wordpess_bastion_ssh_access_group" {
   name = "SSH-Access-For-Bastion-Host"
   description = "SSH-Access-For-Bastion-Host"
   vpc_id = aws_vpc.alex_sbk_vpc_for_wordpress.id
   tags = {
     Name = "Bastion-Host_Security-group"
   }
   # Allow incoming SSH packets from anywhere
   ingress {
     from_port = 22
     protocol = "tcp"
     to_port = 22
     cidr_blocks = ["0.0.0.0/0"]
   }

//   # Allow all outbound requests
//   egress {
//     from_port = 0
//     protocol = -1
//     to_port = 0
//     cidr_blocks = ["0.0.0.0/0"]
//   }

 }

 # Create launch config for bastion hosts autoscaling group

 resource "aws_launch_configuration" "wordpress_bastion_host" {
   image_id = "ami-0e1ce3e0deb8896d2"
   instance_type = "t2.micro"
   name = "Bastion-HOST-LC"

   # Using our security group
   security_groups = [aws_security_group.wordpess_bastion_ssh_access_group.id]

   # Required when using a launch configuration with an auto scaling group.
   lifecycle {
     create_before_destroy = true
   }
 }

  # Now create Auto scaling group for bastion host


 resource "aws_autoscaling_group" "bastion-host-auto-scaling-group" {
   name = "bastion-host-ASG"
   launch_configuration = aws_launch_configuration.wordpress_bastion_host.name
   max_size = 1
   min_size = 1
   vpc_zone_identifier = toset([aws_subnet.alex_sbk_wordpress_subnetA_public.id,
     aws_subnet.alex_sbk_wordpress_subnetB_public.id])

   tag {
     key = "Name"
     propagate_at_launch = true
     value = "bastion-host-for-wordpress"
   }

 }