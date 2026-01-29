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


class TestReadRecentLambda(unittest.TestCase):

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
    def test_successful_read_recent(self, mock_table):
        """Test successful retrieval of recent logs."""
        mock_items = [
            {
                'id': 'test-id-1',
                'datetime': '2026-01-29T10:00:00.000Z',
                'severity': 'info',
                'message': 'Test message 1'
            },
            {
                'id': 'test-id-2',
                'datetime': '2026-01-29T09:00:00.000Z',
                'severity': 'warning',
                'message': 'Test message 2'
            }
        ]
        mock_table.scan.return_value = {'Items': mock_items}

        response = lambda_handler({}, None)
        self.assertEqual(response['statusCode'], 200)
        body = json.loads(response['body'])
        self.assertEqual(body['count'], 2)
        self.assertEqual(len(body['logs']), 2)
        # Verify sorted by datetime descending
        self.assertEqual(body['logs'][0]['datetime'], '2026-01-29T10:00:00.000Z')
        self.assertEqual(body['logs'][1]['datetime'], '2026-01-29T09:00:00.000Z')

    @patch('index.table', new_callable=lambda: boto3.resource('dynamodb', region_name='us-east-1').Table(os.environ['TABLE_NAME']))
    def test_empty_table(self, mock_table):
        """Test retrieval when table is empty."""
        mock_table.scan.return_value = {'Items': []}
        response = lambda_handler({}, None)
        self.assertEqual(response['statusCode'], 200)
        body = json.loads(response['body'])
        self.assertEqual(body['count'], 0)
        self.assertEqual(len(body['logs']), 0)

    @patch('index.table', new_callable=lambda: boto3.resource('dynamodb', region_name='us-east-1').Table(os.environ['TABLE_NAME']))
    def test_pagination(self, mock_table):
        """Test handling of paginated results."""
        mock_items_page1 = [
            {
                'id': f'test-id-{i}',
                'datetime': f'2026-01-29T{10+i:02d}:00:00.000Z',
                'severity': 'info',
                'message': f'Test message {i}'
            }
            for i in range(50)
        ]
        mock_items_page2 = [
            {
                'id': f'test-id-{i}',
                'datetime': f'2026-01-29T{i:02d}:00:00.000Z',
                'severity': 'info',
                'message': f'Test message {i}'
            }
            for i in range(50, 100)
        ]
        mock_table.scan.side_effect = [
            {'Items': mock_items_page1, 'LastEvaluatedKey': {'id': 'test-id-49'}},
            {'Items': mock_items_page2}
        ]

        response = lambda_handler({}, None)
        self.assertEqual(response['statusCode'], 200)
        body = json.loads(response['body'])
        self.assertEqual(body['count'], 100)

    @patch('index.table', new_callable=lambda: boto3.resource('dynamodb', region_name='us-east-1').Table(os.environ['TABLE_NAME']))
    def test_limit_to_100(self, mock_table):
        """Test that only 100 most recent logs are returned."""
        mock_items = [
            {
                'id': f'test-id-{i}',
                'datetime': f'2026-01-29T{i:02d}:00:00.000Z',
                'severity': 'info',
                'message': f'Test message {i}'
            }
            for i in range(150)
        ]
        mock_table.scan.return_value = {'Items': mock_items}

        response = lambda_handler({}, None)
        self.assertEqual(response['statusCode'], 200)
        body = json.loads(response['body'])
        self.assertEqual(body['count'], 100)


if __name__ == '__main__':
    unittest.main()
