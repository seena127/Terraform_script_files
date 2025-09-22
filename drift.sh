#!/bin/bash
cd /path/to/terraform/code

# Initialize backend (S3)
terraform init -input=false

# Run plan with detailed exit code
terraform plan -detailed-exitcode -out=tfplan.out > plan.log 2>&1
PLAN_EXIT=$?

if [ $PLAN_EXIT -eq 2 ]; then
  echo "Drift detected!"
  # Send notification (example using AWS SNS)
  aws sns publish \
    --topic-arn arn:aws:sns:us-east-1:123456789012:TerraformDriftTopic \
    --subject "Terraform Drift Detected" \
    --message "Drift detected in resources. Check plan.log for details."
elif [ $PLAN_EXIT -eq 0 ]; then
  echo "No drift detected."
else
  echo "Error running terraform plan."
  exit $PLAN_EXIT
fi
