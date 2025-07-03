#!/bin/bash

# Configuration
AWS_REGION="us-east-1"  # Change to your preferred region

# Repository names for your code compiler
REPOSITORIES=("java-compiler-runner" "js-compiler-runner" "python-compiler-runner" "cpp-compiler-runner")

echo "Creating ECR repositories for Code Compiler application..."

for REPO in "${REPOSITORIES[@]}"; do
    echo "Creating repository: ${REPO}"
    
    aws ecr create-repository \
        --repository-name ${REPO} \
        --region ${AWS_REGION} \
        --image-scanning-configuration scanOnPush=true \
        --encryption-configuration encryptionType=AES256
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully created repository: ${REPO}"
    else
        echo "❌ Failed to create repository: ${REPO} (may already exist)"
    fi
    echo "---"
done

echo ""
echo "ECR Setup Complete!"
echo "Next steps:"
echo "1. Run the build-and-push-to-ecr.sh script to push your Docker images"
echo "2. Update your Spring Boot application to use ECR image URIs"
