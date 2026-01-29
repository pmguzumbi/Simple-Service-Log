import json
import os
import uuid
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
        
        # Validate message length (DynamoDB item size limit is 400KB, keeping message under 10KB)
        if len(message) > 10240:
            return create_response(400, {'error': 'Message exceeds maximum length of 10KB'})
        
        # Generate log entry
        log_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()
        
        log_entry = {
            'id': log_id,
            'datetime': timestamp,
            'severity': severity,
            'message': message
        }
        
        # Store in DynamoDB
        table.put_item(Item=log_entry)
        
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
        print(f"DynamoDB error: {error_code} - {error_message}")
        return create_response(500, {'error': 'Failed to store log entry'})
    
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        return create_response(500, {'error': 'Internal server error'})


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

