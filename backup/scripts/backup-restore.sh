#!/usr/bin/env bash
set -e

CONTAINER="${PACKAGE_NAME}_backup"

echo "Available backups:"
docker exec -i "$CONTAINER" /bin/bash -c "/backup/restore-database.sh list"
echo ""

printf "Enter backup filename to restore: "
read filename

if [[ -z "$filename" ]]; then
  echo "No file entered. Cancelled."
  exit 0
fi

printf "This will replace the database. Confirm? [y/N] "
read confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Restore cancelled."
  exit 0
fi

docker exec -i "$CONTAINER" /bin/bash -c "FORCE_RESTORE=true /backup/restore-database.sh restore $filename"
echo "Restore completed."
