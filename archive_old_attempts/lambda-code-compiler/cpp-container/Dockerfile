FROM public.ecr.aws/lambda/python:3.9

# Install C++ compiler and development tools
RUN yum update -y && \
    yum groupinstall -y "Development Tools" && \
    yum install -y gcc-c++ gdb make cmake && \
    yum clean all && \
    rm -rf /var/cache/yum

# Verify C++ installation during build
RUN gcc --version && g++ --version

# Copy function code
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Default command
CMD ["lambda_function.lambda_handler"]
