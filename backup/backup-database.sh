#!/usr/bin/env bash
set -euo pipefail

# Configuration
: "${DB_HOST:=db}"
: "${DB_PORT:=5432}"
: "${DB_USER:=postgres}"
: "${DB_PASSWORD:=postgres}"
: "${DB_NAME:=nestjs_starter_db}"
: "${RETENTION_DAYS:=7}"
: "${BACKUP_FORMAT:=plain}"

AWS_UPLOAD=false
if [[ -n "${AWS_S3_BUCKET:-}" ]]; then
  AWS_UPLOAD=true
  : "${AWS_REGION:=us-east-1}"
  : "${AWS_S3_PREFIX:=backups/db}"
fi

export PGPASSWORD="$DB_PASSWORD"
TIMESTAMP="$(date -u +'%Y-%m-%d_%H-%M-%S')"
FILENAME="${DB_NAME}_${TIMESTAMP}.sql.gz"
BACKUP_DIR="/backups"
BACKUP_PATH="${BACKUP_DIR}/${FILENAME}"

mkdir -p "${BACKUP_DIR}"

echo "$(date -u) [backup] Starting backup for ${DB_NAME} to ${BACKUP_PATH}"

# Choose format
if [ "$BACKUP_FORMAT" = "custom" ]; then
  # custom format: .dump (we still gzip for transport)
  FILENAME="${DB_NAME}_${TIMESTAMP}.dump.gz"
  BACKUP_PATH="${BACKUP_DIR}/${FILENAME}"
  # -Fc = custom format
  pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -F c | gzip > "$BACKUP_PATH"
else
  # plain text SQL dump, gzipped
  pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -F p | gzip > "$BACKUP_PATH"
fi

echo "$(date -u) [backup] Created ${BACKUP_PATH} (size: $(du -h "$BACKUP_PATH" | cut -f1))"

# Upload to S3 if configured
if [ "$AWS_UPLOAD" = true ]; then
  S3_DEST="s3://${AWS_S3_BUCKET}/${AWS_S3_PREFIX}/$(basename "$BACKUP_PATH")"
  echo "$(date -u) [backup] Uploading to ${S3_DEST}"
  aws s3 cp "$BACKUP_PATH" "$S3_DEST" --region "$AWS_REGION" --only-show-errors
  echo "$(date -u) [backup] Upload completed"
fi

# Cleanup local files older than RETENTION_DAYS
echo "$(date -u) [backup] Cleaning local backups older than ${RETENTION_DAYS} days"
find "$BACKUP_DIR" -type f -mtime +"${RETENTION_DAYS}" -print -delete || true

echo "$(date -u) [backup] Done"
