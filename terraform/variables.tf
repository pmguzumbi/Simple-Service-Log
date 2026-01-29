# Input variables

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "simple-log-service"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for DynamoDB table"
  type        = bool
  default     = true
}

variable "compliance_email" {
  description = "Email address for compliance notifications"
  type        = string
  default     = ""
}


