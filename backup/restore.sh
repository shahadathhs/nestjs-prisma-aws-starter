#!/bin/sh

set -e

######## CONFIG ########
DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"
BACKUP_FILE_PATH="$1"   # Provided by user: /backups/file.dump or s3://...

export PGPASSWORD="${DB_PASSWORD}"
########################

if [ -z "$BACKUP_FILE_PATH" ]; then
  echo "❌ ERROR: No backup file provided."
  echo "Usage: ./restore.sh /backups/myfile.dump"
  exit 1
fi

LOCAL_FILE="/tmp/restore.dump"

############ S3 DOWNLOAD IF NEEDED ############
if echo "$BACKUP_FILE_PATH" | grep -q "^s3://"; then
  echo "📥 Downloading from S3: $BACKUP_FILE_PATH"
  aws s3 cp "$BACKUP_FILE_PATH" "$LOCAL_FILE"
else
  echo "📄 Using local backup: $BACKUP_FILE_PATH"
  cp "$BACKUP_FILE_PATH" "$LOCAL_FILE"
fi

if [ ! -f "$LOCAL_FILE" ]; then
  echo "❌ ERROR: Backup file not found."
  exit 1
fi
###############################################


echo "🗑 Dropping database $DB_NAME..."
psql -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -c "DROP DATABASE IF EXISTS $DB_NAME;"

echo "📦 Creating new database..."
psql -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" -c "CREATE DATABASE $DB_NAME;"

echo "⏳ Restoring backup..."
pg_restore -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" \
  -d "$DB_NAME" --clean --if-exists \
  "$LOCAL_FILE"

echo "🎉 Restore completed successfully!"
