# API Reference

## Overview

The Simple Log Service provides two REST API endpoints via Lambda Function URLs with AWS IAM authentication.

## Authentication

All API requests must be signed using AWS Signature Version 4 (SigV4).

### Required Headers
- `Authorization`: AWS SigV4 signature
- `X-Amz-Date`: Request timestamp
- `X-Amz-Security-Token`: Session token (if using temporary credentials)
- `Content-Type`: `application/json` (for POST requests)

### Using AWS SDK
```python
import boto3
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest

session = boto3.Session()
credentials = session.get_credentials()
request = AWSRequest(method='POST', url=function_url, data=body)
SigV4Auth(credentials, 'lambda', 'us-east-1').add_auth(request)
```

### Using AWS CLI
```bash
aws lambda invoke-url \
  --function-url https://your-function-url \
  --payload '{"severity":"info","message":"test"}' \
  response.json
```

## Endpoints

### 1. Ingest Log Entry

**Endpoint**: `POST {INGEST_FUNCTION_URL}`

**Description**: Creates a new log entry in the system.

**Request Headers**:
```
Content-Type: application/json
Authorization: AWS4-HMAC-SHA256 Credential=...
X-Amz-Date: 20260129T083000Z
```

**Request Body**:
```json
{
  "severity": "info|warning|error",
  "message": "Log message text (max 10KB)"
}
```

**Request Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| severity | string | Yes | Log severity level: `info`, `warning`, or `error` |
| message | string | Yes | Log message text (max 10,240 characters) |

**Success Response** (200 OK):
```json
{
  "message": "Log entry created successfully",
  "log_entry": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "datetime": "2026-01-29T08:30:00.123456Z",
    "severity": "info",
    "message": "Application started successfully"
  }
}
```

**Error Responses**:

**400 Bad Request** - Missing severity:
```json
{
  "error": "Missing required field: severity"
}
```

**400 Bad Request** - Missing message:
```json
{
  "error": "Missing required field: message"
}
```

**400 Bad Request** - Invalid severity:
```json
{
  "error": "Invalid severity. Must be one of: info, warning, error"
}
```

**400 Bad Request** - Message too long:
```json
{
  "error": "Message exceeds maximum length of 10KB"
}
```

**400 Bad Request** - Invalid JSON:
```json
{
  "error": "Invalid JSON: Expecting value: line 1 column 1 (char 0)"
}
```

**500 Internal Server Error**:
```json
{
  "error": "Failed to store log entry"
}
```

**Example Request**:
```bash
curl -X POST https://your-ingest-url.lambda-url.us-east-1.on.aws/ \
  -H "Content-Type: application/json" \
  -H "Authorization: AWS4-HMAC-SHA256 ..." \
  -d '{
    "severity": "warning",
    "message": "High memory usage detected: 85%"
  }'
```

---

### 2. Read Recent Logs

**Endpoint**: `GET {READ_RECENT_FUNCTION_URL}`

**Description**: Retrieves the 100 most recent log entries, sorted by datetime descending (newest first).

**Request Headers**:
```
Authorization: AWS4-HMAC-SHA256 Credential=...
X-Amz-Date: 20260129T083000Z
```

**Request Parameters**: None

**Success Response** (200 OK):
```json
{
  "count": 100,
  "logs": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "datetime": "2026-01-29T08:30:00.123456Z",
      "severity": "error",
      "message": "Database connection failed"
    },
    {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "datetime": "2026-01-29T08:29:55.987654Z",
      "severity": "warning",
      "message": "High memory usage detected: 85%"
    },
    {
      "id": "770e8400-e29b-41d4-a716-446655440002",
      "datetime": "2026-01-29T08:29:50.456789Z",
      "severity": "info",
      "message": "Application started successfully"
    }
  ]
}
```

**Response Fields**:
| Field | Type | Description |
|-------|------|-------------|
| count | integer | Number of log entries returned (max 100) |
| logs | array | Array of log entry objects |
| logs[].id | string | Unique identifier (UUID v4) |
| logs[].datetime | string | ISO 8601 timestamp with microseconds |
| logs[].severity | string | Log severity: `info`, `warning`, or `error` |
| logs[].message | string | Log message text |

**Error Responses**:

**500 Internal Server Error**:
```json
{
  "error": "Failed to retrieve log entries"
}
```

**Example Request**:
```bash
curl -X GET https://your-read-recent-url.lambda-url.us-east-1.on.aws/ \
  -H "Authorization: AWS4-HMAC-SHA256 ..."
```

---

## Rate Limits

