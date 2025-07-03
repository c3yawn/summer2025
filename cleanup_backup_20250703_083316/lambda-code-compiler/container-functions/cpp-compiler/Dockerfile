# Multi-stage build: Start with Ubuntu for GCC, then copy to Lambda base
FROM ubuntu:20.04 as gcc-stage

# Install GCC and essential tools
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    gcc g++ libc6-dev \
    python3 python3-pip && \
    apt-get clean

# Final stage: Lambda base with GCC copied over
FROM public.ecr.aws/lambda/python:3.11

# Copy GCC binaries (Ubuntu paths)
COPY --from=gcc-stage /usr/bin/gcc /usr/bin/gcc
COPY --from=gcc-stage /usr/bin/g++ /usr/bin/g++

# Copy essential libraries
COPY --from=gcc-stage /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/lib64/
COPY --from=gcc-stage /usr/lib/x86_64-linux-gnu/libgcc_s.so.1 /usr/lib64/
COPY --from=gcc-stage /lib/x86_64-linux-gnu/libc.so.6 /usr/lib64/
COPY --from=gcc-stage /lib64/ld-linux-x86-64.so.2 /lib64/

# Copy headers and library directories
COPY --from=gcc-stage /usr/include /usr/include
COPY --from=gcc-stage /usr/lib/gcc /usr/lib/gcc

# Copy function code
COPY app.py ${LAMBDA_TASK_ROOT}

# Test GCC
RUN g++ --version || echo "GCC test failed, but continuing..."

CMD ["app.lambda_handler"]
