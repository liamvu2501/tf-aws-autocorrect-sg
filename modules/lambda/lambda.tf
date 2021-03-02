#############################
#### Create Lambda role #####
#############################

#Create a role and assign to Lambda
resource "aws_iam_role" "autocorrect-sg-lambda-role" {
  name = var.lambda_role_name

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

#Create a policy with appropriate permision
resource "aws_iam_policy" "autocorrect-sg-lambda-policy" {
  name        = var.lambda_policy_name
  description = "Policy for Lambda role created with Terraform"

  policy = <<EOF
{
"Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
     {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupEgress"
      ],
      "Resource": "*"
    },
            {
            "Action": [
                "sns:*"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:sns:${var.region}:${var.account_id}:${var.topic_name}"
        }
    ]
}
EOF
}

#Attach the policy to the role
resource "aws_iam_role_policy_attachment" "autocorrect-sg-lambda-role-attachment" {
  role       = aws_iam_role.autocorrect-sg-lambda-role.name
  policy_arn = aws_iam_policy.autocorrect-sg-lambda-policy.arn
}


#################################
#### Create Lambda function #####
#################################

#Upload zip file from local
resource "aws_lambda_function" "autocorrect-sg-lambda-function" {
  filename      = "${path.module}/lambda.zip"
  function_name = var.function_name
  role          = aws_iam_role.autocorrect-sg-lambda-role.arn
  handler       = "lambda.lambda_handler"

  #When updating the package, the hash will change and TF will update the function without the need to delete & re-create the function
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")

  runtime = "python3.6"

  timeout = 30

  #Environment variables will be passed to the editor.py. The values are from user's input
  environment {
    variables = {
      region        = var.region
      topic_arn     = var.topic_arn
      function_name = var.function_name
    }
  }
}

#####################################################################
#### Create permission to trigger Lambda function from CW Event #####
#####################################################################

resource "aws_lambda_permission" "allow-cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.autocorrect-sg-lambda-function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = var.cwrule_arn
}
