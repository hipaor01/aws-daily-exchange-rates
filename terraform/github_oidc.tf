resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github.arn,
      ]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:hipaor01/aws-daily-exchange-rates:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

data "aws_iam_policy_document" "github_deploy" {
  statement {
    sid    = "TerraformStateBucket"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::ecb-daily-exchange-rates-tfstate-${data.aws_caller_identity.current.account_id}",
    ]
  }

  statement {
    sid    = "TerraformStateObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      "arn:aws:s3:::ecb-daily-exchange-rates-tfstate-${data.aws_caller_identity.current.account_id}/aws-daily-exchange-rates/terraform.tfstate",
      "arn:aws:s3:::ecb-daily-exchange-rates-tfstate-${data.aws_caller_identity.current.account_id}/aws-daily-exchange-rates/terraform.tfstate.tflock",
    ]
  }

  statement {
    sid    = "ApplicationBucket"
    effect = "Allow"

    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::${var.project_name}-${data.aws_caller_identity.current.account_id}",
      "arn:aws:s3:::${var.project_name}-${data.aws_caller_identity.current.account_id}/*",
    ]
  }

  statement {
    sid    = "ApplicationLambda"
    effect = "Allow"

    actions = [
      "lambda:*",
    ]

    resources = [
      "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}",
    ]
  }

  statement {
    sid    = "ApplicationLogs"
    effect = "Allow"

    actions = [
      "logs:*",
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}:*",
    ]
  }

  statement {
    sid    = "DescribeLogGroups"
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ApplicationSchedule"
    effect = "Allow"

    actions = [
      "scheduler:*",
    ]

    resources = [
      "arn:aws:scheduler:${var.aws_region}:${data.aws_caller_identity.current.account_id}:schedule/default/${var.project_name}-daily",
    ]
  }

  statement {
    sid    = "ApplicationRoles"
    effect = "Allow"

    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListRolePolicies",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-lambda-role",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-scheduler-role",
    ]
  }

  statement {
    sid    = "ReadGitHubIdentity"
    effect = "Allow"

    actions = [
      "iam:GetOpenIDConnectProvider",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListOpenIDConnectProviderTags",
      "iam:ListRolePolicies",
    ]

    resources = [
      aws_iam_openid_connect_provider.github.arn,
      aws_iam_role.github_actions.arn,
    ]
  }

  statement {
    sid    = "ReadLambdaManagedPolicy"
    effect = "Allow"

    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
    ]

    resources = [
      "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    ]
  }
}

resource "aws_iam_role_policy" "github_deploy" {
  name   = "${var.project_name}-deploy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_deploy.json
}