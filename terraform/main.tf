# Core infrastructure for Simple Log Service

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "simple-log-service"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}

# Data source for account ID
data "aws_caller_identity" "current" {}

# KMS Key for DynamoDB and CloudWatch Logs encryption
resource "aws_kms_key" "log_service" {
  description             = "KMS key for Simple Log Service encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      },
      {
        Sid    = "Allow DynamoDB"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "dynamodb.${var.aws_region}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "Allow SNS"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-kms-key"
  }
}

resource "aws_kms_alias" "log_service" {
  name          = "alias/${var.project_name}"
  target_key_id = aws_kms_key.log_service.key_id
}

# DynamoDB Table
resource "aws_dynamodb_table" "log_entries" {
  name           = "${var.project_name}-entries"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "datetime"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "datetime"
    type = "S"
  }

  global_secondary_index {
    name            = "datetime-index"
    hash_key        = "datetime"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.log_service.arn
  }

  deletion_protection_enabled = var.enable_deletion_protection

  tags = {
    Name = "${var.project_name}-table"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "ingest_lambda" {
  name              = "/aws/lambda/${var.project_name}-ingest"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.log_service.arn

  tags = {
    Name = "${var.project_name}-ingest-logs"
  }
}

resource "aws_cloudwatch_log_group" "read_recent_lambda" {
  name              = "/aws/lambda/${var.project_name}-read-recent"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.log_service.arn

  tags = {
    Name = "${var.project_name}-read-recent-logs"
  }
}

# IAM Role for Ingest Lambda
resource "aws_iam_role" "ingest_lambda" {
  name = "${var.project_name}-ingest-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ingest-role"
  }
}

resource "aws_iam_role_policy" "ingest_lambda" {
  name = "${var.project_name}-ingest-lambda-policy"
  role = aws_iam_role.ingest_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = aws_dynamodb_table.log_entries.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.log_service.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ingest_lambda.arn}:*"
      }
    ]
  })
}

# IAM Role for Read Recent Lambda
resource "aws_iam_role" "read_recent_lambda" {
  name = "${var.project_name}-read-recent-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-read-recent-role"
  }
}

resource "aws_iam_role_policy" "read_recent_lambda" {
  name = "${var.project_name}-read-recent-lambda-policy"
  role = aws_iam_role.read_recent_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.log_entries.arn,
          "${aws_dynamodb_table.log_entries.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.log_service.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.read_recent_lambda.arn}:*"
      }
    ]
  })
}

# Package Lambda functions
data "archive_file" "ingest_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/ingest"
  output_path = "${path.module}/ingest_lambda.zip"
  excludes    = ["tests", "__pycache__", "*.pyc"]
}

data "archive_file" "read_recent_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/read_recent"
  output_path = "${path.module}/read_recent_lambda.zip"
  excludes    = ["tests", "__pycache__", "*.pyc"]
}

# Ingest Lambda Function
resource "aws_lambda_function" "ingest" {
  filename         = data.archive_file.ingest_lambda.output_path
  function_name    = "${var.project_name}-ingest"
  role            = aws_iam_role.ingest_lambda.arn
  handler         = "index.lambda_handler"
  source_code_hash = data.archive_file.ingest_lambda.output_base64sha256
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.log_entries.name
    }
  }

  logging_config {
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.ingest_lambda.name
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name = "${var.project_name}-ingest-function"
  }

  depends_on = [
    aws_cloudwatch_log_group.ingest_lambda
  ]
}

# Read Recent Lambda Function
resource "aws_lambda_function" "read_recent" {
  filename         = data.archive_file.read_recent_lambda.output_path
  function_name    = "${var.project_name}-read-recent"
  role            = aws_iam_role.read_recent_lambda.arn
  handler         = "index.lambda_handler"
  source_code_hash = data.archive_file.read_recent_lambda.output_base64sha256
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.log_entries.name
    }
  }

  logging_config {
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.read_recent_lambda.name
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name = "${var.project_name}-read-recent-function"
  }

  depends_on = [
    aws_cloudwatch_log_group.read_recent_lambda
  ]
}

# Lambda Function URLs with IAM Auth
resource "aws_lambda_function_url" "ingest" {
  function_name      = aws_lambda_function.ingest.function_name
  authorization_type = "AWS_IAM"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["POST"]
    allow_headers     = ["*"]
    max_age          = 86400
  }
}

resource "aws_lambda_function_url" "read_recent" {
  function_name      = aws_lambda_function.read_recent.function_name
  authorization_type = "AWS_IAM"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET"]
    allow_headers     = ["*"]
    max_age          = 86400
  }
}

# SNS Topic for Compliance Notifications
resource "aws_sns_topic" "compliance_alerts" {
  name              = "${var.project_name}-compliance-alerts"
  kms_master_key_id = aws_kms_key.log_service.id

  tags = {
    Name = "${var.project_name}-compliance-topic"
  }
}

resource "aws_sns_topic_subscription" "compliance_email" {
  count     = var.compliance_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.compliance_alerts.arn
  protocol  = "email"
  endpoint  = var.compliance_email
}
