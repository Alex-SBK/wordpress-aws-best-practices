terraform {
  required_version = ">=0.13"
}
provider "aws" {
  region = "eu-central-1"
}

resource "aws_launch_configuration" "alex_wordpress_launch_config" {
  # image with Ubuntu Server 18.04 LTS (HVM), SSD
  image_id = "ami-0e1ce3e0deb8896d2"

  instance_type = "t2.micro"
  security_groups = [aws_security_group.alex_wordpress_terraform_wordpress_sec_group.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = true
  }
}


# Looking up the data for our Default VPC
# And getting the data about Default VPC
data "aws_vpc" "default" {
  default = true
}

# Now getting data out of datasource with data about Default VPC
# So we know default vpc id:
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}
# And now we can tell our ASG to use subnets with exactly these ids below:

resource "aws_autoscaling_group" "alex-sbk-wordpress-autoscaling-group" {
  max_size = 2
  min_size = 2

  launch_configuration = aws_launch_configuration.alex_wordpress_launch_config.name
  health_check_type = "ELB"

  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  target_group_arns = [aws_lb_target_group.alex_wordpress_target_group_for_our_auto_scale.arn]


  tag {
    key = "Name"
    propagate_at_launch = true
    value = "terraform-asg-example"
  }
}

# Now create an AWS Application load balancer

resource "aws_lb" "alex-sbk-load-balancer-for-wordpress" {
  name = "wordpress-cluster-load-balancer"
  load_balancer_type = "application"

  # Again take this from previous data source
  # aws_subnet_ids
  # by this setting we use ALL the subnets in our Default VPC
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alex_wordpress_terraform_wordpress_sec_group.id]
}

# Next: define a Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alex-sbk-load-balancer-for-wordpress.arn
  port = 80
  protocol = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_security_group" "alex_wordpress_terraform_wordpress_sec_group" {
  name = var.wordpress_instance_security_group_name

  # Allow incoming HTTP requests
  ingress {
    from_port = var.server_port
    protocol = "tcp"
    to_port = var.server_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port = 0
    protocol = -1
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

}


# Now create target group for our ASG
resource "aws_lb_target_group" "alex_wordpress_target_group_for_our_auto_scale" {
  name = "alex-target-group"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "alex-wordpress-auto-scaling-group" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alex_wordpress_target_group_for_our_auto_scale.arn
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

