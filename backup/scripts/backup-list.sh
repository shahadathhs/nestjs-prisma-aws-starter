#!/usr/bin/env bash
set -e

CONTAINER="${PACKAGE_NAME}_backup"

echo "Available backups:"

if docker ps -f name="$CONTAINER" --format "{{.Names}}" | grep -q "$CONTAINER"; then
  docker exec -i "$CONTAINER" /bin/bash -c "/backup/restore-database.sh list"
else
  echo "Backup container is not running."
  exit 1
fi
