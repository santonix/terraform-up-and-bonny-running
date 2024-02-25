provider "aws" {
  region = "us-east-2"
}
/*Running a single server is a good start, but in the real world, a single server is a single
point of failure. If that server crashes, or if it becomes overloaded from too much
traffic, users will be unable to access your site. The solution is to run a cluster of
servers, routing around servers that go down, and adjusting the size of the cluster up
or down based on traffic.
Managing such a cluster manually is a lot of work. Fortunately, you can let AWS take
care of it for by you using an Auto Scaling Group (ASG). 
ASG takes care of a lot of tasks for you completely automatically, including launching
a cluster of EC2 Instances, monitoring the health of each Instance, replacing failed
Instances, and adjusting the size of the cluster in response to load.
The first step in creating an ASG is to create a launch configuration, which specifies
how to configure each EC2 Instance in the ASG...*/

resource "aws_launch_configuration" "example" {
  image_id                    = "ami-0c55b159cbfafe1f0"
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.instance.id]
  associate_public_ip_address = true
  key_name                    = "myfirst-instance"



  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  lifecycle {
    create_before_destroy = true
  }


}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = [data.aws_subnet.default.id]

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 5
  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}






resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  vpc_id     = data.aws_vpc.default.id
  cidr_block = "172.31.0.0/20"
}

resource "aws_lb" "example" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = ["subnet-007dce3b6f6e2c3c5", "subnet-09f80990e75d9dad2"]
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"
  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }

}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}



resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
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

output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}
