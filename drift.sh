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

/*
terraform init
terraform plan -detailed-exitcode -out=plan.out
if [ $? -eq 2 ]; then
   echo "Drift detected!"
   # Send notification (SNS, Slack, etc.)
fi

if [ $? -eq 2 ]; then
   aws sns publish --topic-arn arn:aws:sns:us-east-1:123456789012:TerraformDrift \
                   --subject "Terraform Drift Detected" \
                   --message "Drift detected for AWS resources managed via Terraform. Please review."
fi


*/

/*
GitHub actions workflow
name: Terraform Drift Detection
on:
  schedule:
    - cron: "*/10 * * * *"  # every 10 minutes
jobs:
  drift-detection:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - run: terraform init
      - run: |
          terraform plan -detailed-exitcode -out=plan.out
          if [ $? -eq 2 ]; then
            echo "Drift detected!"
            # Call SNS or Slack webhook
          fi
*/

*/
Use AWS Config to monitor resources managed by Terraform.

AWS Config rules detect changes in EC2, S3, RDS, etc.

When a drift/change occurs, Config can trigger an SNS notification.

This works in real time, without running Terraform continuously.

*/
