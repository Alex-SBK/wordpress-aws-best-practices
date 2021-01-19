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