output "nat_gateway_id" {
    value = aws_nat_gateway.nat.id
  
}
output "aws_instance_ip" {
    value = aws_instance.pub_ec2.public_ip
  
}