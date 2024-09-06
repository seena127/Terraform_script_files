provider "aws"  {
    region="us-east-1"
  
}
data "aws_canonical_user_id" "curr"{}
resource "aws_s3_bucket" "analytics" {
    bucket = "source-${local.common_tags.env}"
    force_destroy = true
    object_lock_enabled = false
  
}
resource "aws_s3_bucket" "s3-practice" {
    bucket = "logging-${local.common_tags.env}"
    force_destroy = true
    object_lock_enabled = false

  
}
resource "aws_s3_bucket" "destination" {
  bucket = "destination-buck-rep"
  force_destroy = true
  
}

resource "aws_s3_bucket_logging" "log" {
  target_bucket = aws_s3_bucket.s3-practice.id
  bucket = aws_s3_bucket.analytics.id
  target_prefix="log/"  
}

#iam role for replicaton of analytics to destination and attachment to the policy
resource "aws_iam_policy" "dest_repl" {
  name = "dest-s3-rep-policy"
  description = "destination-s3-replica"
  policy = jsonencode({
    "Version":"2012-10-17",
    "Statement"=[
      {
        "Action":[
          "s3:ListBucket",
          "s3:GetReplicationConfiguration"
        ],
        "Effect":"Allow",
        "Resource":"${aws_s3_bucket.analytics.arn}"
      },
      {
       
        "Action":[
          "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
        ],
        "Effect":"Allow",
        "Resource":"${aws_s3_bucket.analytics.arn}"

      },
      
      {
        "Action":[
          "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
        ],
        "Effect":"Allow",
        "Resource":"${aws_s3_bucket.destination.arn}"

      }
    ]
      

  })
  
}
resource "aws_iam_role" "s3_rep"{
  name="s3-replication"
  
  description="s3-replication-rule"
  assume_role_policy=jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service= "s3.amazonaws.com"
        }
        }
      
    ]


  })
}

resource "aws_iam_role_policy_attachment" "s3-replication"{
  role= aws_iam_role.s3_rep.name
  policy_arn = aws_iam_policy.dest_repl.arn
}

resource "aws_s3_bucket_replication_configuration" "s3_rep" {
  depends_on = [ aws_s3_bucket_versioning.ver ]
  role = aws_iam_role.s3_rep.arn
  bucket = aws_s3_bucket.analytics.id
  rule {
    id="none"
    filter {
      
    }
    status = "Enabled"
    destination {
      bucket = aws_s3_bucket.destination.arn
      storage_class = "STANDARD"
    }
    delete_marker_replication {
      status = "Disabled"
    }
  }

  
}
#adding object to analystics s3 bucket
resource "aws_s3_object" "inde" {
  bucket = aws_s3_bucket.analytics.id
  for_each = local.files
  key = each.key
  source = each.value
}

#life cycle configuration for analytics bucket
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_infre" {
  bucket = aws_s3_bucket.analytics.id
  rule {
    id = "transition-to-ia"
    status = "Enabled"
    filter {
      prefix = ""

    }
    transition {
      days = 45
      storage_class = "STANDARD_IA"
    }
    transition {
      days = 75
      storage_class = "GLACIER"
    }
  }

  
}
#version enabling for replication on both buckets
resource "aws_s3_bucket_versioning" "ver" {
  bucket = aws_s3_bucket.analytics.id
  versioning_configuration {
    status = "Enabled"
  }
  
}
resource "aws_s3_bucket_versioning" "ver2" {
  bucket = aws_s3_bucket.destination.id
  versioning_configuration {
    status = "Enabled"
  }
  
}
#bucket policy for analytics bucket for static website hosting
resource "aws_s3_bucket_policy" "s3_pol" {
  bucket = aws_s3_bucket.analytics.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = ["s3:GetObject"],
        Effect    = "Allow",
        Resource  = "${aws_s3_bucket.analytics.arn}/*",
        Principal = "*"
      }
    ]
  })
}


resource "aws_s3_bucket_ownership_controls" "own_control" {
    bucket = aws_s3_bucket.analytics.id
    rule {
      object_ownership = "BucketOwnerPreferred"
    }
  
}

resource "aws_s3_bucket_acl" "bu_acl" {
    bucket = aws_s3_bucket.analytics.id
    depends_on = [ aws_s3_bucket_ownership_controls.own_control ]
    acl = "public-read"

  
}



resource "aws_s3_bucket_website_configuration" "web" {
  bucket = aws_s3_bucket.analytics.id
  index_document {
    suffix = "index.html"
    
  }
  error_document {
    key="second.html"
  }


  
}
#iam policy for sns to send messages
resource "aws_sns_topic" "s3-event-sns" {
  name = "s3-event-notification-sns"
  
}
resource "aws_sns_topic_policy" "sns-policy" {
  arn = aws_sns_topic.s3-event-sns.arn
  policy = jsonencode({

    "Version"="2012-10-17",
    "Statement"=[
      {
      "Action"= [
        "SNS:Publish"
      ],
      "Effect"="Allow",
      "Resource"= "${aws_sns_topic.s3-event-sns.arn}",
      "Principal"={
        "Service"="s3.amazonaws.com"
      }
      }

    ]
    
  })
  
}
resource "aws_s3_bucket_notification" "event-notify-sns" {
  bucket = aws_s3_bucket.analytics.id
  topic {
    topic_arn = aws_sns_topic.s3-event-sns.arn
    events = [
      "s3:ObjectCreated:*"
      ]
  }

  
}


locals {
  files = {
    first  = "index.html"
    second = "second.html"
  }
}





locals {
  common_tags ={
    env="demo-terr-s3"
  }
}