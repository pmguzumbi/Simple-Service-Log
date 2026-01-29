# Troubleshooting Guide

## Common Issues and Solutions

### Deployment Issues

#### Issue: Terraform Init Fails
**Symptoms**:
```
Error: Failed to query available provider packages
```

**Causes**:
- No internet connection
- Terraform version too old
- Provider registry unreachable

**Solutions**:
1. Check internet connectivity
2. Update Terraform: `terraform version` (require >= 1.5.0)
3. Try alternative provider mirror:
```bash
terraform init -plugin-dir=/path/to/plugins
```

---

#### Issue: Terraform Apply Fails - KMS Key Policy
**Symptoms**:
```
Error: Error creating KMS key: AccessDeniedException
```

**Causes**:
- Insufficient IAM permissions
- Missing kms:CreateKey permission

**Solutions**:
1. Verify IAM permissions:
```bash
aws iam get-user-policy --user-name your-user --policy-name your-policy
```

2. Add required permissions:
```json
{
  "Effect": "Allow",
  "Action": [
    "kms:CreateKey",
    "kms:CreateAlias",
    "kms:EnableKeyRotation"
  ],
  "Resource": "*"
}
```

---

#### Issue: Lambda Deployment Package Too Large
**Symptoms**:
```
Error: InvalidParameterValueException: Unzipped size must be smaller than 262144000 bytes
```

**Causes**:
- Lambda package exceeds 250MB unzipped
- Unnecessary files included in package

**Solutions**:
1. Check package size:
```bash
unzip -l terraform/ingest_lambda.zip | tail -1
```

2. Exclude unnecessary files in `data.archive_file`:
```hcl
excludes = ["tests", "__pycache__", "*.pyc", "*.md"]
```

3. Use Lambda layers for large dependencies

---

### Runtime Issues

#### Issue: 403 Forbidden When Invoking Lambda
**Symptoms**:
```json
{
  "Message": "User is not authorized to perform: lambda:InvokeFunctionUrl"
}
```

**Causes**:
- Missing IAM permissions
- Incorrect AWS credentials
- Function URL not configured for IAM auth

**Solutions**:
1. Verify IAM policy allows `lambda:InvokeFunctionUrl`:
```json
{
  "Effect": "Allow",
  "Action": "lambda:InvokeFunctionUrl",
  "Resource": "arn:aws:lambda:us-east-1:123456789012:function:simple-log-service-*"
}
```

2. Check AWS credentials:
```bash
aws sts get-caller-identity
```

3. Verify function URL authorization type:
```bash
aws lambda get-function-url-config --function-name simple-log-service-ingest
```

---

#### Issue: DynamoDB AccessDeniedException
**Symptoms**:
```
botocore.exceptions.ClientError: An error occurred (AccessDeniedException) when calling the PutItem operation
```

**Causes**:
- Lambda role missing DynamoDB permissions
- KMS key policy doesn't allow Lambda role

**Solutions**:
1. Verify Lambda role has DynamoDB permissions:
```bash
aws iam get-role-policy \
  --role-name simple-log-service-ingest-lambda-role \
  --policy-name simple-log-service-ingest-lambda-policy
```

2. Check KMS key policy allows Lambda role:
```bash
aws kms get-key-policy --key-id alias/simple-log-service --policy-name default
```

3. Update KMS key policy if needed:
```json
{
  "Sid": "Allow Lambda to use the key",
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::123456789012:role/simple-log-service-ingest-lambda-role"
  },
  "Action": [
    "kms:Decrypt",
    "kms:GenerateDataKey"
  ],
  "Resource": "*"
}
```

---

#### Issue: Lambda Timeout
**Symptoms**:
```
Task timed out after 30.00 seconds
```

**Causes**:
- DynamoDB throttling
- Large scan operation
- Network latency

**Solutions**:
1. Increase Lambda timeout in Terraform:
```hcl
resource "aws_lambda_function" "read_recent" {
  timeout = 60  # Increase from 30 to 60 seconds
}
```

2. Check DynamoDB metrics for throttling:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name UserErrors \
  --dimensions Name=TableName,Value=simple-log-service-entries \
  --start-time 2026-01-29T00:00:00Z \
  --end-time 2026-01-29T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

3. Optimize read_recent Lambda to use Query instead of Scan

---

#### Issue: CloudWatch Logs Not Appearing
**Symptoms**:
- Lambda executes successfully
- No logs in CloudWatch

**Causes**:
- Lambda role missing CloudWatch Logs permissions
- Log group doesn't exist
- KMS key policy doesn't allow CloudWatch

**Solutions**:
1. Verify log group exists:
```bash
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/simple-log-service
```

2. Check Lambda role permissions:
```json
{
  "Effect": "Allow",
  "Action": [
    "logs:CreateLogStream",
    "logs:PutLogEvents"
  ],
  "Resource": "arn:aws:logs:us-east-1:123456789012:log-group:/aws/lambda/simple-log-service-*:*"
}
```

