# Architecture Documentation

## Overview

The Simple Log Service is a serverless application built on AWS that provides secure log ingestion and retrieval capabilities. The architecture follows AWS best practices for security, scalability, and operational excellence.

## Architecture Diagram

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ HTTPS + AWS SigV4
       │
       ├──────────────────────────────┬────────────────────────────┐
       │                              │                            │
       ▼                              ▼                            ▼
┌──────────────┐              ┌──────────────┐            ┌──────────────┐
│   Ingest     │              │ Read Recent  │            │  AWS Config  │
│   Lambda     │              │   Lambda     │            │   Recorder   │
│  (Function   │              │  (Function   │            └──────┬───────┘
│     URL)     │              │     URL)     │                   │
└──────┬───────┘              └──────┬───────┘                   │
       │                             │                           │
       │ Write                       │ Read                      │ Monitor
       │                             │                           │
       ▼                             ▼                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DynamoDB Table                           │
│                      (log-entries)                              │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Primary Key: id (Partition) + datetime (Sort)            │  │
│  │ GSI: datetime-index                                      │  │
│  │ Encryption: KMS Customer-Managed Key                     │  │
│  │ Point-in-Time Recovery: Enabled                          │  │
│  │ Deletion Protection: Enabled                             │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
       │                             │
       │                             │
       ▼                             ▼
┌──────────────┐              ┌──────────────┐
│  CloudWatch  │              │     KMS      │
│     Logs     │              │     Key      │
│  (Encrypted) │              │  (Rotation   │
│              │              │   Enabled)   │
└──────────────┘              └──────────────┘
       │
       │ Compliance Violations
       ▼
┌──────────────┐
│     SNS      │
│    Topic     │
│  (Encrypted) │
└──────────────┘
```

## Components

### 1. Lambda Functions

#### Ingest Lambda
- **Purpose**: Accept and store log entries
- **Runtime**: Python 3.11
- **Memory**: 256 MB
- **Timeout**: 30 seconds
- **Authentication**: AWS IAM (SigV4)
- **Invocation**: Lambda Function URL (HTTPS)

**Responsibilities**:
- Validate input (severity, message)
- Generate unique ID (UUID v4)
- Create ISO 8601 timestamp
- Store entry in DynamoDB
- Return success/error response

#### Read Recent Lambda
- **Purpose**: Retrieve 100 most recent log entries
- **Runtime**: Python 3.11
- **Memory**: 256 MB
- **Timeout**: 30 seconds
- **Authentication**: AWS IAM (SigV4)
- **Invocation**: Lambda Function URL (HTTPS)

**Responsibilities**:
- Scan DynamoDB table
- Handle pagination
- Sort by datetime descending
- Return top 100 entries

### 2. DynamoDB Table

**Table Name**: `simple-log-service-entries`

**Primary Key**:
- Partition Key: `id` (String) - UUID v4
- Sort Key: `datetime` (String) - ISO 8601 timestamp

**Global Secondary Index**:
- Name: `datetime-index`
- Partition Key: `datetime`
- Projection: ALL

**Configuration**:
- Billing Mode: PAY_PER_REQUEST (on-demand)
- Encryption: KMS customer-managed key
- Point-in-Time Recovery: Enabled
- Deletion Protection: Enabled

### 3. Security Components

#### KMS Key
- Customer-managed encryption key
- Automatic key rotation enabled
- Used for:
  - DynamoDB table encryption
  - CloudWatch Logs encryption
  - SNS topic encryption
  - S3 bucket encryption (AWS Config)

#### IAM Roles
- **Ingest Lambda Role**: DynamoDB PutItem, KMS Decrypt/GenerateDataKey, CloudWatch Logs
- **Read Recent Lambda Role**: DynamoDB Query/Scan, KMS Decrypt, CloudWatch Logs
- **AWS Config Role**: S3 access, SNS Publish, KMS operations

### 4. Monitoring & Compliance

#### CloudWatch Logs
- Separate log groups for each Lambda
- JSON log format
- 30-day retention
- KMS encryption

#### AWS Config
- Monitors compliance with security best practices
- Configuration recorder for DynamoDB, Lambda, KMS, CloudWatch
- Config rules:
  - DynamoDB encryption at rest
  - DynamoDB point-in-time recovery
  - CloudWatch log group encryption
  - KMS key rotation

#### EventBridge
- Captures Config compliance changes
- Triggers SNS notifications for violations

#### SNS Topic
- Receives compliance violation alerts
- KMS encrypted
- Email subscription for notifications

## Data Flow

### Ingest Flow
1. Client signs request with AWS SigV4 using temporary credentials
2. HTTPS POST to Ingest Lambda Function URL
3. Lambda validates input (severity, message)
4. Lambda generates ID and timestamp
5. Lambda writes to DynamoDB with KMS encryption
6. Lambda returns success response
7. CloudWatch Logs captures execution logs

### Read Recent Flow
1. Client signs request with AWS SigV4 using temporary credentials
2. HTTPS GET to Read Recent Lambda Function URL
3. Lambda scans DynamoDB table
4. Lambda handles pagination if needed
5. Lambda sorts results by datetime descending
6. Lambda returns top 100 entries
7. CloudWatch Logs captures execution logs

### Compliance Monitoring Flow
1. AWS Config continuously monitors resources
2. Config evaluates compliance rules
3. Non-compliant changes trigger EventBridge rule
4. EventBridge publishes to SNS topic
5. SNS sends email notification to administrators

## Scalability

- **DynamoDB**: On-demand billing scales automatically
- **Lambda**: Concurrent executions scale automatically (up to account limits)
- **Function URLs**: No API Gateway throttling limits
- **CloudWatch Logs**: Unlimited ingestion capacity

## High Availability

- **DynamoDB**: Multi-AZ replication by default
- **Lambda**: Runs in multiple AZs automatically
- **KMS**: Multi-AZ service
- **CloudWatch**: Multi-AZ service

## Disaster Recovery

- **DynamoDB Point-in-Time Recovery**: Restore to any point in last 35 days
- **DynamoDB Deletion Protection**: Prevents accidental table deletion
- **Infrastructure as Code**: Complete infrastructure can be recreated from Terraform
- **AWS Config History**: S3 bucket stores configuration history

## Cost Optimization

- **DynamoDB**: Pay-per-request pricing (no idle costs)
- **Lambda**: Pay only for execution time
- **CloudWatch Logs**: 30-day retention reduces storage costs
- **KMS**: Single key for all encryption needs

## Security Considerations

1. **Authentication**: AWS IAM with temporary credentials (no API keys)
2. **Authorization**: IAM policies with least privilege
3. **Encryption at Rest**: KMS customer-managed keys
4. **Encryption in Transit**: TLS 1.2+ for all communications
5. **Audit Logging**: CloudWatch Logs for all operations
6. **Compliance Monitoring**: AWS Config with automated alerts
7. **Data Protection**: Deletion protection and point-in-time recovery

