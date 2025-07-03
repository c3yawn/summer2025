FROM public.ecr.aws/amazoncorretto/amazoncorretto:17 as builder
RUN yum update -y && yum install -y python3 python3-pip && yum clean all

FROM public.ecr.aws/lambda/python:3.11
COPY --from=builder /usr/lib/jvm/java-17-amazon-corretto /usr/lib/jvm/java-17-amazon-corretto
COPY --from=builder /usr/bin/java /usr/bin/java
COPY --from=builder /usr/bin/javac /usr/bin/javac

ENV JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto
ENV PATH=$JAVA_HOME/bin:$PATH

COPY handler.py ${LAMBDA_TASK_ROOT}/
COPY requirements.txt ${LAMBDA_TASK_ROOT}/
RUN pip install -r requirements.txt

CMD ["handler.lambda_handler"]
