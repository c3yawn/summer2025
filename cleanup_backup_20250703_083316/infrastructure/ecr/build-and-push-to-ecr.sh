#!/bin/bash

# Configuration
AWS_REGION="us-east-1"  # Change to your preferred region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Image names
IMAGES=("java-compiler-runner" "js-compiler-runner" "python-compiler-runner" "cpp-compiler-runner")
DOCKERFILE_PATHS=("docker_resources/java_dockerfile" "docker_resources/javascript_dockerfile" "docker_resources/python_dockerfile" "docker_resources/cpp_dockerfile")

echo "Building and pushing Docker images to ECR..."
echo "Registry: ${ECR_REGISTRY}"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Build and push each image
for i in "${!IMAGES[@]}"; do
    IMAGE_NAME="${IMAGES[$i]}"
    DOCKERFILE_PATH="${DOCKERFILE_PATHS[$i]}"
    ECR_REPO_URI="${ECR_REGISTRY}/${IMAGE_NAME}"
    
    echo "Processing ${IMAGE_NAME}..."
    
    # Create ECR repository if it doesn't exist
    echo "Creating ECR repository for ${IMAGE_NAME}..."
    aws ecr create-repository --repository-name ${IMAGE_NAME} --region ${AWS_REGION} 2>/dev/null || echo "Repository ${IMAGE_NAME} already exists"
    
    # Build the Docker image
    echo "Building Docker image ${IMAGE_NAME}..."
    docker build -t ${IMAGE_NAME}:latest ${DOCKERFILE_PATH}
    
    # Tag for ECR
    echo "Tagging image for ECR..."
    docker tag ${IMAGE_NAME}:latest ${ECR_REPO_URI}:latest
    docker tag ${IMAGE_NAME}:latest ${ECR_REPO_URI}:$(date +%Y%m%d-%H%M%S)
    
    # Push to ECR
    echo "Pushing ${IMAGE_NAME} to ECR..."
    docker push ${ECR_REPO_URI}:latest
    docker push ${ECR_REPO_URI}:$(date +%Y%m%d-%H%M%S)
    
    echo "Successfully pushed ${IMAGE_NAME} to ECR"
    echo "Repository URI: ${ECR_REPO_URI}"
    echo "---"
done

echo "All images have been built and pushed to ECR!"
echo ""
echo "ECR Repository URIs:"
for IMAGE_NAME in "${IMAGES[@]}"; do
    echo "${ECR_REGISTRY}/${IMAGE_NAME}:latest"
done
