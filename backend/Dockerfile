# Multi-stage Dockerfile for FastAPI + OpenCV
# Stage 1: Build dependencies
FROM python:3.11-slim as builder

WORKDIR /app
COPY requirements.txt .

# Install build dependencies if needed (none strictly required for binary wheels, but good practice)
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Production Image
FROM python:3.11-slim

# Install OpenCV headless dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m appuser
WORKDIR /home/appuser/app

# Copy installed python packages from builder
COPY --from=builder /root/.local /home/appuser/.local
ENV PATH=/home/appuser/.local/bin:$PATH

# Copy application source code
COPY . .

# Ensure appuser owns the directory
RUN chown -R appuser:appuser /home/appuser/app
USER appuser

# Expose FastAPI port
EXPOSE 8000

# Healthcheck targeting the /health endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:8000/health/ || exit 1

# Start the application using uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
