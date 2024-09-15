provider "aws" {
    region = "us-east-1"
  
}
resource "aws_iam_role" "codebuild" {
    name = "codebuild-terraform"
    description = "codebuild-terraform"
    assume_role_policy = jsonencode({
        "Version":"2012-10-17",
        Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service= "codebuild.amazonaws.com"
        }
        }
      
    ]
    })
  
}

resource "aws_iam_role_policy_attachment" "attach" {
    
    role = aws_iam_role.codebuild.name
   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}
resource "aws_ssm_parameter" "git_token" {
    name = "GIT_TOKEN"
    description = "github oauth token"
    type = "SecureString"
    value = "#git webhook token"
  
}
resource "aws_codebuild_project" "first" {
    name = "simple-terraform-pyapp"
    description = "simple terraform based codebuild project"
    service_role = aws_iam_role.codebuild.arn
    artifacts {
      type = "NO_ARTIFACTS"
    }
    environment {
      compute_type = "BUILD_GENERAL1_SMALL"
      image = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
      type = "LINUX_CONTAINER"
      privileged_mode = false
      environment_variable {
      name  = "OAUTH_TOKEN"
      value = aws_ssm_parameter.git_token.value
      type  = "PARAMETER_STORE"
    }

    }
    
   
         
    source {
      type = "GITHUB"
      location = "https://github.com/seena127/Terraform_script_files.git"
      buildspec = "codepipeline/buildpec.yaml"
      
    }
    source_version = "main"
     logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
    
   
}
}

resource "aws_codebuild_webhook" "webhook1" {
    project_name=aws_codebuild_project.first.name

    
    filter_group{
        filter{
            type="EVENT"
            pattern="PUSH"
        }
    }
  
}
provider "github" {
    token=aws_ssm_parameter.git_token.value
  
}
resource "github_repository_webhook" "web" {
    repository= "https://github.com/seena127/Terraform_script_files.git"
    
    configuration{
        url=aws_codebuild_webhook.webhook1.payload_url
        content_type="json"
        insecure_ssl=false
        secret="new value"

    }
    events=["push"]
    active=true
}
resource "aws_codebuild_source_credential" "gittoken" {
    auth_type="PERSONAL_ACCESS_TOKEN"
    server_type="GITHUB"
    token=aws_ssm_parameter.git_token.value
    
  
}