# ------------------------------------------------------
# Create Elastic IP addresses for A and B public subnets
# ------------------------------------------------------

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

# -----------------------------------------
# Create NAT gateways in our public subnets
# -----------------------------------------

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

# ---------------------------
# Create private route tables
# ---------------------------
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

# -------------------------------------------------
# Associate our private subnets to our NAT gateways
# -------------------------------------------------

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

# Data subnets has no routes to outside (to NAT-gateways)
