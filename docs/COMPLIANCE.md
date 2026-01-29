# Compliance Documentation

## Overview

The Simple Log Service implements comprehensive compliance monitoring using AWS Config to ensure adherence to security best practices and organizational policies.

## AWS Config Setup

### Configuration Recorder
- **Name**: `simple-log-service-recorder`
- **Recording Scope**: Selected resource types only
- **Resource Types Monitored**:
  - AWS::DynamoDB::Table
  - AWS::Lambda::Function
  - AWS::KMS::Key
  - AWS::Logs::LogGroup

### Delivery Channel
- **S3 Bucket**: `simple-log-service-config-{account-id}`
- **SNS Topic**: `simple-log-service-compliance-alerts`
- **Delivery Frequency**: Configuration changes and compliance evaluations

## Compliance Rules

### 1. DynamoDB Table Encryption (DYNAMODB_TABLE_ENCRYPTED_KMS)
**Purpose**: Ensures all DynamoDB tables use KMS customer-managed keys for encryption

**Evaluation**:
- Checks if `SSEDescription.SSEType` is `KMS`
- Verifies KMS key is customer-managed (not AWS-managed)

**Compliance Criteria**:
- ✅ COMPLIANT: Table encrypted with customer-managed KMS key
- ❌ NON_COMPLIANT: Table not encrypted or using AWS-managed key

**Remediation**:
1. Enable encryption on the table
2. Specify customer-managed KMS key ARN
3. Re-deploy with Terraform

### 2. DynamoDB Point-in-Time Recovery (DYNAMODB_PITR_ENABLED)
**Purpose**: Ensures continuous backups are enabled for disaster recovery

**Evaluation**:
- Checks if `ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus` is `ENABLED`

**Compliance Criteria**:
- ✅ COMPLIANT: PITR enabled
- ❌ NON_COMPLIANT: PITR disabled

**Remediation**:
1. Enable point-in-time recovery in DynamoDB console or Terraform
2. Verify `point_in_time_recovery.enabled = true` in Terraform

### 3. CloudWatch Log Group Encryption (CLOUDWATCH_LOG_GROUP_ENCRYPTED)
**Purpose**: Ensures all log data is encrypted at rest

**Evaluation**:
- Checks if `kmsKeyId` is present and valid

**Compliance Criteria**:
- ✅ COMPLIANT: Log group encrypted with KMS key
- ❌ NON_COMPLIANT: Log group not encrypted

**Remediation**:
1. Specify `kms_key_id` in CloudWatch log group resource
2. Ensure KMS key policy allows CloudWatch Logs service

### 4. KMS Key Rotation (CMK_BACKING_KEY_ROTATION_ENABLED)
**Purpose**: Ensures cryptographic best practices with automatic key rotation

**Evaluation**:
- Checks if `KeyRotationEnabled` is `true`

**Compliance Criteria**:
- ✅ COMPLIANT: Automatic key rotation enabled
- ❌ NON_COMPLIANT: Key rotation disabled

**Remediation**:
1. Enable key rotation in KMS console or Terraform
2. Verify `enable_key_rotation = true` in Terraform

## Compliance Monitoring

### Real-Time Alerts

**EventBridge Rule**: Captures compliance changes
```json
{
  "source": ["aws.config"],
  "detail-type": ["Config Rules Compliance Change"],
  "detail": {
    "newEvaluationResult": {
      "complianceType": ["NON_COMPLIANT"]
    }
  }
}
```

**SNS Notification Format**:
```json
{
  "configRuleName": "simple-log-service-dynamodb-encryption",
  "resourceType": "AWS::DynamoDB::Table",
  "resourceId": "simple-log-service-entries",
  "complianceType": "NON_COMPLIANT",
  "annotation": "Resource is not compliant with rule"
}
```

### Compliance Dashboard

Access AWS Config dashboard to view:
- Overall compliance score
- Non-compliant resources
- Compliance timeline
- Configuration history

**Console Path**: AWS Config → Dashboard → Compliance

## Compliance Reporting

### Daily Compliance Report
1. Navigate to AWS Config console
2. Select "Compliance" from left menu
3. Export compliance report (CSV/JSON)
4. Review non-compliant resources

### Automated Reporting
- EventBridge can trigger Lambda for custom reports
- S3 bucket stores configuration snapshots
- Athena can query Config data for analytics

## Remediation Procedures

### Automated Remediation (Optional)
AWS Config supports automated remediation using Systems Manager Automation documents. Not implemented by default to prevent unintended changes.

### Manual Remediation Process
1. **Receive Alert**: SNS email notification
2. **Investigate**: Review AWS Config dashboard
3. **Identify Root Cause**: Check configuration changes
4. **Remediate**: Update Terraform configuration
5. **Deploy**: Run `terraform apply`
6. **Verify**: Confirm compliance in AWS Config

## Compliance Best Practices

### 1. Regular Reviews
- Weekly review of compliance dashboard
- Monthly audit of all resources
- Quarterly security assessment

### 2. Change Management
- All infrastructure changes via Terraform
- Peer review for Terraform changes
- Test in non-production first

### 3. Documentation
- Document all compliance exceptions
- Maintain runbooks for remediation
- Update procedures as rules evolve

### 4. Training
- Train team on compliance requirements
- Regular security awareness sessions
- Share compliance reports with stakeholders

## Compliance Exceptions

### Requesting Exceptions
1. Document business justification
2. Identify compensating controls
3. Get approval from security team
4. Set expiration date for exception
5. Review exceptions quarterly

### Exception Tracking
- Maintain exception register
- Document approval and expiration
- Set reminders for review dates

## Integration with Other Services

### AWS Security Hub
- Config findings can be sent to Security Hub
- Centralized security posture management
- Cross-account compliance visibility

### AWS CloudTrail
- Config uses CloudTrail for API activity
- Audit trail for configuration changes
- Compliance evidence for audits

### AWS Organizations
- Config can aggregate across accounts
- Organization-wide compliance policies
- Centralized compliance reporting

## Compliance Metrics

### Key Performance Indicators (KPIs)
- **Compliance Score**: Percentage of compliant resources
- **Mean Time to Remediate (MTTR)**: Average time to fix violations
- **Violation Frequency**: Number of violations per month
- **Remediation Rate**: Percentage of violations fixed within SLA

### Target Metrics
- Compliance Score: ≥ 95%
- MTTR: ≤ 24 hours
- Violation Frequency: ≤ 5 per month
- Remediation Rate: 100% within 48 hours

## Audit Support

### Compliance Evidence
- AWS Config provides configuration snapshots
- CloudTrail provides API activity logs
- S3 bucket stores historical data
- Retention: 7 years (configurable)

### Audit Preparation
1. Export compliance reports
2. Generate configuration timeline
3. Document remediation actions
4. Prepare evidence package
5. Schedule audit review meeting