### Lambda Concurrency
- Default: 1,000 concurrent executions per region
- Can be increased via AWS Support ticket
- Throttling returns 429 Too Many Requests

### DynamoDB
- On-demand billing mode: No rate limits
- Automatic scaling based on traffic
- Burst capacity available

## Error Handling

### HTTP Status Codes
| Code | Description |
|------|-------------|
| 200 | Success |
| 400 | Bad Request (validation error) |
| 403 | Forbidden (authentication failed) |
| 429 | Too Many Requests (rate limit exceeded) |
| 500 | Internal Server Error |

### Retry Strategy
- Implement exponential backoff for 5xx errors
- Maximum 3 retry attempts
- Initial delay: 1 second
- Backoff multiplier: 2

### Example Retry Logic
```python
import time

def call_api_with_retry(func, max_retries=3):
    for attempt in range(max_retries):
        try:
            return func()
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            delay = 2 ** attempt
            time.sleep(delay)
```

## CORS Configuration

### Ingest Lambda
- **Allowed Origins**: `*`
- **Allowed Methods**: `POST`, `OPTIONS`
- **Allowed Headers**: `*`
- **Allow Credentials**: `true`
- **Max Age**: 86400 seconds (24 hours)

### Read Recent Lambda
- **Allowed Origins**: `*`
- **Allowed Methods**: `GET`, `OPTIONS`
- **Allowed Headers**: `*`
- **Allow Credentials**: `true`
- **Max Age**: 86400 seconds (24 hours)

## Best Practices

### 1. Use Temporary Credentials
- Use AWS STS to obtain temporary credentials
- Rotate credentials regularly
- Never hardcode credentials

### 2. Implement Retry Logic
- Handle transient failures gracefully
- Use exponential backoff
- Set maximum retry attempts

### 3. Validate Input
- Validate severity values client-side
- Check message length before sending
- Use proper JSON encoding

### 4. Monitor Usage
- Track API call volume
- Monitor error rates
- Set up CloudWatch alarms

### 5. Handle Errors Gracefully
- Parse error responses
- Log errors for debugging
- Provide user-friendly error messages

## SDK Examples

### Python (boto3)
```python
import boto3
import json
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
import requests

def ingest_log(function_url, severity, message):
    session = boto3.Session()
    credentials = session.get_credentials()
    
    payload = {'severity': severity, 'message': message}
    body = json.dumps(payload)
    
    request = AWSRequest(method='POST', url=function_url, data=body)
    SigV4Auth(credentials, 'lambda', 'us-east-1').add_auth(request)
    
    headers = dict(request.headers)
    headers['Content-Type'] = 'application/json'
    
    response = requests.post(function_url, headers=headers, data=body)
    return response.json()
```

### JavaScript (AWS SDK v3)
```javascript
const { SignatureV4 } = require('@aws-sdk/signature-v4');
const { HttpRequest } = require('@aws-sdk/protocol-http');
const { defaultProvider } = require('@aws-sdk/credential-provider-node');
const { Sha256 } = require('@aws-crypto/sha256-js');

async function ingestLog(functionUrl, severity, message) {
  const credentials = await defaultProvider()();
  const payload = JSON.stringify({ severity, message });
  
  const request = new HttpRequest({
    method: 'POST',
    protocol: 'https:',
    hostname: new URL(functionUrl).hostname,
    path: new URL(functionUrl).pathname,
    headers: {
      'Content-Type': 'application/json',
      'host': new URL(functionUrl).hostname
    },
    body: payload
  });
  
  const signer = new SignatureV4({
    credentials,
    region: 'us-east-1',
    service: 'lambda',
    sha256: Sha256
  });
  
  const signedRequest = await signer.sign(request);
  
  const response = await fetch(functionUrl, {
    method: 'POST',
    headers: signedRequest.headers,
    body: payload
  });
  
  return response.json();
}
```

## Testing

### Using Provided Script
```bash
# Ingest log
python scripts/invoke_with_sigv4.py ingest \
  --severity info \
  --message "Test message"

# Read recent logs
python scripts/invoke_with_sigv4.py read-recent
```

### Using curl with AWS CLI
```bash
# Get temporary credentials
eval $(aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/test-role \
  --role-session-name test-session \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text | \
  awk '{print "export AWS_ACCESS_KEY_ID="$1" AWS_SECRET_ACCESS_KEY="$2" AWS_SESSION_TOKEN="$3}')

# Use awscurl for signed requests
awscurl --service lambda \
  -X POST \
  -d '{"severity":"info","message":"test"}' \
  https://your-function-url
```

