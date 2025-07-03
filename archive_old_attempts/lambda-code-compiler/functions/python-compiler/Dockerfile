FROM public.ecr.aws/lambda/python:3.11

COPY handler.py ${LAMBDA_TASK_ROOT}/
COPY requirements.txt ${LAMBDA_TASK_ROOT}/

RUN pip install -r requirements.txt

CMD ["handler.lambda_handler"]
