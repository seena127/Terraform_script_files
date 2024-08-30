provider "aws" {
    region = "us-east-1"
}
data "aws_ami" "linux"{
    most_recent = true
filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames="true"
  
}
resource "aws_eip" "nat_ip" {
    domain = "vpc"
  
}
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.my_vpc.id
  
}
resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat_ip.id
    subnet_id = aws_subnet.priv_sub.id
  
}
resource "aws_subnet" "pub_sub"{
    vpc_id = aws_vpc.my_vpc.id
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1a"
    cidr_block = "10.0.1.0/24"
}
resource "aws_subnet" "priv_sub" {
    map_public_ip_on_launch = "false"
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"
  
}
resource "aws_route_table" "rtb1" {
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

  
}
resource "aws_route_table" "rtb2" {
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }
  
}
resource "aws_route_table_association" "rtba" {
    subnet_id = aws_subnet.pub_sub.id
    route_table_id = aws_route_table.rtb1.id
  
}
resource "aws_route_table_association" "rtba1" {
    subnet_id = aws_subnet.priv_sub.id
    route_table_id = aws_route_table.rtb2.id
  
}
resource "aws_security_group" "priv_nsg" {
    vpc_id = aws_vpc.my_vpc.id
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = ["${aws_security_group.admin.id}"]
    }
  

}
resource "aws_security_group" "admin" {
    vpc_id = aws_vpc.my_vpc.id
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}
resource "aws_instance" "pub_ec2" {
    ami=data.aws_ami.linux.id
    instance_type = "t2.micro"
    security_groups = [aws_security_group.admin.id]
    subnet_id = aws_subnet.pub_sub.id
    user_data = <<-EOF
    #!/bin/bash
    sudo yum -y upgrade
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker  # Ensure Docker starts on boot
    EOF
   }
resource "aws_instance" "priv_ec2" {
    ami=data.aws_ami.linux.id
    instance_type = "t2.micro"
    security_groups = [aws_security_group.priv_nsg.id]
    subnet_id = aws_subnet.priv_sub.id
    user_data = <<-EOF
    #!/bin/bash
    sudo yum -y upgrade
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker  # Ensure Docker starts on boot
    EOF
    }