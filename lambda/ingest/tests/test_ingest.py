import json
import os
import unittest
from unittest.mock import patch
from moto import mock_dynamodb2
import boto3
import sys

# Ensure index.py can be imported
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from index import lambda_handler

# Mock environment variable for table name
os.environ['TABLE_NAME'] = 'test-log-entries'


class TestIngestLambda(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        # Start moto DynamoDB mock
        cls.mock_dynamodb = mock_dynamodb2()
        cls.mock_dynamodb.start()

        # Create the table in mocked DynamoDB
        dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
        dynamodb.create_table(
            TableName=os.environ['TABLE_NAME'],
            KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST"
        )

    @classmethod
    def tearDownClass(cls):
        # Stop moto mock after all tests
        cls.mock_dynamodb.stop()

    @patch('index.table', new_callable=lambda: boto3.resource('dynamodb', region_name='us-east-1').Table(os.environ['TABLE_NAME']))
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

    @patch('index.table', new_callable=lambda: boto3.resource('dynamodb', region_name='us-east-1').Table(os.environ['TABLE_NAME']))
    def test_missing_severity(self, mock_table):
        """Test error when severity is missing."""
        event = {
            'body': json.dumps({'message': 'Test log message'})
        }
        response = lambda_handler(event, None)
        self.assertEqual(response['statusCode'], 400)
        body = json.loads(response['body'])
        self.assertIn('error', body)
        self.assertIn('severity', body['error'])

    @patch('index.table', new_callable=lambda: boto3.resource('dynamodb', region_name='us-east-1').Table(os.environ['TABLE_NAME']))
    def test_missing_message(self, mock_table):
        """Test error when message is missing."""
        event = {'body': json.dumps({'severity': 'info'})}
        response = lambda_handler(event, None)
        self.assertEqual(response['statusCode'], 400)
        body = json.loads(response['body'])
        self.assertIn('error', body)
        self.assertIn('message', body['error'])

    @patch('index.table', new_callable=lambda: boto3.resource('dynamodb', region_name='us-east-1').Table(os.environ['TABLE_NAME']))
    def test_invalid_severity(self, mock_table):
        """Test error when severity is invalid."""
        event = {'body': json.dumps({'severity': 'critical', 'message': 'Test log message'})}
        response = lambda_handler(event, None)
        self.assertEqual(response['statusCode'], 400)
        body = json.loads(response['body'])
        self.assertIn('error', body)
        self.assertIn('Invalid severity', body['error'])

    @patch('index.table', new_callable=lambda: boto3.resource('dynamodb', region_name='us-east-1').Table(os.environ['TABLE_NAME']))
    def test_message_too_long(self, mock_table):
        """Test error when message exceeds maximum length."""
        event = {'body': json.dumps({'severity': 'info', 'message': 'x' * 10241})}
        response = lambda_handler(event, None)
        self.assertEqual(response['statusCode'], 400)
        body = json.loads(response['body'])
        self.assertIn('error', body)
        self.assertIn('exceeds maximum length', body['error'])

    @patch('index.table', new_callable=lambda: boto3.resource('dynamodb', region_name='us-east-1').Table(os.environ['TABLE_NAME']))
    def test_invalid_json(self, mock_table):
        """Test error when request body is invalid JSON."""
        event = {'body': 'invalid json'}
        response = lambda_handler(event, None)
        self.assertEqual(response['statusCode'], 400)
        body = json.loads(response['body'])
        self.assertIn('error', body)
        self.assertIn('Invalid JSON', body['error'])


if __name__ == '__main__':
    unittest.main()
