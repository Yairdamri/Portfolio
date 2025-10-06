# Use the official Python image for building the app
FROM python:3.11-slim AS builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set the working directory
WORKDIR /app

# Copy the requirements file into the image
COPY requirements.txt /app/

# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire app directory into the image
COPY . /app/

# ---
# Lightweight test image to run unit tests (isolated, no real DB)
FROM python:3.11-slim AS test
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV USE_MOCK_DB=1
WORKDIR /app

# Only install deps needed for tests
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt && pip install --no-cache-dir pytest pytest-cov

# Copy application and tests
COPY app /app/app
COPY tests /app/tests
COPY pytest.ini /app/pytest.ini

# Default command runs tests and writes JUnit report to /app/reports
CMD ["bash", "-lc", "mkdir -p /app/reports && pytest -q --maxfail=1 --disable-warnings --junitxml=/app/reports/unit-tests.xml"]

# ---
# Use a smaller base image for the runtime stage
FROM python:3.11-alpine AS runtime

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set the working directory
WORKDIR /app

# Copy the requirements file and install dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy only the necessary files from the builder stage
COPY --from=builder /app /app

# Expose the port FastAPI runs on
EXPOSE 8000

# Command to run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
