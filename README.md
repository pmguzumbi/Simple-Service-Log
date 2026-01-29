# Simple Log Service

A secure, serverless log ingestion and retrieval service built on AWS using DynamoDB and Lambda functions.

## Overview

This service provides two core capabilities:
- **Ingest logs**: Store log entries with severity levels (info, warning, error)
- **Retrieve logs**: Fetch the 100 most recent log entries

## Performance

### Benchmarks (p99 Latency)
- **Ingest API**: <100ms
- **Read Recent API**: <200ms

### Throughput
- **Ingest**: 1,000+ requests/second
- **Read Recent**: 500+ requests/second

### Availability
- **Target**: 99.9% uptime
- **Maximum downtime**: 43.2 minutes/month

See [docs/PERFORMANCE.md](docs/PERFORMANCE.md) for detailed performance metrics and optimization guidelines.

## Architecture

### Components
- **DynamoDB Table**: Stores log entries with automatic scaling
- **Ingest Lambda**: Accepts and stores log entries via Function URL
- **Read Recent Lambda**: Retrieves the 100 most recent logs via Function URL (optimized with GSI Query)
- **KMS**: Customer-managed keys for encryption at rest
- **CloudWatch**: Encrypted log groups for Lambda execution logs with alarms
- **AWS Config**: Compliance monitoring for security best practices
- **SNS**: Notifications for compliance violations
- **X-Ray**: Distributed tracing for performance monitoring

### Security Features
- IAM authentication with temporary credentials (AWS SigV4)
- Encryption at rest using KMS customer-managed keys
- Encryption in transit (TLS 1.2+)
- Point-in-time recovery enabled
- Deletion protection enabled
- CloudWatch logs encrypted with KMS
- AWS Config rules for compliance monitoring
- SNS notifications for violations
- Enhanced input validation to prevent injection attacks

### Monitoring & Alarms
- Lambda error rate alarms
- Lambda duration alarms
- Lambda throttle alarms
- DynamoDB throttle alarms
- DynamoDB error alarms
- CloudWatch Dashboard for real-time metrics

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

## Performance Testing

Run load tests to benchmark performance:

```bash
# Install Locust
pip install locust

# Set environment variables
export INGEST_URL=$(cd terraform && terraform output -raw ingest_function_url)
export READ_URL=$(cd terraform && terraform output -raw read_recent_function_url)

# Run load test
locust -f scripts/load_test.py --headless --users 100 --spawn-rate 10 --run-time 5m
```

## Monitoring

### CloudWatch Dashboard
Access the CloudWatch dashboard for real-time metrics:
```bash
aws cloudwatch get-dashboard --dashboard-name simple-log-service-dashboard
```

### View Alarms
```bash
aws cloudwatch describe-alarms --alarm-name-prefix simple-log-service
```

### CloudWatch Logs Insights
Query Lambda logs for errors:
```
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
```

## Cost Estimation

See [docs/COST_ESTIMATION.md](docs/COST_ESTIMATION.md) for detailed cost analysis:

- **Low Usage** (10K logs/month): ~$10/month
- **Medium Usage** (1M logs/month): ~$17/month
- **High Usage** (100M logs/month): ~$307/month
- **Enterprise** (1B logs/month): ~$2,750/month

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
