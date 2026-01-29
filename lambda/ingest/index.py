import json
import os
import uuid
import re
from datetime import datetime, timezone
from typing import Dict, Any
import boto3
from botocore.exceptions import ClientError

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ['TABLE_NAME']
table = dynamodb.Table(table_name)

# Valid severity levels
VALID_SEVERITIES = {'info', 'warning', 'error'}

# Maximum message length (10KB)
MAX_MESSAGE_LENGTH = 10240

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for ingesting log entries.
    
    Expected input format:
    {
        "severity": "info|warning|error",
        "message": "Log message text"
    }
    
    Returns:
    {
        "statusCode": 200|400|500,
        "body": JSON string with result or error
    }
    """
    try:
        # Parse request body
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', event)
        
        # Validate required fields
        if 'severity' not in body:
            return create_response(400, {'error': 'Missing required field: severity'})
        
        if 'message' not in body:
            return create_response(400, {'error': 'Missing required field: message'})
        
        severity = body['severity'].lower()
        message = body['message']
        
        # Validate severity
        if severity not in VALID_SEVERITIES:
            return create_response(
                400,
                {'error': f'Invalid severity. Must be one of: {", ".join(VALID_SEVERITIES)}'}
            )
        
        # Validate message length
        if len(message) > MAX_MESSAGE_LENGTH:
            return create_response(
                400, 
                {'error': f'Message exceeds maximum length of {MAX_MESSAGE_LENGTH} characters'}
            )
        
        # Enhanced input validation - prevent injection attacks
        if not validate_message(message):
            return create_response(
                400,
                {'error': 'Message contains invalid or potentially harmful characters'}
            )
        
        # Generate log entry
        log_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()
        
        log_entry = {
            'id': log_id,
            'datetime': timestamp,
            'severity': severity,
            'message': message
        }
        
        # Store in DynamoDB with retry logic
        try:
            table.put_item(Item=log_entry)
        except ClientError as e:
            if e.response['Error']['Code'] == 'ProvisionedThroughputExceededException':
                # Implement exponential backoff for throughput errors
                import time
                time.sleep(0.1)
                table.put_item(Item=log_entry)
            else:
                raise
        
        # Return success response
        return create_response(
            200,
            {
                'message': 'Log entry created successfully',
                'log_entry': log_entry
            }
        )
        
    except json.JSONDecodeError as e:
        return create_response(400, {'error': f'Invalid JSON: {str(e)}'})
    
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        
        # Handle specific DynamoDB errors
        if error_code == 'ProvisionedThroughputExceededException':
            print(f"Throughput exceeded: {error_message}")
            return create_response(429, {'error': 'Rate limit exceeded, please retry'})
        elif error_code == 'ResourceNotFoundException':
            print(f"Table not found: {error_message}")
            return create_response(500, {'error': 'Database table not found'})
        else:
            print(f"DynamoDB error: {error_code} - {error_message}")
            return create_response(500, {'error': 'Failed to store log entry'})
    
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        return create_response(500, {'error': 'Internal server error'})


def validate_message(message: str) -> bool:
    """
    Validate message content to prevent injection attacks.
    
    Args:
        message: The log message to validate
        
    Returns:
        True if message is valid, False otherwise
    """
    # Check for potentially harmful characters
    # Allow alphanumeric, spaces, and common punctuation
    if re.search(r'[<>{}\\]', message):
        return False
    
    # Check for null bytes
    if '\x00' in message:
        return False
    
    return True


def create_response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """Create a standardized API response."""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'POST,OPTIONS'
        },
        'body': json.dumps(body)
    }
