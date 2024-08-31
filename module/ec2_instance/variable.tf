variable "region" {
    type = string
    default = "us-east-1"
}
variable "cidr_blocks" {
    default = "10.0.0.0/16"
  
}
variable "availability_zone"{
    default = ["us-east-1a", "us-east-1b"]
    type = list(string)
}
variable "sub_cidr_blocks" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
  type = list
}
variable "map_public" {
    default = "true"
  
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

variable "enable_dns" {
    default = "true"
  
}

variable "instance_type" {
    default = "t2.micro"
    type=string
}
variable "environment" {
  description = "Environment type"
  type        = list(string)
  default     = ["public", "private"]
}


resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Example security group"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.environment == "private" ? ["${aws_security_group.admin.id}"] : ["0.0.0.0/0"]
  }
}
