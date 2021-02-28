###################################
#### Create Cloudwatch Events #####
###################################

#https://stackoverflow.com/questions/35895315/use-terraform-to-set-up-a-lambda-function-triggered-by-a-scheduled-event-source
#https://aws.amazon.com/premiumsupport/knowledge-center/monitor-security-group-changes-ec2/

locals {
  cloudwatch_tags = {
    Project     = "Autocorrect-SGs"
    Environment = "Terraform"
  }
}

#Create CW Event rule to capture add/remove actions to EC2 SGs
resource "aws_cloudwatch_event_rule" "autocorrect-sg-rule" {
  name        = var.cwrule_name
  description = "Capture SGs event"

  event_pattern = <<EOF
{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "ec2.amazonaws.com"
    ],
    "eventName": [
      "AuthorizeSecurityGroupIngress",
      "AuthorizeSecurityGroupEgress",
      "RevokeSecurityGroupIngress",
      "RevokeSecurityGroupEgress"
    ]
  }
}
EOF

  tags = local.cloudwatch_tags

}

#Create CW Event Target to trigger Lambda function
resource "aws_cloudwatch_event_target" "autocorrect-sg-target" {
  target_id = "tflambda-taget"
  rule      = aws_cloudwatch_event_rule.autocorrect-sg-rule.name
  arn       = var.lambda_arn
}

