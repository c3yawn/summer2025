#!/bin/bash

# Setup IAM roles for ECS

echo "Setting up IAM roles for ECS..."

# 1. Create ECS Task Execution Role
echo "Creating ECS Task Execution Role..."
cat > ecs-task-execution-role-trust-policy.json << INNER_EOF
{
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
}
INNER_EOF

aws iam create-role \
    --role-name ecsTaskExecutionRole \
    --assume-role-policy-document file://ecs-task-execution-role-trust-policy.json 2>/dev/null || echo "Role already exists"

aws iam attach-role-policy \
    --role-name ecsTaskExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# 2. Create ECS Task Role (for the application itself)
echo "Creating ECS Task Role..."
cat > ecs-task-role-policy.json << INNER_EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
INNER_EOF

aws iam create-role \
    --role-name ecsTaskRole \
    --assume-role-policy-document file://ecs-task-execution-role-trust-policy.json 2>/dev/null || echo "Role already exists"

aws iam put-role-policy \
    --role-name ecsTaskRole \
    --policy-name ECRAndLogsAccess \
    --policy-document file://ecs-task-role-policy.json

# 3. Create ECR Access Policy for local development
echo "Creating ECR access policy for local development..."
cat > ecr-access-policy.json << INNER_EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage",
        "ecr:CreateRepository",
        "ecr:DescribeRepositories"
      ],
      "Resource": "*"
    }
  ]
}
INNER_EOF

aws iam create-policy \
    --policy-name CodeCompilerECRAccess \
    --policy-document file://ecr-access-policy.json 2>/dev/null || echo "Policy already exists"

echo "IAM roles setup complete!"
echo "Make sure to:"
echo "1. Attach the CodeCompilerECRAccess policy to your user/role for local development"
echo "2. Update the ARNs in ecs-task-definition.json with your account ID"

# Clean up temporary files
rm -f ecs-task-execution-role-trust-policy.json ecs-task-role-policy.json ecr-access-policy.json
