data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../src/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}"
  retention_in_days = 14
}

resource "aws_lambda_function" "rates" {
  function_name = var.project_name
  role          = aws_iam_role.lambda.arn

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  handler = "lambda_function.lambda_handler"
  runtime = "python3.13"

  memory_size = 128
  timeout     = 30

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.rates.id
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.lambda_s3,
    aws_iam_role_policy_attachment.lambda_logs,
  ]
}