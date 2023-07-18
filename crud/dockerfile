# Stage 1: Development stage
FROM python:3.9-alpine as development
WORKDIR /work

# Stage 2: Runtime stage
FROM development as runtime
WORKDIR /app

COPY ./src/requirements.txt /app/
RUN pip install -r /app/requirements.txt

COPY ./src/app.py /app/app.py
COPY ./src/website /app/website

WORKDIR /app
CMD flask run -h 0.0.0 -p 5000