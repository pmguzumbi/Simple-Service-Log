# Cost Estimation

## Overview

This document provides estimated monthly costs for running the Simple Log Service on AWS. Costs are based on AWS pricing as of January 2026 in the us-east-1 region.

## Cost Components

### 1. DynamoDB

**Pricing Model**: On-Demand (Pay-per-request)

**Write Requests**:
- $1.25 per million write request units
- Each log entry = 1 write request unit

**Read Requests**:
- $0.25 per million read request units
- Each query for 100 logs = ~1-2 read request units (with GSI)

**Storage**:
- $0.25 per GB-month
- Average log entry size: ~500 bytes
- 1 million logs ≈ 0.5 GB

**Point-in-Time Recovery**:
- $0.20 per GB-month

### 2. Lambda

**Invocation Pricing**:
- $0.20 per million requests

**Duration Pricing**:
- $0.0000166667 per GB-second
- 256 MB memory = 0.25 GB
- Average duration: 100ms = 0.1 seconds
- Cost per invocation: $0.0000004167

### 3. CloudWatch Logs

**Log Ingestion**:
- $0.50 per GB ingested
- Average log size per Lambda execution: 1 KB
- 1 million executions = 1 GB

**Log Storage**:
- $0.03 per GB-month
- 30-day retention

### 4. KMS

**Key Storage**:
- $1.00 per month per customer-managed key

**API Requests**:
- First 20,000 requests/month: Free
- Additional requests: $0.03 per 10,000 requests

### 5. AWS Config

**Configuration Items**:
- $0.003 per configuration item recorded
- ~4 resources monitored = ~$0.012/month

**Config Rules**:
- $2.00 per active rule per region per month
- 4 rules = $8.00/month

### 6. SNS

**Notifications**:
- $0.50 per million requests
- Email notifications: Free (first 1,000)

### 7. S3 (AWS Config Storage)

**Storage**:
- $0.023 per GB-month (Standard)
- Config snapshots: ~10 MB/month

**Requests**:
- PUT requests: $0.005 per 1,000 requests
- GET requests: $0.0004 per 1,000 requests

## Cost Scenarios

### Scenario 1: Low Usage (Development/Testing)
**Assumptions**:
- 10,000 log entries/month
- 1,000 read requests/month
- Minimal storage (<1 GB)

| Service | Monthly Cost |
|---------|--------------|
| DynamoDB (writes) | $0.01 |
| DynamoDB (reads) | $0.00 |
| DynamoDB (storage) | $0.25 |
| DynamoDB (PITR) | $0.20 |
| Lambda (invocations) | $0.00 |
| Lambda (duration) | $0.01 |
| CloudWatch Logs | $0.50 |
| KMS | $1.00 |
| AWS Config | $8.01 |
| SNS | $0.00 |
| S3 | $0.01 |
| **Total** | **$9.99/month** |

### Scenario 2: Medium Usage (Small Production)
**Assumptions**:
- 1 million log entries/month
- 100,000 read requests/month
- 10 GB storage

| Service | Monthly Cost |
|---------|--------------|
| DynamoDB (writes) | $1.25 |
| DynamoDB (reads) | $0.03 |
| DynamoDB (storage) | $2.50 |
| DynamoDB (PITR) | $2.00 |
| Lambda (invocations) | $0.22 |
| Lambda (duration) | $0.46 |
| CloudWatch Logs | $1.50 |
| KMS | $1.00 |
| AWS Config | $8.01 |
| SNS | $0.00 |
| S3 | $0.25 |
| **Total** | **$17.22/month** |

### Scenario 3: High Usage (Large Production)
**Assumptions**:
- 100 million log entries/month
- 10 million read requests/month
- 100 GB storage

| Service | Monthly Cost |
|---------|--------------|
| DynamoDB (writes) | $125.00 |
| DynamoDB (reads) | $2.50 |
| DynamoDB (storage) | $25.00 |
| DynamoDB (PITR) | $20.00 |
| Lambda (invocations) | $22.00 |
| Lambda (duration) | $45.83 |
| CloudWatch Logs | $55.00 |
| KMS | $1.00 |
| AWS Config | $8.01 |
| SNS | $0.01 |
| S3 | $2.50 |
| **Total** | **$306.85/month** |

### Scenario 4: Enterprise Usage
**Assumptions**:
- 1 billion log entries/month
- 100 million read requests/month
- 500 GB storage

