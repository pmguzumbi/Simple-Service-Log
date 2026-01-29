# Security Documentation

## Security Architecture

The Simple Log Service implements defense-in-depth security following AWS best practices and the AWS Well-Architected Framework Security Pillar.

## Authentication & Authorization

### IAM Authentication (AWS SigV4)
- All API requests must be signed using AWS Signature Version 4
- Uses temporary credentials from AWS STS
- No long-lived API keys or passwords
- Credentials automatically rotate

### IAM Policies
- Least privilege principle applied to all roles
- Separate roles for each Lambda function
- Explicit permissions (no wildcards)
- Resource-level permissions where possible

### Lambda Function URLs
- Authorization Type: AWS_IAM (not NONE)
- Requires valid AWS credentials to invoke
- CORS configured for secure cross-origin requests

## Encryption

### Encryption at Rest
- **DynamoDB Table**: Encrypted with KMS customer-managed key
- **CloudWatch Logs**: Encrypted with KMS customer-managed key
- **SNS Topic**: Encrypted with KMS customer-managed key
- **S3 Bucket (Config)**: Encrypted with KMS customer-managed key

### Encryption in Transit
- All communications use TLS 1.2 or higher
- Lambda Function URLs enforce HTTPS
- AWS SDK uses HTTPS by default
- No unencrypted data transmission

### Key Management
- Customer-managed KMS key (not AWS-managed)
- Automatic key rotation enabled (annual)
- Key deletion window: 30 days
- Separate key alias for easy identification

## Data Protection

### DynamoDB
- **Point-in-Time Recovery**: Enabled (35-day retention)
- **Deletion Protection**: Enabled (prevents accidental deletion)
- **Backup**: Continuous backups via PITR
- **Access Control**: IAM policies restrict access

### Input Validation
- Severity must be: info, warning, or error
- Message maximum length: 10KB
- JSON schema validation
- SQL injection not applicable (NoSQL database)

### Data Retention
- CloudWatch Logs: 30-day retention
- DynamoDB: Indefinite (manual deletion required)
- AWS Config: Historical data in S3

## Network Security

### VPC (Optional)
- Lambda functions can run in VPC if required
- Not implemented by default (adds complexity and cost)
- Function URLs work with or without VPC

### Security Groups
- Not applicable (Lambda Function URLs are public endpoints)
- Authentication via IAM provides access control

### Network Isolation
- DynamoDB is a managed service (no network exposure)
- Lambda execution environment is isolated
- KMS is a managed service (no network exposure)

## Compliance & Monitoring

### AWS Config
- Continuous compliance monitoring
- Automated rule evaluation
- Configuration change tracking
- Compliance dashboard

### Config Rules Implemented
1. **DYNAMODB_TABLE_ENCRYPTED_KMS**: Ensures DynamoDB uses KMS encryption
2. **DYNAMODB_PITR_ENABLED**: Ensures point-in-time recovery is enabled
3. **CLOUDWATCH_LOG_GROUP_ENCRYPTED**: Ensures CloudWatch Logs are encrypted
4. **CMK_BACKING_KEY_ROTATION_ENABLED**: Ensures KMS key rotation is enabled

### Alerting
- EventBridge captures compliance violations
- SNS sends email notifications
- Real-time alerts for security issues

### Audit Logging
- CloudWatch Logs capture all Lambda executions
- AWS CloudTrail captures all API calls (account-level)
- DynamoDB streams can be enabled for change tracking

## Incident Response

### Detection
- AWS Config detects non-compliant resources
- CloudWatch Logs provide execution details
- SNS alerts notify security team

### Response Procedures
1. Receive SNS notification
2. Review AWS Config compliance dashboard
3. Investigate CloudWatch Logs
4. Remediate non-compliant resource
5. Verify compliance
