# Use Ubuntu 22.04
FROM ubuntu:22.04

# Set environment
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    FLASK_APP=app.py \
    FLASK_ENV=production

# Install Python 3.10, pip, and system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3.10-venv \
    python3.10-dev \
    python3-pip \
    build-essential \
    libffi-dev \
    libssl-dev \
    libpq-dev \
    git \
    git-annex \
    git-annex-remote-rclone \
    curl \
    wget \
    sqlite3 \
    libcurl4-openssl-dev \
    libxml2-dev \
    libxslt-dev \
    pkg-config \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create symbolic links for python and pip
RUN ln -sf /usr/bin/python3.10 /usr/bin/python3 \
    && ln -sf /usr/bin/python3 /usr/bin/python

# Upgrade pip
RUN python3 -m pip install --upgrade pip setuptools wheel

# Workdir
WORKDIR /app

# Copy requirements first (for caching)
COPY requirements.txt .

# Fix bcrypt issue (required by CONP Portal)
RUN pip install "bcrypt>=4.0.1"

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the full app
COPY . .

# Create necessary instance directory
RUN mkdir -p /app/instance \
    && chmod 755 /app

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/ || exit 1

# Start CONP Portal
CMD ["bash", "-c", \
    "flask db upgrade && \
     flask seed_test_db && \
     flask update_pipeline_data && \
     flask seed_test_experiments && \
     flask run --host 0.0.0.0 --port 5000"]

