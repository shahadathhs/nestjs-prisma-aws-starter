# backup/Dockerfile
FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/scripts:${PATH}"

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

# Create directories
RUN mkdir -p /backups /scripts /var/log/backup

# Copy scripts
COPY run-cron.sh /scripts/run-cron.sh
COPY backup-database.sh /scripts/backup-database.sh
COPY restore-database.sh /scripts/restore-database.sh

RUN chmod +x /scripts/*.sh

# Entrypoint
CMD ["/scripts/run-cron.sh"]
