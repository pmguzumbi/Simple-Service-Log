# Output values

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.log_entries.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.log_entries.arn
}

output "ingest_function_name" {
  description = "Name of the ingest Lambda function"
  value       = aws_lambda_function.ingest.function_name
}

output "ingest_function_arn" {
  description = "ARN of the ingest Lambda function"
  value       = aws_lambda_function.ingest.arn
}

output "ingest_function_url" {
  description = "Function URL for ingest Lambda (requires IAM auth)"
  value       = aws_lambda_function_url.ingest.function_url
}

output "read_recent_function_name" {
  description = "Name of the read recent Lambda function"
  value       = aws_lambda_function.read_recent.function_name
}

output "read_recent_function_arn" {
  description = "ARN of the read recent Lambda function"
  value       = aws_lambda_function.read_recent.arn
}

output "read_recent_function_url" {
  description = "Function URL for read recent Lambda (requires IAM auth)"
  value       = aws_lambda_function_url.read_recent.function_url
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.log_service.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.log_service.arn
}

output "compliance_sns_topic_arn" {
  description = "ARN of the compliance alerts SNS topic"
  value       = aws_sns_topic.compliance_alerts.arn
}

output "config_bucket_name" {
  description = "Name of the AWS Config S3 bucket"
  value       = aws_s3_bucket.config.id
}


