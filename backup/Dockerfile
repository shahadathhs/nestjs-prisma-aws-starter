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

# Copy backup
COPY run-cron.sh ./run-cron.sh
COPY backup-database.sh ./backup-database.sh
COPY restore-database.sh ./restore-database.sh

# Make scripts executable
RUN chmod +x ./run-cron.sh ./backup-database.sh ./restore-database.sh

# Entrypoint
CMD ["/backup/run-cron.sh"]
