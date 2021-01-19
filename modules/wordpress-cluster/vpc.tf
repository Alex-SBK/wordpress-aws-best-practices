 # At first create VPC for our worpress application

resource "aws_vpc" "alex_sbk_vpc_for_wordpress" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "alex_sbk_vpc_for_worpress_best_practice"
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

 # Now cteare 2 subnets for
 # 2 separate Aviability Zones in one VPC
 # for hight Aviability and so on

 # At first get info about Avalibility zones in current region
 data "aws_availability_zones" "current_zones_info" {

 }
 # And create the subnets: A and B

 resource "aws_subnet" "alex_sbk_wordpress_subnets" {

  vpc_id = aws_vpc.alex_sbk_vpc_for_wordpress.id
   for_each = var.subnets
   cidr_block = each.value.cidr_block
  availability_zone = data.aws_availability_zones.current_zones_info.names[each.value.av_zone_index]
  tags = {
    Name = "Alex-Sbk-wordpress-subnet-${each.value.name}"
  }
}