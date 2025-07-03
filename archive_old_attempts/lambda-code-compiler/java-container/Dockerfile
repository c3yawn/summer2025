FROM public.ecr.aws/lambda/python:3.9

# Install Java using Amazon Linux package manager (most compatible)
RUN yum update -y && \
    yum install -y java-11-amazon-corretto-headless java-11-amazon-corretto-devel && \
    yum clean all && \
    rm -rf /var/cache/yum

# Set Java environment
ENV JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto.x86_64
ENV PATH=$JAVA_HOME/bin:$PATH

# Verify Java installation during build
RUN java -version 2>&1 | head -1 && javac -version 2>&1

# Copy function code
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Default command
CMD ["lambda_function.lambda_handler"]
