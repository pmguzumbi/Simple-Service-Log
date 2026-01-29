import json
import os
import unittest
from unittest.mock import patch, MagicMock
from datetime import datetime

# Mock environment variables
os.environ['TABLE_NAME'] = 'test-log-entries'

# Import after setting env vars
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from index import lambda_handler

class TestIngestLambda(unittest.TestCase):
    
    @patch('index.table')
    def test_successful_log_ingest(self, mock_table):
        """Test successful log entry creation."""
        mock_table.put_item.return_value = {}
        
        event = {
            'body': json.dumps({
                'severity': 'info',
                'message': 'Test log message'
            })
        }
        
        response = lambda_handler(event, None)
        
        self.assertEqual(response['statusCode'], 200)
        body = json.loads(response['body'])
        self.assertEqual(body['message'], 'Log entry created successfully')
        self.assertIn('log_entry', body)
        self.assertEqual(body['log_entry']['severity'], 'info')
        self.assertEqual(body['log_entry']['message'], 'Test log message')
        mock_table.put_item.assert_called_once()
    
    @patch('index.table')
    def test_missing_severity(self, mock_table):
        """Test error when severity is missing."""
        event = {
            'body': json.dumps({
                'message': 'Test log message'
            })
        }
        
        response = lambda_handler(event, None)
        
        self.assertEqual(response['statusCode'], 400)
        body = json.loads(response['body'])
        self.assertIn('error', body)
        self.assertIn('severity', body['error'])
    
    @patch('index.table')
    def test_missing_message(self, mock_table):
        """Test error when message is missing."""
        event = {
            'body': json.dumps({
                'severity': 'info'
            })
        }
        
        response = lambda_handler(event, None)
        
        self.assertEqual(response['statusCode'], 400)
        body = json.loads(response['body'])
        self.assertIn('error', body)
        self.assertIn('message', body['error'])
    
    @patch('index.table')
    def test_invalid_severity(self, mock_table):
        """Test error when severity is invalid."""
        event = {
            'body': json.dumps({
                'severity': 'critical',
                'message': 'Test log message'
            })
        }
        
        response = lambda_handler(event, None)
        
        self.assertEqual(response['statusCode'], 400)
        body = json.loads(response['body'])
        self.assertIn('error', body)
        self.assertIn('Invalid severity', body['error'])
    
    @patch('index.table')
    def test_message_too_long(self, mock_table):
        """Test error when message exceeds maximum length."""
        event = {
            'body': json.dumps({
                'severity': 'info',
                'message': 'x' * 10241  # Exceeds 10KB limit
            })
        }
        
        response = lambda_handler(event, None)
        
        self.assertEqual(response['statusCode'], 400)
        body = json.loads(response['body'])
        self.assertIn('error', body)
        self.assertIn('exceeds maximum length', body['error'])
    
    @patch('index.table')
    def test_invalid_json(self, mock_table):
        """Test error when request body is invalid JSON."""
        event = {
            'body': 'invalid json'
        }
        
        response = lambda_handler(event, None)
        
        self.assertEqual(response['statusCode'], 400)
        body = json.loads(response['body'])
        self.assertIn('error', body)
        self.assertIn('Invalid JSON', body['error'])

if __name__ == '__main__':
    unittest.main()

