provider "aws" {
    region = "us-east-1"
  
}
resource "aws_sns_topic" "email1" {
    name = "lambda_to_email_notification"
    
}
resource "aws_sns_topic_subscription" "email1"{
    topic_arn = aws_sns_topic.email1.arn
    protocol = "email"
    endpoint = "bsreenivasasarma1999@gmail.com"
  
}
resource "aws_iam_policy" "lambda_permissions" {
    name   = "aws-lambda-permissions-for-snap-delete"
    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "logs:CreateLogGroup",
                "Resource": "arn:aws:logs:us-east-1:642661729275:*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ],
                "Resource": "${aws_lambda_function.snap_del.arn}"
            },
            {
                
                "Effect": "Allow",
                "Action": [
                    "ec2:DescribeInstances",
                    "ec2:DeleteSnapshot",
                    "ec2:DescribeVolumes",
                    "ec2:DescribeSnapshots",
                    "ec2:UnlockSnapshot",
                    "ec2:ModifySnapshotAttribute",
                    "ec2:ResetSnapshotAttribute"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "sns:Publish",
                    "SNS:RemovePermission",
        "SNS:SetTopicAttributes",
        "SNS:DeleteTopic",
        "SNS:ListSubscriptionsByTopic",
        "SNS:GetTopicAttributes",
        "SNS:AddPermission",
        "SNS:Subscribe"
                ],
                "Resource": "${aws_sns_topic.email1.arn}"

            }
        ]
    })
}
resource "aws_iam_role" "lambda" {
    name = "lambda_role_permissions"
    assume_role_policy = jsonencode({
         "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "sts:AssumeRole",
                "Principal":{
                    "Service":["lambda.amazonaws.com"]
                }
            }
        ]


    })
  
}
resource "aws_iam_role_policy_attachment" "lambda_attachment" {
    
    policy_arn = aws_iam_policy.lambda_permissions.arn
    role  =aws_iam_role.lambda.name 
  
}
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "ebs_del.py"
  output_path = "ebs_del.zip"
}


resource "aws_lambda_function" "snap_del"{
    function_name = "snapshot-delete"
    role= aws_iam_role.lambda.arn
    filename = "ebs_del.zip"
    source_code_hash = data.archive_file.lambda.output_base64sha256
    runtime = "python3.12"
    handler = "ebs_del.lambda_handler"

    timeout = 30
    environment {
      variables = {
        sns_topic_arn =aws_sns_topic.email1.arn
      }
      }

    }
resource "aws_lambda_invocation" "invoke_lambda" {
    function_name = aws_lambda_function.snap_del.function_name
     input = jsonencode({
    key1 = "value1"
    key2 = "value2"
  })
  
}
locals {
    lambda_response_body = jsondecode(aws_lambda_invocation.invoke_lambda.result).body
}
output "result_entry" {
    value = local.lambda_response_body
}
