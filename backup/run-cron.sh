#!/usr/bin/env bash
set -euo pipefail

: "${BACKUP_SCHEDULE:=0 3 * * *}"

# Log file location
LOG_FILE="/var/log/backup/cron.log"
touch "$LOG_FILE"

# Export current environment variables to a file so cron can use them
# We filter out some internal bash/system variables to be clean
declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /backup/container.env

# Write crontab
# We explicitly source the env file before running the script
CRONLINE="$BACKUP_SCHEDULE . /backup/container.env; /backup/backup-database.sh >> $LOG_FILE 2>&1"

echo "$CRONLINE" | crontab -

echo "$(date): Starting cron service..." >> "$LOG_FILE"
echo "Schedule: $BACKUP_SCHEDULE" >> "$LOG_FILE"

# Start cron in foreground
exec cron -f
