data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "${var.project_name}-scheduler-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role.json
}

data "aws_iam_policy_document" "scheduler_invoke_lambda" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      aws_lambda_function.rates.arn,
    ]
  }
}

resource "aws_iam_role_policy" "scheduler_invoke_lambda" {
  name   = "${var.project_name}-invoke-lambda"
  role   = aws_iam_role.scheduler.id
  policy = data.aws_iam_policy_document.scheduler_invoke_lambda.json
}

resource "aws_scheduler_schedule" "daily" {
  name        = "${var.project_name}-daily"
  description = "Descarga diariamente tipos de cambio del BCE"
  state       = "ENABLED"

  schedule_expression          = "cron(0 18 * * ? *)"
  schedule_expression_timezone = "Europe/Madrid"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.rates.arn
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      source = "eventbridge-scheduler"
    })

    retry_policy {
      maximum_event_age_in_seconds = 3600
      maximum_retry_attempts       = 2
    }
  }

  depends_on = [
    aws_iam_role_policy.scheduler_invoke_lambda,
  ]
}