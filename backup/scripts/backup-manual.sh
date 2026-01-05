#!/usr/bin/env bash
set -e

CONTAINER="${PACKAGE_NAME}_backup"

echo "Creating manual backup..."

if docker ps -f name="$CONTAINER" --format "{{.Names}}" | grep -q "$CONTAINER"; then
  docker exec -i "$CONTAINER" /bin/bash -c "/backup/backup-database.sh"
else
  echo "Backup container is not running."
  exit 1
fi
