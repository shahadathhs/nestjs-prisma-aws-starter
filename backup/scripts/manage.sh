#!/usr/bin/env bash
set -e

# Configuration
CONTAINER="${PACKAGE_NAME}_backup"
COMMAND="${1:-help}"

# Check if container is running
if ! docker ps -f name="$CONTAINER" --format "{{.Names}}" | grep -q "$CONTAINER"; then
  echo "Error: Backup container '$CONTAINER' is not running."
  echo "Please start the stack first (make start or make dev-up)."
  exit 1
fi

function show_help {
  echo "Usage: $0 [list|create|restore]"
}

case "$COMMAND" in
  list)
    echo "Available backups (inside $CONTAINER):"
    docker exec -i "$CONTAINER" /backup/scripts/restore-database.sh list
    ;;

  create)
    echo "Triggering manual backup in $CONTAINER..."
    docker exec -i "$CONTAINER" /backup/scripts/backup-database.sh
    ;;

  restore)
    echo "Available backups:"
    docker exec -i "$CONTAINER" /backup/scripts/restore-database.sh list
    echo ""
    printf "Enter backup filename to restore: "
    read -r backup_file

    if [ -z "$backup_file" ]; then
      echo "No file selected. Cancelled."
      exit 0
    fi

    printf "WARNING: This will replace the current database. Are you sure? [y/N] "
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      docker exec -i "$CONTAINER" /bin/bash -c "FORCE_RESTORE=true /backup/scripts/restore-database.sh restore $backup_file"
      echo "Restore operation finished."
    else
      echo "Restore cancelled."
    fi
    ;;

  *)
    show_help
    exit 1
    ;;
esac
