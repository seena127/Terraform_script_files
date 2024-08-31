provider "aws" {
    region = var.region
}

resource "aws_vpc" "my_vpc" {
    cidr_block = var.cidr_blocks
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
    map_public_ip_on_launch = var.map_public
    availability_zone = var.availability_zone[0]
    cidr_block = var.sub_cidr_blocks[0]
}
resource "aws_subnet" "priv_sub" {
    map_public_ip_on_launch = "false"
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = var.sub_cidr_blocks[1]
    availability_zone = var.availability_zone[1]
  
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
  

}
resource "aws_security_group" "admin" {
    vpc_id = aws_vpc.my_vpc.id
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}
resource "aws_instance" "pub_ec2" {
    ami=data.aws_ami.linux.id
    instance_type = "t2.micro"
    security_groups = [aws_security_group.admin.id]
    subnet_id = aws_subnet.pub_sub.id
    tags = {
      "env"= var.environment[0]
    }
     user_data = templatefile(
      "C:/Users/prasad/Desktop/kubernetes/terraform_script/Terraform/module/ec2_instance/user_data.sh", 
      {}
    )
   }
resource "aws_instance" "priv_ec2" {
    ami=data.aws_ami.linux.id
    instance_type = var.instance_type
    security_groups = [aws_security_group.priv_nsg.id]
    subnet_id = aws_subnet.priv_sub.id
    tags = {
      "env"= var.environment[1]
    }
    user_data = templatefile(
      "C:/Users/prasad/Desktop/kubernetes/terraform_script/Terraform/module/ec2_instance/user_data.sh", 
      {}
    )
    }