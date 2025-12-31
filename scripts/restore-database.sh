#!/bin/bash

# =============================================================================
# PostgreSQL Database Restore Script
# =============================================================================
# This script restores a PostgreSQL database from a backup file.

set -euo pipefail

# Configuration from environment variables
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-nestjs_starter_db}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"

# Backup directory
BACKUP_DIR="${BACKUP_DIR:-/backups}"

# Logging
LOG_FILE="${BACKUP_DIR}/restore.log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# Function to list available backups
list_backups() {
    log "Available backups in ${BACKUP_DIR}:"
    find "${BACKUP_DIR}" -name "${DB_NAME}_*.dump*" -type f -printf "%T@ %p\n" | \
        sort -nr | \
        head -20 | \
        while read timestamp file; do
            local date_str=$(date -d "@${timestamp}" '+%Y-%m-%d %H:%M:%S')
            local size=$(du -h "${file}" | cut -f1)
            echo "  ${date_str} - ${file} (${size})"
        done
}

# Function to restore from backup
restore_backup() {
    local backup_file="$1"
    
    log "Starting database restore from: ${backup_file}"
    
    # Check if backup file exists
    if [[ ! -f "${backup_file}" ]]; then
        log "ERROR: Backup file not found: ${backup_file}"
        exit 1
    fi
    
    # Set PGPASSWORD for pg_restore
    export PGPASSWORD="${DB_PASSWORD}"
    
    # Determine if file is compressed and decompress if needed
    local temp_file="${backup_file}"
    if [[ "${backup_file}" == *.gz ]]; then
        log "Decompressing gzip backup..."
        temp_file="${backup_file%.gz}"
        gunzip -c "${backup_file}" > "${temp_file}"
    elif [[ "${backup_file}" == *.bz2 ]]; then
        log "Decompressing bzip2 backup..."
        temp_file="${backup_file%.bz2}"
        bunzip2 -c "${backup_file}" > "${temp_file}"
    elif [[ "${backup_file}" == *.xz ]]; then
        log "Decompressing xz backup..."
        temp_file="${backup_file%.xz}"
        unxz -c "${backup_file}" > "${temp_file}"
    fi
    
    # Drop existing database (optional - requires confirmation)
    if [[ "${FORCE_RESTORE:-false}" == "true" ]]; then
        log "Dropping existing database..."
        psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -c "DROP DATABASE IF EXISTS ${DB_NAME};"
        log "Creating new database..."
        psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -c "CREATE DATABASE ${DB_NAME};"
    fi
    
    # Restore database
    log "Restoring database..."
    pg_restore -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" \
        -d "${DB_NAME}" \
        --verbose \
        --clean \
        --if-exists \
        --no-acl \
        --no-owner \
        "${temp_file}"
    
    # Clean up temporary decompressed file
    if [[ "${temp_file}" != "${backup_file}" ]]; then
        rm -f "${temp_file}"
    fi
    
    # Clear password
    unset PGPASSWORD
    
    log "Database restore completed successfully."
}

# Function to download backup from S3
download_from_s3() {
    local s3_path="$1"
    local local_file="$2"
    
    log "Downloading backup from S3: ${s3_path}"
    
    if command -v aws >/dev/null 2>&1; then
        aws s3 cp "${s3_path}" "${local_file}" --region "${AWS_REGION:-us-east-1}"
        
        if [[ $? -eq 0 ]]; then
            log "Successfully downloaded backup from S3."
        else
            log "ERROR: Failed to download backup from S3."
            exit 1
        fi
    else
        log "ERROR: AWS CLI not found."
        exit 1
    fi
}

# Main script logic
main() {
    # Create backup directory if it doesn't exist
    mkdir -p "${BACKUP_DIR}"
    
    case "${1:-}" in
        "list")
            list_backups
            ;;
        "restore")
            if [[ -z "${2:-}" ]]; then
                log "ERROR: Please specify a backup file to restore."
                echo "Usage: $0 restore <backup_file>"
                echo "Available backups:"
                list_backups
                exit 1
            fi
            restore_backup "$2"
            ;;
        "restore-s3")
            if [[ -z "${2:-}" ]]; then
                log "ERROR: Please specify S3 path to restore."
                echo "Usage: $0 restore-s3 <s3://bucket/path/to/backup>"
                exit 1
            fi
            
            local backup_file="${BACKUP_DIR}/$(basename "$2")"
            download_from_s3 "$2" "${backup_file}"
            restore_backup "${backup_file}"
            ;;
        *)
            echo "PostgreSQL Database Restore Script"
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  list                    List available backups"
            echo "  restore <backup_file>   Restore from local backup file"
            echo "  restore-s3 <s3_path>   Download and restore from S3"
            echo ""
            echo "Environment Variables:"
            echo "  DB_HOST         Database host (default: localhost)"
            echo "  DB_PORT         Database port (default: 5432)"
            echo "  DB_NAME         Database name (default: nestjs_starter_db)"
            echo "  DB_USER         Database user (default: postgres)"
            echo "  DB_PASSWORD     Database password (default: postgres)"
            echo "  FORCE_RESTORE   Force drop and recreate database (default: false)"
            echo "  BACKUP_DIR      Backup directory (default: /backups)"
            echo "  AWS_REGION      AWS region for S3 operations (default: us-east-1)"
            echo ""
            echo "Examples:"
            echo "  $0 list"
            echo "  $0 restore /backups/nestjs_starter_db_20231231_120000.dump.gz"
            echo "  $0 restore-s3 s3://my-bucket/database-backups/nestjs_starter_db_20231231_120000.dump.gz"
            exit 1
            ;;
    esac
}

# Error handling
trap 'log "ERROR: Restore script failed at line $LINENO"' ERR

# Run main function with all arguments
main "$@"
