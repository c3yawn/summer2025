#!/bin/bash

# Configuration
AWS_REGION="us-east-1"
CLUSTER_NAME="code-compiler-cluster"
SERVICE_NAME="code-compiler-service"
TASK_DEFINITION_FAMILY="code-compiler-service"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Deploying Code Compiler to ECS..."
echo "Account ID: ${AWS_ACCOUNT_ID}"
echo "Region: ${AWS_REGION}"
echo "Cluster: ${CLUSTER_NAME}"

# Step 1: Create ECS Cluster if it doesn't exist
echo "Creating ECS Cluster..."
aws ecs create-cluster \
    --cluster-name ${CLUSTER_NAME} \
    --capacity-providers FARGATE \
    --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 \
    --region ${AWS_REGION} 2>/dev/null || echo "Cluster already exists"

# Step 2: Create CloudWatch Log Group
echo "Creating CloudWatch Log Group..."
aws logs create-log-group \
    --log-group-name "/ecs/${TASK_DEFINITION_FAMILY}" \
    --region ${AWS_REGION} 2>/dev/null || echo "Log group already exists"

# Step 3: Register task definition
echo "Registering task definition..."
aws ecs register-task-definition \
    --cli-input-json file://ecs-task-definition.json \
    --region ${AWS_REGION}

echo "Task definition registered successfully!"
echo "You can now create an ECS service manually in the AWS Console or continue with automated service creation."
echo ""
echo "Next steps:"
echo "1. Go to AWS ECS Console"
echo "2. Select your cluster: ${CLUSTER_NAME}"
echo "3. Create a service using task definition: ${TASK_DEFINITION_FAMILY}"
echo "4. Configure networking (VPC, subnets, security groups)"
