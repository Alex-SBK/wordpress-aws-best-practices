# ==============================
# Security group for SSH access
# ==============================
resource "aws_security_group" "allow_ssh_access" {
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

# ===============================
# Security group for WEB access:
# ===============================

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
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ========================
# Security group for EFS
# ========================

resource "aws_security_group" "efs_security_group" {
  name = "EFS_security_group"
  description = "EFS_security_group"
  vpc_id = aws_vpc.vpc_for_wordpress.id
  tags = {
    Name = "EFS_security_group"
  }
  # Allow incoming SSH packets from anywhere
  ingress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    description = "Allow all"
  }
  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [aws_vpc.vpc_for_wordpress.cidr_block]
    description = "PING from inside"
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
