provider "aws" {
    region = "us-west-1"
  
}
module "ec2_instance" {
    source = "./module/ec2_instance"
    availability_zone = ["us-east-1a","us-east-1b"]
    instance_type = "t2.medium"
  
}
output "ec2_public_ip" {
    value= module.ec2_instance.aws_instance_ip
  
}