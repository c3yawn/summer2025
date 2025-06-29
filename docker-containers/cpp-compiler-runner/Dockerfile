# Dockerfile for cpp-compiler-runner
FROM gcc:latest

# Install Python and pip with the --break-system-packages flag
RUN apt-get update && \
    apt-get install -y python3 python3-pip python3-venv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install required Python packages with --break-system-packages
RUN pip3 install --break-system-packages flask boto3

# Create working directory
WORKDIR /app

# Copy the compiler script
COPY cpp_compiler.py /app/

# Expose port
EXPOSE 8080

# Run the Flask application
CMD ["python3", "cpp_compiler.py"]