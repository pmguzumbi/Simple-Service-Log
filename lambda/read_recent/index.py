import json
import os
from typing import Dict, Any, List
from decimal import Decimal
from datetime import datetime, timedelta, timezone
import boto3
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ['TABLE_NAME']
table = dynamodb.Table(table_name)

class DecimalEncoder(json.JSONEncoder):
    """Helper class to convert DynamoDB Decimal types to JSON-serializable types."""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for retrieving the 100 most recent log entries.
    
    Optimized to use Query with GSI instead of Scan for better performance.
    
    Returns:
    {
        "statusCode": 200|500,
        "body": JSON string with log entries or error
    }
    """
    try:
        # Calculate datetime threshold (last 30 days)
        # This ensures we're querying a reasonable time window
        threshold_date = (datetime.now(timezone.utc) - timedelta(days=30)).isoformat()
        
        # Use Query with GSI for efficient retrieval
        # This is much more efficient than Scan for large tables
        response = table.query(
            IndexName='datetime-index',
            KeyConditionExpression=Key('datetime').gte(threshold_date),
            ScanIndexForward=False,  # Sort descending (newest first)
            Limit=100
        )
        
        items = response.get('Items', [])
        
        # If we got fewer than 100 items, try a broader query
        if len(items) < 100 and 'LastEvaluatedKey' not in response:
            # Fall back to scan only if query returned insufficient results
            response = table.scan(Limit=100)
            items = response.get('Items', [])
            
            # Handle pagination for scan
            while 'LastEvaluatedKey' in response and len(items) < 100:
                response = table.scan(
                    ExclusiveStartKey=response['LastEvaluatedKey'],
                    Limit=100
                )
                items.extend(response.get('Items', []))
            
            # Sort by datetime descending
            items = sorted(
                items,
                key=lambda x: x['datetime'],
                reverse=True
            )[:100]
        
        return create_response(
            200,
            {
                'count': len(items),
                'logs': items,
                'query_method': 'gsi_query' if len(items) > 0 else 'scan_fallback'
            }
        )
        
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
            return create_response(500, {'error': 'Failed to retrieve log entries'})
    
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
            'Access-Control-Allow-Methods': 'GET,OPTIONS'
        },
        'body': json.dumps(body, cls=DecimalEncoder)
    }
