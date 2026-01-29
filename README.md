# Simple Log Service

A secure, serverless log ingestion and retrieval service built on AWS using DynamoDB and Lambda functions.

## Overview

This service provides two core capabilities:
- **Ingest logs**: Store log entries with severity levels (info, warning, error)
- **Retrieve logs**: Fetch the 100 most recent log entries

## Architecture

### Components
- **DynamoDB Table**: Stores log entries with automatic scaling
- **Ingest Lambda**: Accepts and stores log entries via Function URL
- **Read Recent Lambda**: Retrieves the 100 most recent logs via Function URL
- **KMS**: Customer-managed keys for encryption at rest
- **CloudWatch**: Encrypted log groups for Lambda execution logs
- **AWS Config**: Compliance monitoring for security best practices
- **SNS**: Notifications for compliance violations

### Security Features
- IAM authentication with temporary credentials (AWS SigV4)
- Encryption at rest using KMS customer-managed keys
- Encryption in transit (TLS 1.2+)
- Point-in-time recovery enabled
- Deletion protection enabled
- CloudWatch logs encrypted with KMS
- AWS Config rules for compliance monitoring
- SNS notifications for violations

## Database Design

**Table**: `log-entries`

**Primary Key**:
- Partition Key: `id` (String) - UUID v4
- Sort Key: `datetime` (String) - ISO 8601 timestamp

**Attributes**:
- `id`: Unique identifier (UUID)
- `datetime`: ISO 8601 timestamp with milliseconds
- `severity`: Enum (info, warning, error)
- `message`: Log message text (max 10KB)

**Indexes**:
- GSI: `datetime-index` - Enables efficient querying by datetime descending

**Rationale**: See `docs/DATABASE_JUSTIFICATION.txt`

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0
- Python 3.11+
- Git

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/your-org/simple-log-service.git
cd simple-log-service
```

### 2. Configure Variables
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

### 4. Get Function URLs
```bash
terraform output ingest_function_url
terraform output read_recent_function_url
```

### 5. Test the Service
```bash
cd ../scripts
./test_service.sh
```

## Usage

### Ingest a Log Entry

Using the secure invocation script (recommended):
```bash
python scripts/invoke_with_sigv4.py ingest \
  --severity info \
  --message "Application started successfully"
```

### Retrieve Recent Logs

```bash
python scripts/invoke_with_sigv4.py read-recent
```

## API Reference

See `docs/API.md` for detailed API documentation.

## Security

See `docs/SECURITY.md` for security architecture and best practices.

## Compliance

See `docs/COMPLIANCE.md` for AWS Config rules and compliance monitoring.

## Troubleshooting

See `docs/TROUBLESHOOTING.md` for common issues and solutions.

## CI/CD

GitHub Actions workflow automatically validates Terraform on pull requests.

## Contributing

See `CONTRIBUTING.md` for contribution guidelines.

## License

MIT License - See `LICENSE` file.

## Changelog

See `CHANGELOG.md` for version history.