3. Verify KMS key policy allows CloudWatch Logs:
```json
{
  "Sid": "Allow CloudWatch Logs",
  "Effect": "Allow",
  "Principal": {
    "Service": "logs.amazonaws.com"
  },
  "Action": [
    "kms:Encrypt",
    "kms:Decrypt",
    "kms:GenerateDataKey"
  ],
  "Resource": "*"
}
```

---

### Compliance Issues

#### Issue: AWS Config Not Recording
**Symptoms**:
- Config dashboard shows no data
- Compliance rules not evaluating

**Causes**:
- Configuration recorder not started
- Insufficient IAM permissions
- S3 bucket policy incorrect

**Solutions**:
1. Check recorder status:
```bash
aws configservice describe-configuration-recorder-status
```

2. Start recorder if stopped:
```bash
aws configservice start-configuration-recorder \
  --configuration-recorder-name simple-log-service-recorder
```

3. Verify S3 bucket policy allows Config:
```bash
aws s3api get-bucket-policy --bucket simple-log-service-config-123456789012
```

---

#### Issue: Compliance Alerts Not Received
**Symptoms**:
- Resources are non-compliant
- No SNS email received

**Causes**:
- SNS subscription not confirmed
- EventBridge rule not enabled
- SNS topic policy incorrect

**Solutions**:
1. Check SNS subscription status:
```bash
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:123456789012:simple-log-service-compliance-alerts
```

2. Confirm subscription via email link

3. Verify EventBridge rule is enabled:
```bash
aws events describe-rule --name simple-log-service-config-compliance-changes
```

4. Test SNS topic:
```bash
aws sns publish \
  --topic-arn arn:aws:sns:us-east-1:123456789012:simple-log-service-compliance-alerts \
  --message "Test message"
```

---

### Performance Issues

#### Issue: Slow Log Retrieval
**Symptoms**:
- Read Recent Lambda takes > 10 seconds
- Timeout warnings in CloudWatch

**Causes**:
- Large number of log entries (> 100,000)
- Scan operation inefficient
- DynamoDB throttling

**Solutions**:
1. Optimize to use Query with GSI:
```python
response = table.query(
    IndexName='datetime-index',
    KeyConditionExpression=Key('datetime').gte('2026-01-01'),
    ScanIndexForward=False,
    Limit=100
)
```

2. Implement pagination:
```python
response = table.scan(Limit=1000)
items = response['Items']

while 'LastEvaluatedKey' in response and len(items) < 100:
    response = table.scan(
        ExclusiveStartKey=response['LastEvaluatedKey'],
        Limit=1000
    )
    items.extend(response['Items'])
```

3. Consider DynamoDB Streams for real-time processing

---

#### Issue: High DynamoDB Costs
**Symptoms**:
- Unexpected AWS bill
- High read/write capacity units

**Causes**:
- Inefficient scan operations
- Excessive API calls
- No caching implemented

**Solutions**:
1. Review DynamoDB metrics:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=simple-log-service-entries \
  --start-time 2026-01-29T00:00:00Z \
  --end-time 2026-01-29T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

2. Implement caching with ElastiCache or Lambda caching

3. Use Query instead of Scan where possible

4. Consider DynamoDB DAX for read-heavy workloads

---

## Debugging Tools

### CloudWatch Logs Insights Queries

**Find all errors**:
```
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
```

**Lambda execution duration**:
```
fields @timestamp, @duration
| stats avg(@duration), max(@duration), min(@duration)
```

**DynamoDB errors**:
```
fields @timestamp, @message
| filter @message like /DynamoDB/
| filter @message like /Error/
| sort @timestamp desc
```

### AWS CLI Commands

**Check Lambda function configuration**:
```bash
aws lambda get-function --function-name simple-log-service-ingest
```

**List recent Lambda invocations**:
```bash
aws lambda list-function-event-invoke-configs \
  --function-name simple-log-service-ingest
```

**Get DynamoDB table details**:
```bash
aws dynamodb describe-table --table-name simple-log-service-entries
```

**Check KMS key status**:
```bash
aws kms describe-key --key-id alias/simple-log-service
```

### Testing Commands

**Test ingest with invalid severity**:
```bash
python scripts/invoke_with_sigv4.py ingest \
  --severity critical \
  --message "This should fail"
```

**Test with oversized message**:
```bash
python scripts/invoke_with_sigv4.py ingest \
  --severity info \
  --message "$(python -c 'print("x" * 10241)')"
```

**Load test (requires Apache Bench)**:
```bash
ab -n 1000 -c 10 -p payload.json -T application/json \
  https://your-function-url
```

## Getting Help

### AWS Support
- Open support case in AWS Console
- Include CloudWatch Logs
- Provide Terraform configuration
- Share error messages

### Community Resources
- AWS Forums: https://forums.aws.amazon.com
- Stack Overflow: Tag with `aws-lambda`, `dynamodb`, `terraform`
- AWS re:Post: https://repost.aws

### Internal Resources
- Check internal documentation
- Contact DevOps team
- Review security policies
- Consult architecture team
