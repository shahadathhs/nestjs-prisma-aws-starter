# backup/Dockerfile
FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/bin:${PATH}"

# Install packages: cron, pg client, gzip, curl, openssl libs for AWS, etc.
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

# Create backup directory and logs
RUN mkdir -p /backups /scripts /var/log/backup \
  && chmod 755 /scripts

# Copy scripts (should be executable)
COPY run-cron.sh /usr/local/bin/run-cron.sh
COPY backup.sh /usr/local/bin/backup.sh

RUN chmod +x /usr/local/bin/run-cron.sh /usr/local/bin/backup.sh

# Entrypoint: start run-cron which writes crontab and runs cron in foreground
CMD ["/usr/local/bin/run-cron.sh"]
