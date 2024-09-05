provider "aws" {
    region="us-east-1"
  
}
resource "aws_vpc" "asg_vpc" {
    
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = "true"
}
data "aws_caller_identity" "current" {}

resource "aws_subnet" "pub1" {
    vpc_id = aws_vpc.asg_vpc.id
    map_public_ip_on_launch = "true"
    cidr_block = "10.0.1.0/24"    
    availability_zone = "us-east-1a"
  
}
resource "aws_subnet" "pub2" {
    vpc_id = aws_vpc.asg_vpc.id
    map_public_ip_on_launch = "true"
    cidr_block = "10.0.2.0/24"   
    availability_zone= "us-east-1b" 
  
}
resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.asg_vpc.id
}
resource "aws_route_table" "rtb" {
    vpc_id = aws_vpc.asg_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw1.id
    }
  
}
resource "aws_route_table_association" "rtbas1" {
    route_table_id = aws_route_table.rtb.id
    subnet_id = aws_subnet.pub2.id
  
}

resource "aws_route_table_association" "rtbas" {
    route_table_id = aws_route_table.rtb.id
    subnet_id = aws_subnet.pub1.id
  
}
resource "aws_security_group" "asg_ec2" {
    vpc_id = aws_vpc.asg_vpc.id
    name="asg_vpc_ec2"
    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}
data "aws_elb_service_account" "root"{}
resource "aws_security_group" "lb_sg" {
    vpc_id = aws_vpc.asg_vpc.id
    
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
        from_port = 0
        to_port = 0
        
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

  
}
resource "aws_launch_template" "linux" {
    name="my-terraform-based-template"
    image_id ="ami-066784287e358dad1"
    instance_type = "t2.micro"
    vpc_security_group_ids  = [aws_security_group.asg_ec2.id]
    key_name = "devops"
    user_data = filebase64("C:/Users/prasad/Desktop/kubernetes/terraform_script/Terraform/user_data.sh")
     

  
}
resource "aws_lb_target_group" "alb_target" {
    name="aws-lb-target"
    vpc_id = aws_vpc.asg_vpc.id
    port=80
    protocol ="HTTP"
    health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
  
  
}
resource "aws_s3_bucket" "alb_logs" {
  bucket = "my-alb-logs-1234567"
  acl    = "private"
  force_destroy = true

  tags = {
    Name = "My ALB Logs Bucket"
  }
}

# Create the IAM Role for ALB logging
resource "aws_iam_role" "alb_logging_role" {
  name = "alb_logging_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service= "elasticloadbalancing.amazonaws.com"
        }
        }
      
    ]
  })
}

# Create an IAM Policy that allows ALB to write logs to the S3 bucket
resource "aws_iam_policy" "alb_logging_policy" {
  name        = "alb_logging_policy"
  description = "Allow ALB to write logs to S3"
  
  policy = jsonencode({
    "Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "Statement1",
			"Effect": "Allow",
			"Action": [
			    "s3:PutObject",
          "s3:PutObjectAcl",


			],
			"Resource":"${aws_s3_bucket.alb_logs.arn}/*"
          
        
		}
	]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "alb_logging_attachment" {
  policy_arn = aws_iam_policy.alb_logging_policy.arn
  role       = aws_iam_role.alb_logging_role.name
}

# Create the S3 Bucket Policy that allows ALB to put logs into the bucket
resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = data.aws_iam_policy_document.lb_logs.json
}
data "aws_iam_policy_document" "lb_logs" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.root.arn]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.alb_logs.arn}/*"]
  }
}


resource "aws_lb" "asg_lb" {
    name = "aws-lb"
    internal = "false"
    load_balancer_type = "application"
    subnets = [aws_subnet.pub1.id,aws_subnet.pub2.id]
    security_groups = [aws_security_group.lb_sg.id]
    access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    enabled = true
    prefix  = "logs"
  }
    


  
}
resource "aws_lb_listener" "aws_lb_listener" {
    load_balancer_arn = aws_lb.asg_lb.arn
    port = 80
    protocol = "HTTP"
    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.alb_target.arn
    }
    }
resource "aws_autoscaling_group" "asg1" {
    name="asg_demo"
    launch_template{
        id = aws_launch_template.linux.id
    }
    min_size=2
    max_size = 5
    desired_capacity = 2
    vpc_zone_identifier = [aws_subnet.pub1.id,aws_subnet.pub2.id]
    target_group_arns = [aws_lb_target_group.alb_target.arn]
    health_check_type         = "ELB"
  health_check_grace_period = 300

  lifecycle {
    create_before_destroy = true
  }
  
}
resource "aws_autoscaling_policy" "scale_up" {
    name                   = "scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg1.name
  
}
resource "aws_autoscaling_policy" "scale_down" {
    name                   = "scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg1.name
  
}
output "aws_lb_arn" {
    value=aws_lb.asg_lb.arn
  
}
output "alb_dns_name" {
  value = aws_lb.asg_lb.dns_name
}