| Service | Monthly Cost |
|---------|--------------|
| DynamoDB (writes) | $1,250.00 |
| DynamoDB (reads) | $25.00 |
| DynamoDB (storage) | $125.00 |
| DynamoDB (PITR) | $100.00 |
| Lambda (invocations) | $220.00 |
| Lambda (duration) | $458.33 |
| CloudWatch Logs | $550.00 |
| KMS | $1.00 |
| AWS Config | $8.01 |
| SNS | $0.05 |
| S3 | $12.00 |
| **Total** | **$2,749.39/month** |

## Cost Optimization Strategies

### 1. DynamoDB Optimization
- **Use Provisioned Capacity** for predictable workloads (can save 50-70%)
- **Enable Auto Scaling** to match capacity with demand
- **Implement TTL** to automatically delete old logs
- **Use DynamoDB Streams** instead of polling for real-time processing

### 2. Lambda Optimization
- **Optimize memory allocation** (test 128MB vs 256MB)
- **Reduce cold starts** with provisioned concurrency (if needed)
- **Batch operations** where possible
- **Use Lambda layers** for shared dependencies

### 3. CloudWatch Logs Optimization
- **Reduce log verbosity** in production
- **Shorten retention period** (7 days instead of 30)
- **Export to S3** for long-term storage (cheaper)
- **Use CloudWatch Logs Insights** instead of storing all logs

### 4. Storage Optimization
- **Implement log rotation** (delete logs older than X days)
- **Compress logs** before storage
- **Use S3 Glacier** for archival (if compliance requires)
- **Enable S3 Intelligent-Tiering** for Config bucket

### 5. Monitoring Optimization
- **Reduce Config rule frequency** (daily instead of continuous)
- **Disable unused Config rules**
- **Use CloudWatch Contributor Insights** for targeted monitoring
- **Set up budget alerts** to track spending

## Cost Comparison: On-Demand vs Provisioned

### DynamoDB Provisioned Capacity Pricing

**Write Capacity Units (WCU)**:
- $0.00065 per WCU-hour
- 1 WCU = 1 write/second

**Read Capacity Units (RCU)**:
- $0.00013 per RCU-hour
- 1 RCU = 1 strongly consistent read/second

### Example: 1 Million Logs/Month

**On-Demand**:
- Cost: $1.25 (writes) + $0.03 (reads) = $1.28

**Provisioned (10 WCU, 5 RCU)**:
- Cost: (10 × $0.00065 × 730) + (5 × $0.00013 × 730) = $5.22

**Recommendation**: Use on-demand for unpredictable workloads, provisioned for steady traffic.

## AWS Free Tier Benefits

**First 12 Months**:
- Lambda: 1 million requests/month free
- DynamoDB: 25 GB storage, 25 WCU, 25 RCU free
- CloudWatch: 10 custom metrics, 10 alarms free
- KMS: 20,000 requests/month free

**Always Free**:
- Lambda: 1 million requests/month
- CloudWatch: 5 GB log ingestion, 5 GB archive

## Budget Recommendations

### Development Environment
- **Budget**: $10-20/month
- **Alerts**: >$15/month

### Staging Environment
- **Budget**: $20-50/month
- **Alerts**: >$40/month

### Production Environment
- **Budget**: $50-500/month (depending on scale)
- **Alerts**: >80% of budget

## Cost Monitoring

### CloudWatch Billing Alarms
Set up alarms for:
- Total estimated charges > $50
- DynamoDB costs > $20
- Lambda costs > $10

### AWS Cost Explorer
- Review costs weekly
- Identify cost trends
- Forecast future costs

### AWS Budgets
- Set monthly budget
- Configure email alerts at 50%, 80%, 100%
- Track by service and tag

## ROI Analysis

### Cost vs Alternatives

**Self-Hosted ELK Stack (EC2)**:
- 3 × t3.medium instances: ~$75/month
- EBS storage (500 GB): ~$50/month
- Data transfer: ~$10/month
- **Total**: ~$135/month + operational overhead

**Managed Service (CloudWatch Logs)**:
- 1 billion log events: ~$500/month
- Storage (500 GB): ~$25/month
- **Total**: ~$525/month

**Simple Log Service**:
- 1 billion log entries: ~$2,750/month
- **Advantage**: Serverless, no operational overhead, auto-scaling

## Conclusion

The Simple Log Service provides cost-effective log management for most use cases:
- **Small workloads**: <$20/month
- **Medium workloads**: $20-100/month
- **Large workloads**: $100-500/month
- **Enterprise workloads**: $500-3,000/month

Key cost drivers are DynamoDB writes and Lambda invocations. Optimize by implementing log rotation, using provisioned capacity for predictable workloads, and reducing CloudWatch Logs retention.
