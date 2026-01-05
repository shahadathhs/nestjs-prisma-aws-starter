#!/usr/bin/env bash
set -euo pipefail

: "${BACKUP_SCHEDULE:=0 3 * * *}"   # fallback if not set

# Write a crontab line (redirect logs into /var/log/backup/backup.log)
CRONLINE="$BACKUP_SCHEDULE /usr/local/bin/backup.sh >> /var/log/backup/backup.log 2>&1"

# Install crontab
echo "$CRONLINE" | crontab -

# Run an immediate backup once on container start (optional)
# Run in background so cron runs next scheduled job
/usr/local/bin/backup.sh >> /var/log/backup/first-run.log 2>&1 || echo "First run failed, continuing..."

# Start cron in foreground
exec cron -f
