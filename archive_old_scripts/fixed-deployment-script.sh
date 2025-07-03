#!/bin/bash

# Fixed ECS-based Code Compiler Deployment Script

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
CLUSTER_NAME="code-compiler-cluster"
S3_BUCKET="code-compiler-temp-files-${AWS_ACCOUNT_ID}"

# Container images
LANGUAGES=("java" "javascript" "python" "cpp")

echo "🚀 Deploying ECS-based Code Compiler..."
echo "Account ID: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION"
echo "ECR Registry: $ECR_REGISTRY"

# Step 1: Create S3 bucket for temporary files
echo "📦 Creating S3 bucket for temporary files..."
aws s3 mb s3://${S3_BUCKET} --region ${AWS_REGION} 2>/dev/null || echo "Bucket already exists"

# Configure S3 bucket for auto-cleanup (optional)
cat > lifecycle-policy.json << EOF
{
    "Rules": [
        {
            "ID": "DeleteTempFiles",
            "Status": "Enabled",
            "Filter": {"Prefix": "temp/"},
            "Expiration": {"Days": 1}
        }
    ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
    --bucket ${S3_BUCKET} \
    --lifecycle-configuration file://lifecycle-policy.json

rm lifecycle-policy.json

# Step 2: Create ECR repositories
echo "📦 Creating ECR repositories..."
for lang in "${LANGUAGES[@]}"; do
    aws ecr create-repository \
        --repository-name ${lang}-compiler-runner \
        --region ${AWS_REGION} 2>/dev/null || echo "Repository ${lang}-compiler-runner already exists"
done

# Step 3: Login to ECR
echo "🔑 Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Step 4: Create Docker containers directory structure
echo "🏗️ Setting up container build structure..."
mkdir -p docker-containers

for lang in "${LANGUAGES[@]}"; do
    mkdir -p docker-containers/${lang}-compiler-runner
done

# Create compiler.py in current directory if not exists
if [ ! -f "compiler.py" ]; then
    echo "❌ compiler.py not found. Please create this file first."
    echo "Use the compiler.py artifact provided in the Claude conversation."
    exit 1
fi

# Create Dockerfile.ecs files if they don't exist
echo "📝 Creating Dockerfile.ecs files..."

# Java Dockerfile.ecs
cat > docker-containers/java-compiler-runner/Dockerfile.ecs << 'EOF'
# Java ECS Compiler Container
FROM openjdk:17-jdk-slim

# Install Python and AWS CLI for S3 operations
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install boto3 for S3 operations
RUN pip3 install boto3

# Create working directory
WORKDIR /app

# Copy compiler script
COPY compiler.py /app/compiler.py
RUN chmod +x /app/compiler.py

# Set entrypoint
ENTRYPOINT ["python3", "/app/compiler.py"]
EOF

# JavaScript Dockerfile.ecs
cat > docker-containers/javascript-compiler-runner/Dockerfile.ecs << 'EOF'
# JavaScript ECS Compiler Container
FROM node:18-slim

# Install Python and pip for running the compiler script
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install boto3 for S3 operations
RUN pip3 install boto3

# Create working directory
WORKDIR /app

# Copy compiler script
COPY compiler.py /app/compiler.py
RUN chmod +x /app/compiler.py

# Set entrypoint
ENTRYPOINT ["python3", "/app/compiler.py"]
EOF

# Python Dockerfile.ecs
cat > docker-containers/python-compiler-runner/Dockerfile.ecs << 'EOF'
# Python ECS Compiler Container
FROM python:3.11-slim

# Install boto3 for S3 operations
RUN pip3 install boto3

# Create working directory
WORKDIR /app

# Copy compiler script
COPY compiler.py /app/compiler.py
RUN chmod +x /app/compiler.py

# Set entrypoint
ENTRYPOINT ["python3", "/app/compiler.py"]
EOF

# C++ Dockerfile.ecs
cat > docker-containers/cpp-compiler-runner/Dockerfile.ecs << 'EOF'
# C++ ECS Compiler Container
FROM gcc:latest

# Install Python and AWS CLI for S3 operations
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install boto3 for S3 operations
RUN pip3 install boto3

# Create working directory
WORKDIR /app

# Copy compiler script
COPY compiler.py /app/compiler.py
RUN chmod +x /app/compiler.py

# Set entrypoint
ENTRYPOINT ["python3", "/app/compiler.py"]
EOF

# Step 5: Build and push container images
echo "🔨 Building and pushing container images..."
for lang in "${LANGUAGES[@]}"; do
    echo "Building ${lang}-compiler-runner..."
    
    # Copy compiler script to build context
    cp compiler.py docker-containers/${lang}-compiler-runner/
    
    # Build image
    cd docker-containers/${lang}-compiler-runner/
    docker build -f Dockerfile.ecs -t ${lang}-compiler-runner:latest .
    
    # Tag for ECR
    docker tag ${lang}-compiler-runner:latest ${ECR_REGISTRY}/${lang}-compiler-runner:latest
    
    # Push to ECR
    docker push ${ECR_REGISTRY}/${lang}-compiler-runner:latest
    
    echo "✅ ${lang}-compiler-runner pushed to ECR"
    
    # Clean up
    rm compiler.py
    cd ../..
done

# Step 6: Create ECS cluster
echo "🏗️ Creating ECS cluster..."
aws ecs create-cluster \
    --cluster-name ${CLUSTER_NAME} \
    --capacity-providers FARGATE \
    --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1

# Step 7: Create ECS task definitions
echo "📋 Creating ECS task definitions..."

# Create task execution role if it doesn't exist
aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}' 2>/dev/null || echo "ecsTaskExecutionRole already exists"

aws iam attach-role-policy \
    --role-name ecsTaskExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy 2>/dev/null || echo "Policy already attached"

# Create task role for S3 access
aws iam create-role --role-name ecsCodeCompilerTaskRole --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}' 2>/dev/null || echo "ecsCodeCompilerTaskRole already exists"

