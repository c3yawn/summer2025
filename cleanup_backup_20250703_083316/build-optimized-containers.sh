#!/bin/bash

# Optimized Container Build and Push Script

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Container images
LANGUAGES=("java" "javascript" "python" "cpp")

echo "🚀 Building optimized containers..."
echo "Account ID: $AWS_ACCOUNT_ID"
echo "ECR Registry: $ECR_REGISTRY"

# Login to ECR
echo "🔑 Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Build and push optimized images
for lang in "${LANGUAGES[@]}"; do
    echo ""
    echo "🔨 Building optimized ${lang}-compiler-runner..."
    
    # Copy compiler script to build context
    cp compiler.py docker-containers/${lang}-compiler-runner/
    
    # Build with optimizations
    cd docker-containers/${lang}-compiler-runner/
    
    # Build with BuildKit for better caching and multi-stage builds
    DOCKER_BUILDKIT=1 docker build \
        -f Dockerfile.ecs \
        -t ${lang}-compiler-runner:optimized \
        --target runtime \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        .
    
    # Tag for ECR
    docker tag ${lang}-compiler-runner:optimized ${ECR_REGISTRY}/${lang}-compiler-runner:latest
    docker tag ${lang}-compiler-runner:optimized ${ECR_REGISTRY}/${lang}-compiler-runner:optimized
    
    # Push both latest and optimized tags
    echo "📤 Pushing ${lang}-compiler-runner..."
    docker push ${ECR_REGISTRY}/${lang}-compiler-runner:latest
    docker push ${ECR_REGISTRY}/${lang}-compiler-runner:optimized
    
    # Show image size
    echo "📊 Image size for ${lang}:"
    docker images ${lang}-compiler-runner:optimized --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
    
    echo "✅ ${lang}-compiler-runner optimized and pushed"
    
    # Clean up
    rm compiler.py
    cd ../..
done

echo ""
echo "🎉 All optimized containers built and pushed!"
