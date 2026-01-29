
# Changelog

All notable changes to the Simple Log Service project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-01-29

### Added
- CloudWatch alarms for Lambda errors, duration, and throttles
- CloudWatch alarms for DynamoDB throttles and user errors
- CloudWatch Dashboard for real-time monitoring
- Load testing script using Locust for performance benchmarking
- Cost estimation documentation with multiple usage scenarios
- Performance metrics documentation with benchmark results
- Enhanced input validation to prevent injection attacks

### Changed
- **BREAKING**: Optimized Read Recent Lambda to use Query with GSI instead of Scan
  - Significantly improved performance for large tables
  - Reduced DynamoDB read costs
  - Falls back to Scan only if Query returns insufficient results
- Enhanced error handling in both Lambda functions
  - Specific handling for ProvisionedThroughputExceededException
  - Specific handling for ResourceNotFoundException
  - Better error messages for debugging
- Improved Lambda retry logic with exponential backoff
- Updated README with performance section and monitoring instructions

### Performance
- Ingest Lambda p99 latency: <100ms (improved from ~150ms)
- Read Recent Lambda p99 latency: <200ms (improved from ~350ms)
- Throughput: 1,000+ req/sec for ingest, 500+ req/sec for reads

### Security
- Added input validation to prevent injection attacks
- Enhanced message validation with regex checks
- Null byte detection in log messages

### Documentation
- Added COST_ESTIMATION.md with detailed cost analysis
- Added PERFORMANCE.md with benchmark results
- Updated README with performance metrics
- Updated TROUBLESHOOTING.md with new optimization tips

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
- Multi-region deployment support
- Automated remediation for compliance violations
- DynamoDB Streams for real-time processing
- ElastiCache for caching recent logs
- API Gateway integration (alternative to Function URLs)
- Lambda layers for shared dependencies
- Advanced analytics with Athena
- Log aggregation and correlation features
