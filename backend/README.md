# Code Compiler Backend Service

Enterprise-grade Spring Boot API service that provides multi-language code compilation through a three-tier performance optimization system: intelligent caching, fast local execution, and cloud-native ECS containers.

## 🏗️ Architecture

This backend service implements a sophisticated execution pipeline:

```
Flutter Frontend → Spring Boot API → Performance Optimization Engine
                                  ↓
                              ┌─────────────┐
                              │ Cache Layer │ (0.05s - instant results)
                              └─────────────┘
                                      ↓
                              ┌─────────────┐
                              │ Fast Path   │ (1-3s - small Python/JS)
                              └─────────────┘
                                      ↓
                              ┌─────────────┐
                              │ ECS Fargate │ (25-35s - compiled languages)
                              └─────────────┘
```

### Core Features
- **🚀 Intelligent Caching**: 1000x speedup for repeated code (0.05s)
- **⚡ Fast Path Execution**: Local execution for small Python/JavaScript files (1-3s)
- **🐳 Optimized ECS**: Cloud-native compilation with pre-optimized containers (25-35s)
- **📊 Performance Monitoring**: Real-time statistics and health monitoring
- **🔄 Auto-scaling**: AWS Fargate handles concurrent requests automatically

## 🚀 Quick Start

### Prerequisites

