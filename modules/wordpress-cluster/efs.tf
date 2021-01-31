# ======= CREATING EFS for wordpress VPC ==========

# Create EFS filesystem
resource "aws_efs_file_system" "wordpress_efs" {
  creation_token = "efs-wordpress"
  tags = {
    Name = "wordpress-EFS"
  }
}

# Now create EFS mount targets for both subnets:
# we'll create EFS mount targets in PRIVATE subnets, so:
# For A subnet private app:
resource "aws_efs_mount_target" "subnet_A_private_app" {
  file_system_id = aws_efs_file_system.wordpress_efs.id
  subnet_id = aws_subnet.subnet_A_private_app.id
  security_groups = [aws_security_group.efs_security_group.id]
}
# For B subnet private app:
resource "aws_efs_mount_target" "subnet_B_private_app" {
  file_system_id = aws_efs_file_system.wordpress_efs.id
  subnet_id = aws_subnet.subnet_B_private_app.id
  security_groups = [aws_security_group.efs_security_group.id]
}
