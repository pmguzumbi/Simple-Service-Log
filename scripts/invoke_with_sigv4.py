# Secure Lambda invocation using SigV4
#!/usr/bin/env python3
"""
Secure invocation script for Simple Log Service Lambda functions using AWS SigV4.
This script uses temporary IAM credentials to authenticate requests.
"""

import argparse
import json
import sys
from datetime import datetime
import boto3
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
import requests

def get_function_url(function_name: str) -> str:
    """Retrieve Lambda function URL from AWS."""
    lambda_client = boto3.client('lambda')
    try:
        response = lambda_client.get_function_url_config(FunctionName=function_name)
        return response['FunctionUrl']
    except Exception as e:
        print(f"Error retrieving function URL: {e}")
        sys.exit(1)

def sign_request(method: str, url: str, body: str = None) -> dict:
    """Sign HTTP request using AWS SigV4."""
    session = boto3.Session()
    credentials = session.get_credentials()
    region = session.region_name or 'us-east-1'
    
    request = AWSRequest(method=method, url=url, data=body)
    SigV4Auth(credentials, 'lambda', region).add_auth(request)
    
    return dict(request.headers)

def ingest_log(severity: str, message: str, function_url: str = None):
    """Ingest a log entry."""
    if not function_url:
        function_url = get_function_url('simple-log-service-ingest')
    
    payload = {
        'severity': severity,
        'message': message
    }
    
    body = json.dumps(payload)
    headers = sign_request('POST', function_url, body)
    headers['Content-Type'] = 'application/json'
    
    try:
        response = requests.post(function_url, headers=headers, data=body)
        response.raise_for_status()
        
        result = response.json()
        print(json.dumps(result, indent=2))
        return result
    except requests.exceptions.RequestException as e:
        print(f"Error ingesting log: {e}")
        if hasattr(e.response, 'text'):
            print(f"Response: {e.response.text}")
        sys.exit(1)

def read_recent_logs(function_url: str = None):
    """Retrieve recent log entries."""
    if not function_url:
        function_url = get_function_url('simple-log-service-read-recent')
    
    headers = sign_request('GET', function_url)
    
    try:
        response = requests.get(function_url, headers=headers)
        response.raise_for_status()
        
        result = response.json()
        print(json.dumps(result, indent=2))
        return result
    except requests.exceptions.RequestException as e:
        print(f"Error reading logs: {e}")
        if hasattr(e.response, 'text'):
            print(f"Response: {e.response.text}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(
        description='Invoke Simple Log Service Lambda functions with AWS SigV4 authentication'
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # Ingest command
    ingest_parser = subparsers.add_parser('ingest', help='Ingest a log entry')
    ingest_parser.add_argument('--severity', required=True, choices=['info', 'warning', 'error'],
                               help='Log severity level')
    ingest_parser.add_argument('--message', required=True, help='Log message')
    ingest_parser.add_argument('--url', help='Function URL (optional, will be retrieved if not provided)')
    
    # Read recent command
    read_parser = subparsers.add_parser('read-recent', help='Read recent log entries')
    read_parser.add_argument('--url', help='Function URL (optional, will be retrieved if not provided)')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    if args.command == 'ingest':
        ingest_log(args.severity, args.message, args.url)
    elif args.command == 'read-recent':
        read_recent_logs(args.url)

if __name__ == '__main__':
    main()

