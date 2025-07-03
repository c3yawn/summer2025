#!/bin/bash

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

LANGUAGES=("java" "python" "javascript" "cpp")

echo "🚀 Building Lambda container images..."
echo "Account ID: $AWS_ACCOUNT_ID"
echo "ECR Registry: $ECR_REGISTRY"

# Login to ECR
echo "🔑 Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

for lang in "${LANGUAGES[@]}"; do
    echo "🔨 Building ${lang}-compiler-lambda..."
    
    # Create ECR repository if it doesn't exist
    aws ecr create-repository --repository-name ${lang}-compiler-lambda --region ${AWS_REGION} 2>/dev/null || echo "Repository exists"
    
    # Build container
    cd functions/${lang}-compiler/
    docker build -t ${lang}-compiler-lambda:latest .
    
    # Tag for ECR
    docker tag ${lang}-compiler-lambda:latest ${ECR_REGISTRY}/${lang}-compiler-lambda:latest
    
    # Push to ECR
    docker push ${ECR_REGISTRY}/${lang}-compiler-lambda:latest
    
    echo "✅ ${lang}-compiler-lambda pushed to ECR"
    cd ../..
done

echo "🎉 All Lambda containers built and pushed!"