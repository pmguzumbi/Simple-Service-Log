#!/usr/bin/env python3
"""
Load testing script for Simple Log Service using Locust.
Tests both ingest and read recent endpoints with AWS SigV4 authentication.
"""

import json
import random
from datetime import datetime
from locust import HttpUser, task, between
import boto3
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest


class LogServiceUser(HttpUser):
    """
    Simulates user behavior for load testing the Simple Log Service.
    """
    wait_time = between(1, 3)  # Wait 1-3 seconds between tasks
    
    def on_start(self):
        """Initialize AWS credentials and function URLs."""
        self.session = boto3.Session()
        self.credentials = self.session.get_credentials()
        self.region = self.session.region_name or 'us-east-1'
        
        # Get function URLs from environment or Terraform outputs
        import os
        self.ingest_url = os.environ.get('INGEST_URL', '')
        self.read_url = os.environ.get('READ_URL', '')
        
        if not self.ingest_url or not self.read_url:
            print("ERROR: Set INGEST_URL and READ_URL environment variables")
            raise ValueError("Missing function URLs")
    
    def sign_request(self, method: str, url: str, body: str = None) -> dict:
        """Sign HTTP request using AWS SigV4."""
        request = AWSRequest(method=method, url=url, data=body)
        SigV4Auth(self.credentials, 'lambda', self.region).add_auth(request)
        return dict(request.headers)
    
    @task(3)
    def ingest_log(self):
        """
        Task: Ingest a log entry (weighted 3x).
        Simulates writing log entries with random severity levels.
        """
        severities = ['info', 'warning', 'error']
        messages = [
            'Application started successfully',
            'High memory usage detected',
            'Database connection failed',
            'User authentication successful',
            'API rate limit exceeded',
            'Cache miss for key',
            'Background job completed',
            'Configuration reloaded'
        ]
        
        payload = {
            'severity': random.choice(severities),
            'message': f"{random.choice(messages)} - {datetime.utcnow().isoformat()}"
        }
        
        body = json.dumps(payload)
        headers = self.sign_request('POST', self.ingest_url, body)
        headers['Content-Type'] = 'application/json'
        
        with self.client.post(
            self.ingest_url,
            data=body,
            headers=headers,
            catch_response=True,
            name="Ingest Log"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Status: {response.status_code}")
    
    @task(1)
    def read_recent_logs(self):
        """
        Task: Read recent logs (weighted 1x).
        Simulates reading the 100 most recent log entries.
        """
        headers = self.sign_request('GET', self.read_url)
        
        with self.client.get(
            self.read_url,
            headers=headers,
            catch_response=True,
            name="Read Recent Logs"
        ) as response:
            if response.status_code == 200:
                try:
                    data = response.json()
                    if 'logs' in data:
                        response.success()
                    else:
                        response.failure("Invalid response format")
                except json.JSONDecodeError:
                    response.failure("Invalid JSON response")
            else:
                response.failure(f"Status: {response.status_code}")


# Run with: locust -f scripts/load_test.py --host=https://your-function-url
# Or: locust -f scripts/load_test.py --headless --users 100 --spawn-rate 10 --run-time 5m