# Create S3 access policy
cat > s3-access-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${S3_BUCKET}",
                "arn:aws:s3:::${S3_BUCKET}/*"
            ]
        }
    ]
}
EOF

aws iam put-role-policy \
    --role-name ecsCodeCompilerTaskRole \
    --policy-name S3AccessPolicy \
    --policy-document file://s3-access-policy.json

rm s3-access-policy.json

for lang in "${LANGUAGES[@]}"; do
    cat > ${lang}-compiler-task.json << EOF
{
    "family": "${lang}-compiler-task",
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole",
    "taskRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsCodeCompilerTaskRole",
    "containerDefinitions": [
        {
            "name": "${lang}-compiler",
            "image": "${ECR_REGISTRY}/${lang}-compiler-runner:latest",
            "essential": true,
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/${lang}-compiler-task",
                    "awslogs-region": "${AWS_REGION}",
                    "awslogs-stream-prefix": "ecs",
                    "awslogs-create-group": "true"
                }
            }
        }
    ]
}
EOF

    aws ecs register-task-definition --cli-input-json file://${lang}-compiler-task.json
    echo "✅ ${lang}-compiler-task registered"
    rm ${lang}-compiler-task.json
done

# Step 8: Create security group for ECS tasks
echo "🔒 Creating security group..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text)

aws ec2 create-security-group \
    --group-name code-compiler-sg \
    --description "Security group for code compiler ECS tasks" \
    --vpc-id ${VPC_ID} 2>/dev/null || echo "Security group already exists"

# Get security group ID
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=code-compiler-sg" --query 'SecurityGroups[0].GroupId' --output text)

# Allow outbound traffic (for ECR pulls and S3 access)
aws ec2 authorize-security-group-egress \
    --group-id ${SG_ID} \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 2>/dev/null || echo "Egress rule already exists"

# Step 9: Get subnet information
echo "🌐 Getting subnet information..."
SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query 'Subnets[*].SubnetId' --output text)
SUBNET_ARRAY=($SUBNETS)

echo "✅ ECS-based Code Compiler deployment complete!"
echo ""
echo "📋 Summary:"
echo "  - S3 Bucket: ${S3_BUCKET}"
echo "  - ECS Cluster: ${CLUSTER_NAME}"
echo "  - Security Group: ${SG_ID}"
echo "  - VPC: ${VPC_ID}"
echo "  - Subnets: ${SUBNETS}"
echo ""
echo "🔧 Configuration for your Spring Boot application:"
echo "aws.ecs.cluster=${CLUSTER_NAME}"
echo "aws.s3.bucket=${S3_BUCKET}"
echo "aws.ecr.registry=${ECR_REGISTRY}"
echo "aws.vpc.security-group=${SG_ID}"
echo "aws.vpc.subnets=${SUBNET_ARRAY[0]},${SUBNET_ARRAY[1]}"
echo ""
echo "🧪 Test Command:"
echo "curl -X POST http://localhost:8080/code/execute -F \"language=cpp\" -F \"mainClassName=main\" -F \"javaFiles=@test.cpp\""