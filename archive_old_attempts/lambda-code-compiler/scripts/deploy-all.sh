#!/bin/bash

echo "🚀 Complete Lambda Code Compiler Deployment"
echo "==========================================="

# Check prerequisites
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install it first."
    exit 1
fi

if ! command -v sam &> /dev/null; then
    echo "❌ SAM CLI not found. Please install it first."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install it first."
    exit 1
fi

# Verify AWS credentials
echo "🔍 Checking AWS credentials..."
aws sts get-caller-identity >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ AWS credentials not configured. Run 'aws configure' first."
    exit 1
fi

echo "✅ Prerequisites check passed!"
echo ""

# Step 1: Build and push containers
echo "📦 Step 1: Building and pushing Lambda containers..."
./scripts/build-containers.sh

if [ $? -ne 0 ]; then
    echo "❌ Container build failed!"
    exit 1
fi

echo ""

# Step 2: Deploy SAM stack
echo "📋 Step 2: Deploying SAM infrastructure..."
./scripts/deploy-sam.sh

if [ $? -ne 0 ]; then
    echo "❌ SAM deployment failed!"
    exit 1
fi

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "🧪 Next steps:"
echo "1. Test the API endpoints (see output above)"
echo "2. Update your frontend to use the new API Gateway URL"
echo "3. Update your Spring Boot backend to call Lambda functions"