# CloudWatch Alarms and Monitoring Configuration

# SNS Topic for Alarms (reuse compliance alerts topic)
# Already defined in main.tf, so we'll reference it

# Lambda Error Alarms

resource "aws_cloudwatch_metric_alarm" "ingest_lambda_errors" {
  alarm_name          = "${var.project_name}-ingest-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when ingest Lambda has more than 5 errors in 5 minutes"
  alarm_actions       = [aws_sns_topic.compliance_alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.ingest.function_name
  }

  tags = {
    Name = "${var.project_name}-ingest-errors-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "read_recent_lambda_errors" {
  alarm_name          = "${var.project_name}-read-recent-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when read recent Lambda has more than 5 errors in 5 minutes"
  alarm_actions       = [aws_sns_topic.compliance_alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.read_recent.function_name
  }

  tags = {
    Name = "${var.project_name}-read-recent-errors-alarm"
  }
}

# Lambda Duration Alarms

resource "aws_cloudwatch_metric_alarm" "ingest_lambda_duration" {
  alarm_name          = "${var.project_name}-ingest-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000"  # 5 seconds
  alarm_description   = "Alert when ingest Lambda average duration exceeds 5 seconds"
  alarm_actions       = [aws_sns_topic.compliance_alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.ingest.function_name
  }

  tags = {
    Name = "${var.project_name}-ingest-duration-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "read_recent_lambda_duration" {
  alarm_name          = "${var.project_name}-read-recent-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "10000"  # 10 seconds
  alarm_description   = "Alert when read recent Lambda average duration exceeds 10 seconds"
  alarm_actions       = [aws_sns_topic.compliance_alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.read_recent.function_name
  }

  tags = {
    Name = "${var.project_name}-read-recent-duration-alarm"
  }
}

# Lambda Throttle Alarms

resource "aws_cloudwatch_metric_alarm" "ingest_lambda_throttles" {
  alarm_name          = "${var.project_name}-ingest-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when ingest Lambda is throttled more than 10 times in 5 minutes"
  alarm_actions       = [aws_sns_topic.compliance_alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.ingest.function_name
  }

  tags = {
    Name = "${var.project_name}-ingest-throttles-alarm"
  }
}

# DynamoDB Alarms

resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttles" {
  alarm_name          = "${var.project_name}-dynamodb-read-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ReadThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when DynamoDB read operations are throttled"
  alarm_actions       = [aws_sns_topic.compliance_alerts.arn]

  dimensions = {
    TableName = aws_dynamodb_table.log_entries.name
  }

  tags = {
    Name = "${var.project_name}-dynamodb-read-throttles-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttles" {
  alarm_name          = "${var.project_name}-dynamodb-write-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "WriteThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when DynamoDB write operations are throttled"
  alarm_actions       = [aws_sns_topic.compliance_alerts.arn]

  dimensions = {
    TableName = aws_dynamodb_table.log_entries.name
  }

  tags = {
    Name = "${var.project_name}-dynamodb-write-throttles-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_user_errors" {
  alarm_name          = "${var.project_name}-dynamodb-user-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "20"
  alarm_description   = "Alert when DynamoDB has more than 20 user errors in 5 minutes"
  alarm_actions       = [aws_sns_topic.compliance_alerts.arn]

  dimensions = {
    TableName = aws_dynamodb_table.log_entries.name
  }

  tags = {
    Name = "${var.project_name}-dynamodb-user-errors-alarm"
  }
}

# CloudWatch Dashboard

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Ingest Invocations" }],
            [".", ".", { stat = "Sum", label = "Read Recent Invocations" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Invocations"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", { stat = "Sum", label = "Ingest Errors" }],
            [".", ".", { stat = "Sum", label = "Read Recent Errors" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Errors"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", { stat = "Average", label = "Ingest Duration" }],
            [".", ".", { stat = "Average", label = "Read Recent Duration" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Lambda Duration (ms)"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", { stat = "Sum" }],
            [".", "ConsumedWriteCapacityUnits", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "DynamoDB Capacity Units"
        }
      }
    ]
  })

  depends_on = [
    aws_lambda_function.ingest,
    aws_lambda_function.read_recent,
    aws_dynamodb_table.log_entries
  ]
}

