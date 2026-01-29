#!/bin/bash
set -e

echo "=========================================="
echo "Simple Log Service Setup"
echo "=========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform is not installed"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed"
    exit 1
fi

echo "✓ All prerequisites met"
echo ""

# Check AWS credentials
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✓ AWS Account: $ACCOUNT_ID"
echo ""

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install -r scripts/requirements.txt
echo "✓ Python dependencies installed"
echo ""

# Initialize Terraform
echo "Initializing Terraform..."
cd terraform
terraform init
echo "✓ Terraform initialized"
echo ""

# Create terraform.tfvars if it doesn't exist
if [ ! -f terraform.tfvars ]; then
    echo "Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "⚠ Please edit terraform/terraform.tfvars with your configuration"
    echo ""
fi

echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Edit terraform/terraform.tfvars with your configuration"
echo "2. Run: cd terraform && terraform plan"
echo "3. Run: terraform apply"
echo "4. Run: cd .. && ./scripts/test_service.sh"

