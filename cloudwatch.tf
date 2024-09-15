provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/18"
    enable_dns_hostnames="true"
  
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.my_vpc.id
  
}
resource "aws_subnet" "pub_sub"{
    vpc_id = aws_vpc.my_vpc.id
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"
    cidr_block = "10.0.1.0/24"
}
resource "aws_route_table" "rtb1" {
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

  
}
resource "aws_route_table_association" "rtba" {
    subnet_id = aws_subnet.pub_sub.id
    route_table_id = aws_route_table.rtb1.id
  
}
resource "aws_security_group" "pub_nsg" {
    vpc_id = aws_vpc.my_vpc.id
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress{
        from_port =22
        to_port =22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }
  

}
resource "aws_instance" "pub_ec2" {

    instance_type = "t2.micro"
    ami = "ami-0182f373e66f89c85"
    security_groups = [aws_security_group.pub_nsg.id]
    subnet_id = aws_subnet.pub_sub.id
    key_name = "devops"
    tags = {
      "env"= "cloudwatch"
    }
       user_data = <<EOF
#!/bin/bash
# Update the package lists
yum update -y

# Install Python 3
yum install python3 -y

# Install Git
yum install git -y

# Clone the repository
git clone https://github.com/seena127/Terraform_script_files.git

# Navigate to the cloned directory
cd Terraform_script_files

# Run your script (ensure your script is correctly named and exists)
python3 cpu_spike.py
EOF


    
   }
resource "aws_sns_topic" "email" {
    name = "cloudwatch_to_email_notification"
    
}
resource "aws_sns_topic_subscription" "email"{
    topic_arn = aws_sns_topic.email.arn
    protocol = "email"
    endpoint = "bsreenivasasarma1999@gmail.com"
  
}
resource "aws_cloudwatch_metric_alarm" "demo-py1" {
    alarm_name = "demo-py1-app"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods=1
    metric_name="CPUUtilization"
    period=30
    statistic="Maximum"
    threshold=30
    dimensions={
        InstanceId= aws_instance.pub_ec2.id
    }
    namespace = "AWS/EC2"

}
