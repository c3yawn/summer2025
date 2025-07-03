# Multi-stage build: Start with Corretto for Java, then copy to Lambda base
FROM public.ecr.aws/amazoncorretto/amazoncorretto:11 as java-stage

# Install Python for Lambda compatibility
RUN yum update -y && yum install -y python3 python3-pip

# Final stage: Lambda base with Java copied over
FROM public.ecr.aws/lambda/python:3.11

# Copy Java runtime from Corretto image
COPY --from=java-stage /usr/lib/jvm/java-11-amazon-corretto /usr/lib/jvm/java-11-amazon-corretto
COPY --from=java-stage /usr/bin/java /usr/bin/java
COPY --from=java-stage /usr/bin/javac /usr/bin/javac

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto
ENV PATH=$JAVA_HOME/bin:$PATH

# Copy function code
COPY app.py ${LAMBDA_TASK_ROOT}

# Verify Java works
RUN java -version && javac -version

CMD ["app.lambda_handler"]
