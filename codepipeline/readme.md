create code build in aws
![image](https://github.com/user-attachments/assets/a6f01ce4-26e3-48f9-9bf9-0347172793fe)
![image](https://github.com/user-attachments/assets/7850eb3b-d5be-42bd-bc65-5764825afb1e)
![image](https://github.com/user-attachments/assets/e8097e81-0ec0-4b82-bb64-574a4ba30dfa)
Environment in codebuild:
![image](https://github.com/user-attachments/assets/4074a087-5746-4404-89e9-e1aa4412ebb1)
![image](https://github.com/user-attachments/assets/fec3efb7-5c1e-4839-b57d-bbad577b1f2a)
permissions for codebuild role: 
AmazonSSMFullAccess
AWSResourceAccessManagerReadOnlyAccess
use the Buildspec.yaml file that has been used in the repository

create codedeploy application
![image](https://github.com/user-attachments/assets/367eeade-3e13-4292-b130-44eca16304ee)
compute platform: aws lambda, ECS, ec2/onpremises
![image](https://github.com/user-attachments/assets/2e9a6765-123e-4388-8d51-2634584a25c3)
code deploy role policies: AmazonEC2FullAccess, AmazonS3FullAccess, AWSCodeDeployRole 
create an ec2 instance or the compute platform with tags that can be used for codedeploy
![image](https://github.com/user-attachments/assets/850ce855-5178-45a1-b2ba-7fe40d324aa7)
ssh into the instance and follow with commands in this link
https://docs.aws.amazon.com/codedeploy/latest/userguide/codedeploy-agent-operations-install-ubuntu.html
commands need to be executed:
sudo su -
apt update
apt install docker.io
sudo apt install ruby-full
sudo apt install wget
cd /home/ubuntu
wget https://bucket-name.s3.region-identifier.amazonaws.com/latest/install
we can find bucket name and region identifier in this document https://docs.aws.amazon.com/codedeploy/latest/userguide/resource-kit.html#resource-kit-bucket-names
chmod +x ./install
sudo ./install auto
systemctl start codedeploy-agent
systemctl status codedeploy-agent
![image](https://github.com/user-attachments/assets/55dad2ae-5d3b-4022-b648-901d39eabf7d)
![image](https://github.com/user-attachments/assets/b24536a0-370a-427e-92cb-903b0c01867c)
![image](https://github.com/user-attachments/assets/81ed17e1-15a0-4137-bf06-91d892fae142)

Create deployment in codedeploy
![image](https://github.com/user-attachments/assets/d6ef6531-4b6e-4489-97c2-e288c04c7378)

launch the deployment
IAM role for instance must have the following permissions:
AmazonEC2FullAccess
AmazonEC2RoleforAWSCodeDeploy
AmazonS3FullAccess
AWSCodeDeployFullAccess
AWSCodeDeployRole

create codepipeline:
appspec.yml should always be at the root of the repository
![image](https://github.com/user-attachments/assets/6530f295-9c54-4d02-923d-8f36341ccefd)
source provider: ![image](https://github.com/user-attachments/assets/d98c9368-53f6-48b8-97eb-c498f9d0d403)
![image](https://github.com/user-attachments/assets/53ecd7c0-830c-4b12-90fe-17d14e6e6ad8)
![image](https://github.com/user-attachments/assets/eb3b483a-ff89-4bee-87b7-602298f1693f)
Build stage: for build codebuild or jenkins can be used
![image](https://github.com/user-attachments/assets/82246ab1-b471-49b6-a552-0cc2d9c10934)
Input artifact: source artifact
Deploy stage: ![image](https://github.com/user-attachments/assets/b8f647cf-312e-461a-85b1-f160bf1f952b)

In aws s3 bucket change bucket policy to allow codepipeline. Bucket policy is as follows:

{
    "Version": "2012-10-17",
    "Id": "SSEAndSSLPolicy",
    "Statement": [
        {
            "Sid": "DenyUnEncryptedObjectUploads",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::codepipeline-us-east-1-664179818416/*",
            "Condition": {
                "StringNotEquals": {
                    "s3:x-amz-server-side-encryption": "aws:kms"
                }
            }
        },
        {
            "Sid": "DenyInsecureConnections",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::codepipeline-us-east-1-664179818416/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        },
        {
            "Sid": "AllowCodePipelineAndCodeDeploy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::codepipeline-us-east-1-664179818416/*",
                "arn:aws:s3:::codepipeline-us-east-1-664179818416"
            ]
        },
        {
            "Sid": "AllowCodeDeploy",
            "Effect": "Allow",
            "Principal": {
                "Service": "codedeploy.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::codepipeline-us-east-1-664179818416/*"
        },
        {
            "Sid": "DenyUnEncryptedObjectUploads2",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::codepipeline-us-east-1-664179818416/*",
            "Condition": {
                "StringNotEquals": {
                    "s3:x-amz-server-side-encryption": "aws:kms"
                }
            }
        },
        {
            "Sid": "DenyInsecureConnections2",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::codepipeline-us-east-1-664179818416/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
