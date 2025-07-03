#!/bin/bash

# Configuration
AWS_REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Deploying Lambda functions for Code Compiler..."
echo "Account ID: $ACCOUNT_ID"

# Create IAM role for Lambda execution
echo "Creating IAM role for Lambda..."
cat > lambda-trust-policy.json << INNER_EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
INNER_EOF

# Create Lambda execution role
aws iam create-role \
    --role-name CodeCompilerLambdaRole \
    --assume-role-policy-document file://lambda-trust-policy.json 2>/dev/null || echo "Role already exists"

# Attach basic Lambda execution policy
aws iam attach-role-policy \
    --role-name CodeCompilerLambdaRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Wait for role to be available
sleep 10

# Array of languages and their Lambda function names
declare -a languages=("java" "python" "javascript" "cpp")

# Deploy each Lambda function
for lang in "${languages[@]}"; do
    echo "Deploying $lang Lambda function..."
    
    # Create deployment package
    mkdir -p lambda-${lang}
    cp lambda-${lang}-executor.py lambda-${lang}/lambda_function.py
    
    # Create ZIP package
    cd lambda-${lang}
    zip -r ../lambda-${lang}.zip .
    cd ..
    
    # Create/Update Lambda function
    aws lambda create-function \
        --function-name "code-compiler-${lang}" \
        --runtime python3.9 \
        --role arn:aws:iam::${ACCOUNT_ID}:role/CodeCompilerLambdaRole \
        --handler lambda_function.lambda_handler \
        --timeout 60 \
        --memory-size 256 \
        --zip-file fileb://lambda-${lang}.zip \
        --region ${AWS_REGION} 2>/dev/null || \
    aws lambda update-function-code \
        --function-name "code-compiler-${lang}" \
        --zip-file fileb://lambda-${lang}.zip \
        --region ${AWS_REGION}
    
    echo "✅ Deployed code-compiler-${lang}"
    
    # Clean up
    rm -rf lambda-${lang} lambda-${lang}.zip
done

# Clean up temporary files
rm -f lambda-trust-policy.json

echo ""
echo "🎉 All Lambda functions deployed successfully!"
echo ""
echo "Lambda Function ARNs:"
for lang in "${languages[@]}"; do
    ARN=$(aws lambda get-function --function-name "code-compiler-${lang}" --region ${AWS_REGION} --query 'Configuration.FunctionArn' --output text)
    echo "  code-compiler-${lang}: ${ARN}"
done

echo ""
echo "Next step: Update your Spring Boot application to use these Lambda functions instead of Docker."
