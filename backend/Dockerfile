# Stage 1: Build dependencies in a virtual environment
FROM python:3.11-slim as builder

WORKDIR /app

# Install system dependencies required for building some python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .

# Install Python dependencies, caching pip for efficiency
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Production Image
FROM python:3.11-slim

# Install OpenCV system dependencies and curl for HEALTHCHECK
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash appuser

WORKDIR /home/appuser/app

# Copy the virtual environment from the builder stage
COPY --from=builder --chown=appuser:appuser /opt/venv /opt/venv

# Ensure the virtual environment is in the PATH
ENV PATH="/opt/venv/bin:$PATH"

# Copy application source code
COPY --chown=appuser:appuser . .

USER appuser

# Expose FastAPI port
EXPOSE 8000

# Healthcheck targeting the /health endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:8000/health/ || exit 1

# Start the application using uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
