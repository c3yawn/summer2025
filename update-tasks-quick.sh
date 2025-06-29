#!/bin/bash

# Quick update to use optimized containers

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com"

echo "🔄 Updating ECS tasks to use optimized containers..."

# Update Java task definition
aws ecs register-task-definition \
    --family java-compiler-task \
    --network-mode awsvpc \
    --requires-compatibilities FARGATE \
    --cpu 256 \
    --memory 512 \
    --execution-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole \
    --task-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsCodeCompilerTaskRole \
    --container-definitions '[
        {
            "name": "java-compiler",
            "image": "'${ECR_REGISTRY}'/java-compiler-runner:latest",
            "essential": true,
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/java-compiler-task",
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "ecs",
                    "awslogs-create-group": "true"
                }
            }
        }
    ]'

echo "✅ Updated java-compiler-task"

# Update other tasks
for lang in "javascript" "python" "cpp"; do
    aws ecs register-task-definition \
        --family ${lang}-compiler-task \
        --network-mode awsvpc \
        --requires-compatibilities FARGATE \
        --cpu 256 \
        --memory 512 \
        --execution-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole \
        --task-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsCodeCompilerTaskRole \
        --container-definitions '[
            {
                "name": "'${lang}'-compiler",
                "image": "'${ECR_REGISTRY}'/'${lang}'-compiler-runner:latest",
                "essential": true,
                "logConfiguration": {
                    "logDriver": "awslogs",
                    "options": {
                        "awslogs-group": "/ecs/'${lang}'-compiler-task",
                        "awslogs-region": "us-east-1",
                        "awslogs-stream-prefix": "ecs",
                        "awslogs-create-group": "true"
                    }
                }
            }
        ]'
    echo "✅ Updated ${lang}-compiler-task"
done

echo "🎉 All task definitions updated to use latest optimized containers!"