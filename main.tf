provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

# SNS Topic
resource "aws_sns_topic" "budget_alert" {
  name = "budget-alert-topic"
}

# SNS Topic Subscription (for email notifications)
resource "aws_sns_topic_subscription" "budget_alert_email" {
  topic_arn = aws_sns_topic.budget_alert.arn
  protocol  = "email"
  endpoint  = "amadasur7@gmail.com"  # Replace with your actual email address
}

# Budget Configuration
resource "aws_budgets_budget" "budget_alert" {
  name              = "cost-budget-alert"
  budget_type       = "COST"
  limit_amount      = "0.01"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alert.arn]
  }
}

# IAM Policy for Lambda to stop EC2 and RDS
resource "aws_iam_policy" "lambda_policy" {
  name        = "LambdaStopResourcesPolicy"
  description = "Policy to stop EC2 and RDS instances"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ec2:DescribeInstances",
          "ec2:StopInstances",
          "rds:DescribeDBInstances",
          "rds:StopDBInstance"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name               = "LambdaStopResourcesRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      }
    ]
  })
}

# Attach IAM policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda Function to stop resources
resource "aws_lambda_function" "stop_resources" {
  filename         = "lambda_function.zip"  # Make sure this file exists
  function_name    = "StopResourcesLambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

# Grant SNS permission to invoke the Lambda function
resource "aws_lambda_permission" "allow_sns_invocation" {
  statement_id  = "AllowSNSToInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_resources.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.budget_alert.arn
}

# Subscribe Lambda to SNS topic
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.budget_alert.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.stop_resources.arn
}