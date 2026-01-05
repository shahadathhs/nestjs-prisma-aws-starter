# backup/Dockerfile
FROM python:3.12-slim

# Set environment variables
WORKDIR /backup

# Install packages
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     cron \
     postgresql-client \
     gzip \
     ca-certificates \
     curl \
     gnupg \
     build-essential \
  && pip install --no-cache-dir awscli \
  && rm -rf /var/lib/apt/lists/*

# Copy scripts folder
COPY scripts/ /backup/scripts/

# Make scripts executable
RUN chmod +x /backup/scripts/*.sh

# Entrypoint
CMD ["/backup/scripts/run-cron.sh"]
