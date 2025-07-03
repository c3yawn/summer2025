FROM public.ecr.aws/lambda/nodejs:18

RUN yum install -y gcc-c++ make

COPY package.json ${LAMBDA_TASK_ROOT}
RUN npm install

COPY index.js ${LAMBDA_TASK_ROOT}

CMD ["index.handler"]
