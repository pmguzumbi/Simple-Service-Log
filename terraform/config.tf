# AWS Config Configuration for Compliance Monitoring

# S3 Bucket for AWS Config
resource "aws_s3_bucket" "config" {
  bucket = "${var.project_name}-config-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-config-bucket"
  }
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.log_service.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket = aws_s3_bucket.config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config.arn
      },
      {
        Sid    = "AWSConfigBucketExistenceCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.config.arn
      },
      {
        Sid    = "AWSConfigBucketPutObject"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# IAM Role for AWS Config
resource "aws_iam_role" "config" {
  name = "${var.project_name}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-config-role"
  }
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

resource "aws_iam_role_policy" "config" {
  name = "${var.project_name}-config-policy"
  role = aws_iam_role.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.config.arn,
          "${aws_s3_bucket.config.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.compliance_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.log_service.arn
      }
    ]
  })
}

# AWS Config Recorder
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = false
    include_global_resource_types = false
    resource_types = [
      "AWS::DynamoDB::Table",
      "AWS::Lambda::Function",
      "AWS::KMS::Key",
      "AWS::Logs::LogGroup"
    ]
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config.bucket
  sns_topic_arn  = aws_sns_topic.compliance_alerts.arn

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

# Config Rules

# Rule: DynamoDB encryption at rest
resource "aws_config_config_rule" "dynamodb_encryption" {
  name = "${var.project_name}-dynamodb-encryption"

  source {
    owner             = "AWS"
    source_identifier = "DYNAMODB_TABLE_ENCRYPTED_KMS"
  }

  scope {
    compliance_resource_types = ["AWS::DynamoDB::Table"]
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Rule: DynamoDB point-in-time recovery
resource "aws_config_config_rule" "dynamodb_pitr" {
  name = "${var.project_name}-dynamodb-pitr"

  source {
    owner             = "AWS"
    source_identifier = "DYNAMODB_PITR_ENABLED"
  }

  scope {
    compliance_resource_types = ["AWS::DynamoDB::Table"]
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Rule: Lambda function in VPC (optional - commented out as not required)
# resource "aws_config_config_rule" "lambda_in_vpc" {
#   name = "${var.project_name}-lambda-in-vpc"
#
#   source {
#     owner             = "AWS"
#     source_identifier = "LAMBDA_INSIDE_VPC"
#   }
#
#   scope {
#     compliance_resource_types = ["AWS::Lambda::Function"]
#   }
#
#   depends_on = [aws_config_configuration_recorder.main]
# }

# Rule: CloudWatch log group encryption
resource "aws_config_config_rule" "cloudwatch_log_encryption" {
  name = "${var.project_name}-cloudwatch-log-encryption"

  source {
    owner             = "AWS"
    source_identifier = "CLOUDWATCH_LOG_GROUP_ENCRYPTED"
  }

  scope {
    compliance_resource_types = ["AWS::Logs::LogGroup"]
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# Rule: KMS key rotation
resource "aws_config_config_rule" "kms_rotation" {
  name = "${var.project_name}-kms-rotation"

  source {
    owner             = "AWS"
    source_identifier = "CMK_BACKING_KEY_ROTATION_ENABLED"
  }

  scope {
    compliance_resource_types = ["AWS::KMS::Key"]
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# EventBridge Rule for Config Compliance Changes
resource "aws_cloudwatch_event_rule" "config_compliance" {
  name        = "${var.project_name}-config-compliance-changes"
  description = "Capture AWS Config compliance changes"

  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      configRuleName = [
        aws_config_config_rule.dynamodb_encryption.name,
        aws_config_config_rule.dynamodb_pitr.name,
        aws_config_config_rule.cloudwatch_log_encryption.name,
        aws_config_config_rule.kms_rotation.name
      ]
      newEvaluationResult = {
        complianceType = ["NON_COMPLIANT"]
      }
    }
  })

  tags = {
    Name = "${var.project_name}-compliance-event-rule"
  }
}

resource "aws_cloudwatch_event_target" "config_compliance_sns" {
  rule      = aws_cloudwatch_event_rule.config_compliance.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.compliance_alerts.arn
}

resource "aws_sns_topic_policy" "config_compliance" {
  arn = aws_sns_topic.compliance_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.compliance_alerts.arn
      }
    ]
  })
}

