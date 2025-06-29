# Dockerfile content for java_code_runner_docker/Dockerfile
# Stage 1: Build - used for compilation
FROM openjdk:17-jdk-slim AS builder

# Set a working directory inside the container
WORKDIR /app

# The command to run your application will be provided at runtime
# via 'docker run' or a script. This ENTRYPOINT is just a default.
# It makes the container ready to receive commands for compilation/execution.
CMD ["java"]