- **Java 17+** - [Download here](https://adoptium.net/)
- **AWS CLI** (configured) - For ECS/ECR access
- **Python 3.11+** - For fast path execution
- **Node.js 18+** - For fast path execution
- **IDE**: VS Code with Spring Boot extensions

### Local Development Setup

1. **Clone and navigate to backend:**
   ```bash
   git clone <repository-url>
   cd summer2025/backend/
   ```

2. **Configure AWS credentials:**
   ```bash
   aws configure
   # Enter your AWS credentials with ECS/ECR permissions
   ```

3. **Configure application properties:**
   ```properties
   # src/main/resources/application.properties
   aws.ecs.cluster=code-compiler-cluster
   aws.s3.bucket=code-compiler-temp-files-123904282156
   aws.ecr.registry=123904282156.dkr.ecr.us-east-1.amazonaws.com
   aws.vpc.subnets=subnet-0cc5b1a7eb85fa21b,subnet-0fb4c72b49056bc86
   aws.vpc.security-group=sg-043cb52fa65fdd33f
   
   # ECS Task Definitions
   ecs.taskdef.java=java-compiler-task
   ecs.taskdef.javascript=javascript-compiler-task
   ecs.taskdef.python=python-compiler-task
   ecs.taskdef.cpp=cpp-compiler-task
   
   # Cache Configuration
   cache.compilation.ttl.minutes=30
   cache.compilation.max.size=1000
   ```

4. **Install local runtimes for fast path:**
   ```bash
   # Windows
   winget install Python.Python.3.11
   winget install OpenJS.NodeJS
   
   # macOS
   brew install python@3.11 node
   
   # Linux
   sudo apt-get install python3.11 nodejs npm
   ```

5. **Deploy AWS infrastructure (one-time setup):**
   ```bash
   # From project root
   ./fixed-deployment-script.sh
   
   # Build and deploy optimized containers
   ./build-optimized-containers.sh
   
   # Optimize ECS task definitions
   ./optimize-ecs-performance.sh
   ```

6. **Start the Spring Boot service:**
   ```bash
   # Method 1: Using Gradle wrapper (recommended)
   ./gradlew bootRun
   
   # Method 2: Using IDE
   # Run CodeCompilerApplication.java main method
   ```

7. **Verify all systems are operational:**
   ```bash
   # Wait for startup message: "Started CodeCompilerApplication in X.XXX seconds"
   
   # Test health endpoint with performance statistics
   curl http://localhost:8080/code/health
   
   # Check cache statistics
   curl http://localhost:8080/code/cache/stats
   
   # Check fast execution capabilities
   curl http://localhost:8080/code/fast/stats
   ```

## 🏃‍♂️ Performance Optimization System

### Three-Tier Execution Engine

1. **Cache Layer (Instant - 0.05s)**
   - Smart content-based caching
   - Automatic cache invalidation
   - 1000x performance improvement for repeated code

2. **Fast Path (Ultra-fast - 1-3s)**
   - Local Python/JavaScript execution
   - File size limit: 2KB
   - No AWS costs for simple scripts

3. **ECS Cloud Execution (Optimized - 25-35s)**
   - AWS Fargate containers with optimized images
   - Support for Java, C++, Python, JavaScript
   - Auto-scaling and isolated execution

### Performance Monitoring

```bash
# Real-time performance statistics
curl http://localhost:8080/code/health

# Expected response with performance metrics:
{
  "status": "healthy",
  "service": "ECS Code Compiler with Warm Pool",
  "cluster_active": true,
  "cache": {
    "total_entries": 10,
    "valid_entries": 8,
    "max_size": 1000,
    "ttl_minutes": 30
  },
  "fast_execution": {
    "supported_languages": ["python", "javascript"],
    "max_file_size_bytes": 2048
  }
}
```

## 🧪 Testing the API

### Performance Test Suite

```bash
# Test 1: Cache Performance (should be ~0.05s on repeat)
curl -X POST http://localhost:8080/code/execute \
  -F "language=python" \
  -F "javaFiles=@test.py"

# Test 2: Fast Path (should be 1-3s for small files)
echo 'print("Fast path test!")' > small_test.py
curl -X POST http://localhost:8080/code/execute \
  -F "language=python" \
  -F "javaFiles=@small_test.py"

# Test 3: ECS Execution (should be 25-35s for compiled languages)
curl -X POST http://localhost:8080/code/execute \
  -F "language=java" \
  -F "javaFiles=@HelloWorld.java"
```

### Language Support Matrix

| Language   | Fast Path | ECS Execution | Expected Performance |
|------------|-----------|---------------|---------------------|
| Python     | ✅ < 2KB  | ✅ Any size   | 1-3s / 25-35s      |
| JavaScript | ✅ < 2KB  | ✅ Any size   | 1-3s / 25-35s      |
| Java       | ❌        | ✅ Any size   | 25-35s             |
| C++        | ❌        | ✅ Any size   | 25-35s             |

## 📁 Enhanced Project Structure

```
backend/
├── src/main/java/com/focusedai/codecompiler/
│   ├── CodeCompilerApplication.java           # Main Spring Boot application
│   ├── CodeCompilerController.java            # REST API endpoints
│   ├── EcsCodeCompilerService.java           # Core orchestration service
│   ├── CompilationCacheService.java          # Intelligent caching system
│   ├── FastExecutionService.java             # Local execution engine
│   ├── WarmPoolService.java                  # Container warm pool management
│   ├── AwsConfiguration.java                 # AWS SDK configuration
│   └── CompilationResult.java                # Response model
├── src/main/resources/
│   └── application.properties                # Configuration
├── build.gradle                              # Dependencies (AWS SDK, Spring Boot, Caffeine)
└── README.md
```

## ⚙️ Advanced Configuration

### Environment Variables

```bash
# AWS Configuration
export AWS_DEFAULT_REGION=us-east-1
export AWS_PROFILE=default

# Performance Tuning
export JAVA_OPTS="-Xmx2G -XX:+UseG1GC"
export CACHE_MAX_SIZE=1000
export FAST_PATH_FILE_LIMIT=2048
```

### Cache Configuration

```properties
# Cache settings for optimal performance
cache.compilation.ttl.minutes=30
cache.compilation.max.size=1000

# Fast path execution limits
fast.execution.max.file.size=2048
fast.execution.timeout.seconds=10
fast.execution.supported.languages=python,javascript

# ECS optimization settings
ecs.task.cpu=512
ecs.task.memory=1024
ecs.task.timeout.minutes=5
```

## 🚀 AWS Infrastructure

### Required AWS Resources

The application requires these AWS resources (created by deployment scripts):

- **ECS Cluster**: `code-compiler-cluster`
- **S3 Bucket**: `code-compiler-temp-files-123904282156`
- **ECR Repositories**: 4 language-specific container repositories
- **VPC Configuration**: Subnets and security groups for Fargate
- **IAM Roles**: ECS execution and task roles

### Container Architecture

Each language uses optimized multi-stage Docker builds:

```dockerfile
# Example: Optimized Python container
FROM python:3.11-slim as builder
RUN pip install --target=/install boto3

FROM python:3.11-slim as runtime
COPY --from=builder /install /usr/local/lib/python3.11/site-packages
ENV PYTHONUNBUFFERED=1
RUN python3 -c "import boto3; print('Pre-warmed')"
COPY compiler.py /app/compiler.py
ENTRYPOINT ["python3", "/app/compiler.py"]
```

## 🔧 API Endpoints

### Core Execution
- **POST** `/code/execute` - Multi-tier code execution
- **GET** `/code/health` - Comprehensive system health

### Performance Monitoring
- **GET** `/code/cache/stats` - Cache performance metrics
- **POST** `/code/cache/clear` - Clear compilation cache
- **GET** `/code/fast/stats` - Fast path execution statistics

### System Management
- **GET** `/code/supported-languages` - Available languages
- **POST** `/code/fast/test` - Test fast path eligibility

### Enhanced Response Format

```json
{
  "success": true,
  "output": "Hello, World!\n",
  "error": "",
  "execution_path": "cache_hit|fast_path|ecs_execution",
  "execution_time_ms": 52,
  "cache_status": "hit|miss"
}
```

## 📊 Performance Metrics & Monitoring

### Real-time Statistics

```bash
# Cache performance
curl http://localhost:8080/code/cache/stats
{
  "total_entries": 15,
  "cache_hit_rate": 0.73,
  "average_retrieval_time_ms": 2.3
}

# Fast execution statistics  
curl http://localhost:8080/code/fast/stats
{
  "total_fast_executions": 45,
  "average_execution_time_ms": 1247,
  "supported_languages": ["python", "javascript"]
}
```

### Performance Benchmarks

| Execution Type | Time Range | Use Case | Cost Impact |
|---------------|------------|----------|-------------|
| Cache Hit | 0.05-0.1s | Repeated testing | $0 |
| Fast Path | 1-3s | Learning/simple scripts | $0 |
| ECS Optimized | 25-35s | Complex compilation | ~$0.01 per execution |

## 🐛 Troubleshooting

### Performance Issues

**Slow ECS execution (>60s):**
```bash
# Check if optimized containers are deployed
aws ecr describe-images --repository-name java-compiler-runner

# Verify task definitions use optimized settings
aws ecs describe-task-definition --task-definition java-compiler-task

# Re-run optimization script
./optimize-ecs-performance.sh
```

**Cache not working:**
```bash
# Check cache statistics
curl http://localhost:8080/code/cache/stats

# Clear and test cache
curl -X POST http://localhost:8080/code/cache/clear
# Run same code twice to test caching
```

**Fast path not activating:**
```bash
# Check if runtimes are installed
python --version  # Should show Python 3.11+
node --version    # Should show Node 18+

# Test fast path eligibility
curl -X POST http://localhost:8080/code/fast/test \
  -F "language=python" \
  -F "javaFiles=@small_test.py"
```

### AWS Configuration Issues

**ECS tasks failing:**
```bash
# Check cluster status
aws ecs describe-clusters --clusters code-compiler-cluster

# View recent task failures
aws ecs list-tasks --cluster code-compiler-cluster --desired-status STOPPED

# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/ecs/"
```

**S3 access issues:**
```bash
# Test S3 permissions
aws s3 ls s3://code-compiler-temp-files-123904282156/

# Check IAM role permissions
aws iam get-role --role-name ecsCodeCompilerTaskRole
```

## 🔒 Security Features

- **Process Isolation**: Each execution in separate Fargate container
- **Network Security**: Containers have no internet access except ECR/S3
- **Resource Limits**: CPU/memory constraints prevent abuse
- **Input Validation**: File size limits and content sanitization
- **Timeout Protection**: 5-minute maximum execution time
- **Temporary Storage**: S3 lifecycle policy removes files after 1 day

## 📈 Scaling & Production

### Auto-scaling Capabilities
- **ECS Fargate**: Automatic container scaling based on demand
- **S3**: Unlimited storage with lifecycle management
- **Cache**: In-memory caching with configurable limits
- **Fast Path**: Local execution scales with server resources

### Cost Optimization
- **Cache hits**: No AWS charges
- **Fast path**: No AWS charges for simple scripts
- **ECS execution**: Pay-per-use Fargate pricing
- **S3**: Minimal storage costs with automatic cleanup

### Production Deployment

```bash
# Deploy complete infrastructure
./fixed-deployment-script.sh

# Build and push optimized containers
./build-optimized-containers.sh

# Deploy application to ECS
./deploy-spring-boot-to-ecs.sh

# Configure load balancing and auto-scaling
./configure-production-scaling.sh
```

## 🤝 Development Workflow

### Adding Performance Optimizations

1. **Implement caching** for new data types
2. **Extend fast path** to support additional languages
3. **Optimize container images** for faster startup
4. **Add monitoring** for new metrics

### Making Changes

```bash
# Local development
./gradlew bootRun

# Test all performance tiers
curl http://localhost:8080/code/health

# Deploy changes
git push
./deploy-updated-containers.sh
```

## 📚 Additional Resources

- [AWS ECS Best Practices](https://docs.aws.amazon.com/ecs/latest/bestpracticesguide/)
- [Spring Boot Caching](https://spring.io/guides/gs/caching/)
- [Docker Multi-stage Builds](https://docs.docker.com/develop/dev-best-practices/)
- [System Architecture Documentation](../docs/architecture.md)

---

**🎯 Performance Achievement**: This system delivers 1000x speedup for repeated code and 3-4x improvement for complex compilation through intelligent caching and cloud-native optimization.