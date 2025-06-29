# Code Compiler Backend Service

Spring Boot API service that handles multi-language code compilation requests and orchestrates Docker container execution for Java, JavaScript, Python, and C++.

## 🏗️ Architecture

This backend service acts as an API gateway that:
- Receives code compilation requests from the Flutter frontend
- Validates and routes requests to appropriate language-specific Docker containers
- Manages container lifecycle and response processing
- Returns standardized compilation and execution results

## 🚀 Quick Start

### Prerequisites

- **Java 17+** - [Download here](https://adoptium.net/)
- **Docker Desktop** - [Install for your OS](https://docs.docker.com/get-started/get-docker/)
- **AWS CLI** (configured) - For ECR access in production
- **IDE**: VS Code with `Extension Pack for Java` and `Spring Boot Extension Pack`

### Local Development Setup

1. **Clone and navigate to backend:**
   ```bash
   git clone <repository-url>
   cd summer2025/backend/
   ```

2. **Configure application properties:**
   ```properties
   # src/main/resources/application.properties
   aws.region=us-east-1
   aws.ecr.registry=123904282156.dkr.ecr.us-east-1.amazonaws.com
   
   # Docker image mappings
   docker.images.java=java-compiler-runner
   docker.images.javascript=js-compiler-runner
   docker.images.python=python-compiler-runner
   docker.images.cpp=cpp-compiler-runner
   ```

3. **Build required Docker containers:**
   ```bash
   # From project root (summer2025/)
   cd docker-containers/java_dockerfile/
   docker build -t java-compiler-runner .
   
   cd ../javascript_dockerfile/
   docker build -t js-compiler-runner .
   
   cd ../python_dockerfile/
   docker build -t python-compiler-runner .
   
   cd ../cpp-compiler-runner/
   docker build -t cpp-compiler-runner .
   ```

4. **Start the Spring Boot service:**
   ```bash
   # Navigate back to backend directory
   cd ../../backend/
   
   # Method 1: Using Gradle wrapper (recommended)
   ./gradlew bootRun
   
   # Method 2: Using VS Code Spring Boot Dashboard
   # - Open VS Code in the backend directory
   # - Use Spring Boot Dashboard extension to start the app
   
   # Method 3: Using IDE
   # - Import project into IntelliJ IDEA or Eclipse
   # - Run CodecompilerApplication.java main method
   ```

5. **Verify service is running:**
   ```bash
   # Wait for startup message: "Started CodecompilerApplication in X.XXX seconds"
   
   # Test health endpoint
   curl http://localhost:8080/code/health
   # Should return: {"status":"healthy","service":"Docker Code Compiler","timestamp":"..."}
   
   # Check port usage
   netstat -ano | findstr :8080  # Windows
   # or
   lsof -ti:8080                  # macOS/Linux
   ```

## 🏃‍♂️ Starting the Application

### Prerequisites Check
Before starting, ensure you have:
- ✅ **Java 17+** installed
- ✅ **Docker Desktop** running
- ✅ **All 4 language containers** built (see step 3 above)

### Startup Process

1. **Open terminal in backend directory:**
   ```bash
   cd summer2025/backend/
   ```

2. **Start Spring Boot service:**
   ```bash
   ./gradlew bootRun
   ```

3. **Look for startup confirmation:**
   ```
   Started CodecompilerApplication in 1.771 seconds (process running for 2.137)
   ```

4. **Test the service:**
   ```bash
   # Health check
   curl http://localhost:8080/code/health
   
   # Should return:
   # {"status":"healthy","service":"Docker Code Compiler","timestamp":"2024-01-01T12:00:00Z"}
   ```

### Common Startup Issues

**Port 8080 already in use:**
```bash
# Find what's using port 8080
netstat -ano | findstr :8080

# Kill the process (replace PID with actual process ID)
taskkill /f /pid [PID]

# Or change port in application.properties:
server.port=8081
```

**Docker containers missing:**
```bash
# Check if containers exist
docker images | grep compiler-runner

# If any are missing, build them:
cd docker-containers/[language]_dockerfile/
docker build -t [language]-compiler-runner .
```

**Java not found:**
```bash
# Check Java version
java -version  # Should show Java 17+

# If not installed, download from: https://adoptium.net/
```

## 🐳 Docker Container Setup

The backend communicates with language-specific Docker containers. Each container must be built and available locally for development:

### Build All Language Containers

```bash
# From project root (summer2025/)

# Java Compiler
cd docker-containers/java-compiler-runner/
docker build -t java-compiler-runner .

# JavaScript Compiler  
cd ../javascript-compiler-runner/
docker build -t js-compiler-runner .

# Python Compiler
cd ../python-compiler-runner/
docker build -t python-compiler-runner .

# C++ Compiler
cd ../cpp-compiler-runner/
docker build -t cpp-compiler-runner .

# Verify images were built
docker images | grep compiler-runner
```

## 🧪 Testing the API

### Using Postman

1. **Install Postman** and the [Postman Desktop Agent](https://www.postman.com/downloads/postman-agent/)
2. **Test compilation endpoint:**

```http
POST http://localhost:8080/code/execute
Content-Type: multipart/form-data

Fields:
- language: cpp
- mainClassName: main
- javaFiles: [upload your .cpp file]
```

### Using cURL

```bash
# Create test file
cat > test.cpp << 'EOF'
#include <iostream>
using namespace std;

int main() {
    cout << "Hello from C++!" << endl;
    return 0;
}
EOF

# Test API
curl -X POST http://localhost:8080/code/execute \
  -F "language=cpp" \
  -F "mainClassName=main" \
  -F "javaFiles=@test.cpp"
```

**Expected Response:**
```json
{
    "status": "Success",
    "compilationErrors": "",
    "programOutput": "Hello from C++!",
    "hasError": false
}
```

## 📁 Project Structure

```
backend/
├── src/main/java/
│   └── com/codecompiler/
│       ├── CodeCompilerApplication.java
│       ├── controller/
│       │   └── CodeExecutionController.java
│       └── service/
│           └── DockerContainerService.java
├── src/main/resources/
│   └── application.properties
├── build.gradle
└── README.md
```

## ⚙️ Configuration

### Environment Variables

```bash
# Development
export AWS_REGION=us-east-1
export DOCKER_HOST=unix:///var/run/docker.sock

# Production (ECS)
export AWS_DEFAULT_REGION=us-east-1
export ECR_REGISTRY=123904282156.dkr.ecr.us-east-1.amazonaws.com
```

### Application Properties

```properties
# AWS Configuration
aws.region=${AWS_REGION:us-east-1}
aws.ecr.registry=${ECR_REGISTRY:123904282156.dkr.ecr.us-east-1.amazonaws.com}

# Docker Image Names
docker.images.java=java-compiler-runner
docker.images.javascript=js-compiler-runner
docker.images.python=python-compiler-runner
docker.images.cpp=cpp-compiler-runner

# Server Configuration
server.port=8080
logging.level.com.codecompiler=DEBUG
```

## 🚀 Deployment

### Local Development
- Run containers locally using Docker Desktop
- Spring Boot connects to local Docker daemon

### Production (AWS ECS)
- Containers are pulled from ECR
- Spring Boot runs on ECS Fargate
- Uses IAM roles for container orchestration

### Build and Deploy Scripts
```bash
# Build and push containers to ECR
cd ../infrastructure/ecr/
./create-ecr-repositories.sh
./build-and-push-to-ecr.sh

# Deploy Spring Boot service to ECS
cd ../ecs/
./deploy-to-ecs.sh
```

## 🔧 API Endpoints

### POST /code/execute
Compiles and executes code in the specified language.

**Request:**
- `language` (string): `java|javascript|python|cpp`
- `mainClassName` (string): Main class/file name
- `javaFiles` (files): Source code files

**Response:**
```json
{
    "status": "Success|Compilation Failed|Runtime Error|Timeout",
    "compilationErrors": "string",
    "programOutput": "string",
    "hasError": boolean
}
```

### GET /health
Health check endpoint.

**Response:**
```json
{
    "status": "healthy",
    "timestamp": "2024-01-01T12:00:00Z"
}
```

## 🐛 Troubleshooting

### Common Issues

**Docker containers not found:**
```bash
# Ensure containers are built
docker images | grep compiler-runner

# Rebuild if missing
cd docker-containers/cpp-compiler-runner/
docker build -t cpp-compiler-runner .
```

**Port 8080 already in use:**
```bash
# Find process using port
lsof -ti:8080

# Kill process or change port in application.properties
server.port=8081
```

**AWS credentials issues (production):**
```bash
# Configure AWS CLI
aws configure

# Test ECR access
aws ecr describe-repositories --region us-east-1
```

### Logs

**Local development:**
- Check Spring Boot console output
- Docker container logs: `docker logs <container-id>`

**Production (ECS):**
- CloudWatch Logs: `/ecs/code-compiler-api`
- ECS Console: Task logs and metrics

## 🔒 Security Notes

- **Input validation**: File size limits, content sanitization
- **Container isolation**: Each execution runs in isolated environment
- **Resource limits**: CPU, memory, and execution time constraints
- **Network security**: Containers have no external internet access

## 🤝 Development Workflow

### Adding a New Language

1. **Create Docker container** in `docker-containers/new-language-runner/`
2. **Update application.properties** with new language mapping
3. **Add language support** in `CodeExecutionController.java`
4. **Test locally** with new language requests
5. **Deploy updated containers** and service

### Making Changes

```bash
# Make your changes
git add .
git commit -m "Description of changes"
git push

# Redeploy if needed
./infrastructure/ecs/deploy-to-ecs.sh
```

## 📚 Additional Resources

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Docker Documentation](https://docs.docker.com/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Project Technical Overview](../docs/technical-overview.md)

---

**Note:** This service is designed for educational purposes. Ensure proper security measures for production deployments.