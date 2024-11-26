# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Generate a random string for unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "simple_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach policies to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.lambda_role.name
}

# Create a Lambda function
resource "aws_lambda_function" "hello_world" {
  filename         = "lambda_function.zip"
  function_name    = "hello_world_function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

# Create S3 bucket with a unique name
resource "aws_s3_bucket" "example_bucket" {
  bucket = "my-example-bucket-${random_id.bucket_suffix.hex}"
}

# Allow S3 to invoke Lambda
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.example_bucket.arn
}

# Add a delay to ensure Lambda permissions are propagated
resource "time_sleep" "wait_30_seconds" {
  depends_on = [aws_lambda_permission.allow_bucket]
  create_duration = "30s"
}

# Add S3 event notification to trigger Lambda
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.example_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.hello_world.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket, time_sleep.wait_30_seconds]
}

# Output the Lambda function ARN and S3 bucket name
output "lambda_function_arn" {
  value = aws_lambda_function.hello_world.arn
}

output "s3_bucket_name" {
  value = aws_s3_bucket.example_bucket.id
}