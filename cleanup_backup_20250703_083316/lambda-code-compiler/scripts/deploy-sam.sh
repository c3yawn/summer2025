#!/bin/bash

echo "📋 Deploying SAM stack..."

cd infrastructure/

# Build SAM application
echo "🔨 Building SAM application..."
sam build

# Deploy with guided setup (first time)
if [ ! -f samconfig.toml ]; then
    echo "🚀 First time deployment - running guided setup..."
    sam deploy --guided
else
    echo "🚀 Deploying with existing configuration..."
    sam deploy
fi

# Get API Gateway URL
echo "📡 Getting deployment information..."
API_URL=$(aws cloudformation describe-stacks --stack-name lambda-code-compiler --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayEndpoint`].OutputValue' --output text 2>/dev/null)

if [ ! -z "$API_URL" ]; then
    echo "✅ Deployment successful!"
    echo "🌐 API Gateway URL: ${API_URL}"
    echo ""
    echo "🧪 Test your deployment:"
    echo "curl ${API_URL}/health"
else
    echo "⚠️ Could not retrieve API Gateway URL. Check CloudFormation console."
fi

cd ..