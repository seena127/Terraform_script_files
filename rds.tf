provider "aws"{
    region="us-east-1"
}
variable "rds_pass"{
    type = string
    default = "Admin12345"
}
resource "random_id" "rds_snapshot" {
  byte_length = 4
}
module "vpc" {
  source   = "C:/Users/prasad/Desktop/kubernetes/terraform_script/demo-terr/vpc"
  vpc_cidr = "10.0.0.0/16"
  sub_cidr = ["10.0.1.0/24", "10.0.2.0/24"]
  az = ["us-east-1a", "us-east-1b"]
}
resource "aws_security_group" "rds_sg"{
    name = "rds-sg"
    description = "allow access for rds sg"
    vpc_id = module.vpc.vpc_id
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
}
egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]

}
}
resource "aws_secretsmanager_secret" "rdssecret"{
    name = "rds-demo-var-13607"
}
resource "aws_secretsmanager_secret_version" "rdssecret01"{
   secret_id     = aws_secretsmanager_secret.rdssecret.id
    secret_string = var.rds_pass

}

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = module.vpc.public_subnet_ids
}
resource "aws_db_instance" "db0" {
    
    
    engine = "mysql"
    engine_version = "8.0"
    
    instance_class = "db.t3.small"
    username = "master"
    password = aws_secretsmanager_secret_version.rdssecret01.secret_string
    db_name = "rdsdemo0013"
    parameter_group_name = "default.mysql8.0"
    skip_final_snapshot = false
    final_snapshot_identifier = "rds-final-snapshot-0031"
 #Name of final DB snapshot must be provided if set is false for backup to snapshot after deleted, if set as true no snapshot of the database is taken
    storage_type = "gp2"
    allocated_storage = 20
    db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.name
    vpc_security_group_ids = [ aws_security_group.rds_sg.id ]
    publicly_accessible = true
    multi_az = true
    backup_retention_period = 7

  
}
# 5 Read Replicas
resource "aws_db_instance" "db_read_replica" {
   
  count                    = 2
  engine                   = "mysql"
  instance_class           = "db.t3.micro"
  publicly_accessible      = true
  vpc_security_group_ids   = [aws_security_group.rds_sg.id]
  replicate_source_db      = aws_db_instance.db0.identifier
  availability_zone      = element(module.vpc.availability_zones, count.index % length(module.vpc.availability_zones))
  skip_final_snapshot      = true

  depends_on = [ aws_db_instance.db0 ]
}
resource "aws_iam_role" "rds_proxy_role" {
  name = "rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "rds_proxy_policy" {
  name = "rds-proxy-policy"
  role = aws_iam_role.rds_proxy_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.rdssecret.arn
      }
    ]
  })
}

resource "aws_db_proxy" "rds_proxy"{
    name = "rdsdemoproxy1"
    engine_family  = "MYSQL"
    role_arn  = aws_iam_role.rds_proxy_role.arn
    vpc_subnet_ids = module.vpc.public_subnet_ids
    vpc_security_group_ids = [ aws_security_group.rds_sg.id ]
    auth {
      auth_scheme = "SECRETS"
      secret_arn = aws_secretsmanager_secret.rdssecret.arn
      iam_auth = "DISABLED"
    }
    
    depends_on = [ aws_iam_role_policy.rds_proxy_policy ]



}
#output values 
output "dbs_endpoint" {
    value = aws_db_instance.db0.endpoint
  
}
output "dbs_username" {
    value = aws_db_instance.db0.username
  
}
output "dbs_name" {
    value = aws_db_instance.db0.db_name
  
}
output "dbs_port" {
    value = aws_db_instance.db0.port
}
output "read_replica_endpoints" {
  value = [for replica in aws_db_instance.db_read_replica : replica.endpoint]
}
output "rds_proxy_endpoint" {
  value = aws_db_proxy.rds_proxy.endpoint
}
