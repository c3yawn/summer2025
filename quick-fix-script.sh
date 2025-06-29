#!/bin/bash

# Quick fix for failed JavaScript and C++ containers

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com"

echo "🔧 Fixing JavaScript and C++ containers..."

# Fix JavaScript container
echo "Building fixed javascript-compiler-runner..."

# Update the Dockerfile.ecs for JavaScript
cat > docker-containers/javascript-compiler-runner/Dockerfile.ecs << 'EOF'
# JavaScript ECS Compiler Container (Fixed)
FROM node:18-slim

# Install Python and pip for running the compiler script
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment, then install boto3
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install boto3

# Create working directory
WORKDIR /app

# Copy compiler script
COPY compiler.py /app/compiler.py
RUN chmod +x /app/compiler.py

# Set entrypoint with virtual environment
ENTRYPOINT ["/opt/venv/bin/python", "/app/compiler.py"]
EOF

# Copy compiler script and build
cp compiler.py docker-containers/javascript-compiler-runner/
cd docker-containers/javascript-compiler-runner/
docker build -f Dockerfile.ecs -t javascript-compiler-runner:latest .
docker tag javascript-compiler-runner:latest ${ECR_REGISTRY}/javascript-compiler-runner:latest
docker push ${ECR_REGISTRY}/javascript-compiler-runner:latest
rm compiler.py
cd ../..

echo "✅ JavaScript container fixed and pushed"

# Fix C++ container
echo "Building fixed cpp-compiler-runner..."

# Update the Dockerfile.ecs for C++
cat > docker-containers/cpp-compiler-runner/Dockerfile.ecs << 'EOF'
# C++ ECS Compiler Container (Fixed)
FROM gcc:latest

# Install Python and pip for running the compiler script
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment, then install boto3
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install boto3

# Create working directory
WORKDIR /app

# Copy compiler script
COPY compiler.py /app/compiler.py
RUN chmod +x /app/compiler.py

# Set entrypoint with virtual environment
ENTRYPOINT ["/opt/venv/bin/python", "/app/compiler.py"]
EOF

# Copy compiler script and build
cp compiler.py docker-containers/cpp-compiler-runner/
cd docker-containers/cpp-compiler-runner/
docker build -f Dockerfile.ecs -t cpp-compiler-runner:latest .
docker tag cpp-compiler-runner:latest ${ECR_REGISTRY}/cpp-compiler-runner:latest
docker push ${ECR_REGISTRY}/cpp-compiler-runner:latest
rm compiler.py
cd ../..

echo "✅ C++ container fixed and pushed"

echo "🎉 All containers are now fixed and pushed to ECR!"