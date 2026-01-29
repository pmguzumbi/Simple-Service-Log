#!/bin/bash
set -e

echo "=========================================="
echo "Simple Log Service Integration Tests"
echo "=========================================="
echo ""

# Get function URLs from Terraform outputs
echo "Retrieving function URLs..."
cd terraform
INGEST_URL=$(terraform output -raw ingest_function_url)
READ_URL=$(terraform output -raw read_recent_function_url)
cd ..

echo "Ingest URL: $INGEST_URL"
echo "Read Recent URL: $READ_URL"
echo ""

# Test 1: Ingest info log
echo "Test 1: Ingesting INFO log..."
python3 scripts/invoke_with_sigv4.py ingest \
  --severity info \
  --message "Test info message from integration test" \
  --url "$INGEST_URL"
echo ""

# Test 2: Ingest warning log
echo "Test 2: Ingesting WARNING log..."
python3 scripts/invoke_with_sigv4.py ingest \
  --severity warning \
  --message "Test warning message from integration test" \
  --url "$INGEST_URL"
echo ""

# Test 3: Ingest error log
echo "Test 3: Ingesting ERROR log..."
python3 scripts/invoke_with_sigv4.py ingest \
  --severity error \
  --message "Test error message from integration test" \
  --url "$INGEST_URL"
echo ""

# Wait for eventual consistency
echo "Waiting for DynamoDB eventual consistency..."
sleep 2
echo ""

# Test 4: Read recent logs
echo "Test 4: Reading recent logs..."
python3 scripts/invoke_with_sigv4.py read-recent --url "$READ_URL"
echo ""

echo "=========================================="
echo "All tests completed successfully!"
echo "=========================================="

