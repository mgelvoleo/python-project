

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements first (better caching)
COPY requirements.txt .

# Install packages with retry logic and timeout
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --retries 10 --timeout 60 -r requirements.txt

# Copy the rest of the application
COPY app.py .

# Command to run the application
CMD ["python", "app.py"]