provider "aws" {
    region = "us-east-1"
  
}
resource "aws_cloudformation_stack" "s3-buc" {
    name = "s3-bucket"
    template_body = file("s3-cft.yaml")
    parameters = {
        BucketName= var.bucket_name
    }
  
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "s3-cft-dem"
}