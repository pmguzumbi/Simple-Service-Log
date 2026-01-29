# Changelog

All notable changes to the Simple Log Service project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-29

### Added
- Initial release of Simple Log Service
- DynamoDB table for log storage with KMS encryption
- Ingest Lambda function for adding log entries
- Read Recent Lambda function for retrieving 100 most recent logs
- Lambda Function URLs with AWS IAM authentication
- KMS customer-managed key with automatic rotation
- CloudWatch Logs with KMS encryption
- AWS Config compliance monitoring with 4 rules:
  - DynamoDB table encryption
  - DynamoDB point-in-time recovery
  - CloudWatch log group encryption
  - KMS key rotation
- EventBridge rule for compliance change notifications
- SNS topic for compliance alerts
- S3 bucket for AWS Config storage
- Complete Terraform infrastructure as code
- Python Lambda functions with error handling
- Unit tests for both Lambda functions
- Secure invocation script using AWS SigV4
- Integration test script
- Setup script for initial deployment
- Comprehensive documentation:
  - README.md with quick start guide
  - ARCHITECTURE.md with detailed architecture
  - SECURITY.md with security best practices
  - COMPLIANCE.md with compliance monitoring
  - API.md with API reference
  - TROUBLESHOOTING.md with common issues
  - DATABASE_JUSTIFICATION.txt with database selection rationale
- GitHub Actions workflow for Terraform validation
- Contributing guidelines
- MIT License

### Security
- IAM authentication with temporary credentials
- Encryption at rest using KMS customer-managed keys
- Encryption in transit (TLS 1.2+)
- Point-in-time recovery enabled
- Deletion protection enabled
- CloudWatch logs encrypted
- Least privilege IAM policies
- AWS Config compliance monitoring
- Automated compliance alerts

## [Unreleased]

### Planned
- CloudWatch dashboard for monitoring
- X-Ray tracing integration
- Lambda layers for shared dependencies
- API Gateway integration (alternative to Function URLs)
- DynamoDB Streams for real-time processing
- ElastiCache for caching recent logs
- Multi-region deployment support
- Automated remediation for compliance violations
- Cost optimization recommendations
- Performance benchmarking results
