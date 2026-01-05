#!/bin/bash
set -eo pipefail

# Configuration
: "${DB_HOST:=db}"
: "${DB_PORT:=5432}"
: "${DB_NAME:=app_db}"
: "${DB_USER:=postgres}"
: "${DB_PASSWORD:=postgres}"
BACKUP_DIR="/backups"

export PGPASSWORD="${DB_PASSWORD}"

COMMAND="${1:-help}"
ARG2="${2:-}"

function show_help {
    echo "Usage: $0 [command] [arguments]"
    echo ""
    echo "Commands:"
    echo "  list              List available backups"
    echo "  restore <file>    Restore a specific backup file"
    echo "  restore-s3 <url>  Restore from S3 URL"
    echo ""
}

function list_backups {
    echo "Local backups in ${BACKUP_DIR}:"
    ls -lh "${BACKUP_DIR}"
}

function restore_backup {
    local backup_file="$1"
    local local_path=""
    
    if [[ "$backup_file" == s3://* ]]; then
         echo "Downloading from S3: $backup_file..."
         local_path="/tmp/restore_temp_$(date +%s)"
         aws s3 cp "$backup_file" "$local_path"
    else
        # If it's just a filename, assume it's in BACKUP_DIR
        if [[ "$backup_file" != /* ]]; then
            local_path="${BACKUP_DIR}/${backup_file}"
        else
            local_path="$backup_file"
        fi
    fi

    if [ ! -f "$local_path" ]; then
        echo "Error: File $local_path not found."
        exit 1
    fi

    echo "WARNING: This will overwrite database '${DB_NAME}' on '${DB_HOST}'."
    if [ "${FORCE_RESTORE:-false}" != "true" ]; then
        echo "Set FORCE_RESTORE=true to skip this confirmation, otherwise interactive mode required."
        # In non-interactive environments, we should probably fail if not forced.
        # But for 'make backup-restore' it's interactive.
    fi

    echo "Dropping and recreating database ${DB_NAME}..."
    # Terminate connections first (optional but good practice)
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}' AND pid <> pg_backend_pid();" >/dev/null 2>&1 || true
    
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS \"${DB_NAME}\";"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE \"${DB_NAME}\";"

    echo "Restoring from $local_path..."

    # Determine type based on extension
    if [[ "$local_path" == *.sql.gz ]]; then
        echo "Format: Plain SQL (gzipped)"
        gunzip -c "$local_path" | psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"
    elif [[ "$local_path" == *.sql ]]; then
        echo "Format: Plain SQL"
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" < "$local_path"
    else
        # Assume custom format (pg_dump -Fc) which pg_restore handles (it can handle compressed custom format directly if it's the file)
        # Note: If we gzipped the .dump file (as backup script does .dump.gz), pg_restore might not handle .gz directly depending on version, 
        # normally pg_restore -h host -d db filename 
        # If it is .gz, we might need to gunzip it.
        
        if [[ "$local_path" == *.gz ]]; then
             echo "Format: Custom/Tar (gzipped)"
             # For pg_restore with custom format compressed with gzip, we can pipe strictly OR unzip first.
             # pg_restore can read from stdin.
             gunzip -c "$local_path" | pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" --clean --if-exists
        else
             echo "Format: Custom/Tar (uncompressed or native)"
             pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" --clean --if-exists "$local_path"
        fi
    fi

    echo "Restore complete."
    
    # Cleanup temp file if s3
    if [[ "$backup_file" == s3://* ]]; then
        rm "$local_path"
    fi
}

case "$COMMAND" in
    list)
        list_backups
        ;;
    restore)
        if [ -z "$ARG2" ]; then
            echo "Error: Missing backup filename."
            show_help
            exit 1
        fi
        restore_backup "$ARG2"
        ;;
    restore-s3)
        if [ -z "$ARG2" ]; then
            echo "Error: Missing S3 URL."
            show_help
            exit 1
        fi
        restore_backup "$ARG2"
        ;;
    *)
        show_help
        exit 1
        ;;
esac
