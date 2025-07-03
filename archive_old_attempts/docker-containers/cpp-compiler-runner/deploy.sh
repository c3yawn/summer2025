#!/bin/bash

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="123904282156"
ECR_REGISTRY="123904282156.dkr.ecr.us-east-1.amazonaws.com"
IMAGE_NAME="cpp-compiler-runner"

echo "🚀 Building and deploying C++ compiler Docker image..."
echo "Account ID: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION"
echo "ECR Registry: $ECR_REGISTRY"
echo "Image Name: $IMAGE_NAME"

# Step 1: Create ECR repository if it doesn't exist
echo "📦 Creating ECR repository..."
aws ecr create-repository --repository-name $IMAGE_NAME --region $AWS_REGION 2>/dev/null || echo "Repository already exists"

# Step 2: Get ECR login token
echo "🔑 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Step 3: Build the Docker image
echo "🔨 Building Docker image..."
docker build -t $IMAGE_NAME:latest .

# Step 4: Tag the image for ECR
echo "🏷️ Tagging image for ECR..."
docker tag $IMAGE_NAME:latest $ECR_REGISTRY/$IMAGE_NAME:latest

# Step 5: Push to ECR
echo "⬆️ Pushing image to ECR..."
docker push $ECR_REGISTRY/$IMAGE_NAME:latest

echo ""
echo "✅ C++ compiler Docker image deployed successfully!"
echo "📋 Image URI: $ECR_REGISTRY/$IMAGE_NAME:latest"
echo ""
echo "🔧 Next steps:"
echo "1. Update your Spring Boot service to handle C++ requests"
echo "2. Deploy your updated Spring Boot service to ECS"
echo "3. Test C++ compilation through your API"