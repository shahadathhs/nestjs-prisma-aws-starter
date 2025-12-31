#!/bin/bash

# =============================================================================
# PostgreSQL Database Backup Script
# =============================================================================
# This script creates automated backups of PostgreSQL database with compression,
# rotation, and optional cloud upload support.

set -euo pipefail

# Configuration from environment variables
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-nestjs_starter_db}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres}"

# Backup configuration
BACKUP_DIR="${BACKUP_DIR:-/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
COMPRESSION="${COMPRESSION:-gzip}"
BACKUP_FORMAT="${BACKUP_FORMAT:-custom}"  # custom, directory, tar, plain

# Cloud storage configuration (optional)
AWS_S3_BUCKET="${AWS_S3_BUCKET:-}"
AWS_S3_PREFIX="${AWS_S3_PREFIX:-database-backups}"
AWS_REGION="${AWS_REGION:-us-east-1}"

# Logging
LOG_FILE="${BACKUP_DIR}/backup.log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.dump"
COMPRESSED_FILE="${BACKUP_FILE}.${COMPRESSION}"

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# Function to cleanup old backups
cleanup_old_backups() {
    log "Cleaning up backups older than ${RETENTION_DAYS} days..."
    find "${BACKUP_DIR}" -name "${DB_NAME}_*.dump*" -type f -mtime +${RETENTION_DAYS} -delete
    log "Cleanup completed."
}

# Function to upload to S3 (optional)
upload_to_s3() {
    if [[ -n "${AWS_S3_BUCKET}" && -n "${AWS_ACCESS_KEY_ID}" && -n "${AWS_SECRET_ACCESS_KEY}" ]]; then
        log "Uploading backup to S3: s3://${AWS_S3_BUCKET}/${AWS_S3_PREFIX}/$(basename "${COMPRESSED_FILE}")"
        
        # Use AWS CLI if available, otherwise skip
        if command -v aws >/dev/null 2>&1; then
            aws s3 cp "${COMPRESSED_FILE}" "s3://${AWS_S3_BUCKET}/${AWS_S3_PREFIX}/$(basename "${COMPRESSED_FILE}")" \
                --region "${AWS_REGION}" \
                --storage-class STANDARD_IA
            
            if [[ $? -eq 0 ]]; then
                log "Successfully uploaded backup to S3."
            else
                log "ERROR: Failed to upload backup to S3."
                return 1
            fi
        else
            log "WARNING: AWS CLI not found. Skipping S3 upload."
        fi
    else
        log "S3 configuration not complete. Skipping cloud upload."
    fi
}

# Function to verify backup integrity
verify_backup() {
    local file="$1"
    log "Verifying backup integrity: ${file}"
    
    # For custom format, we can use pg_restore to verify
    if [[ "${BACKUP_FORMAT}" == "custom" ]]; then
        if command -v pg_restore >/dev/null 2>&1; then
            pg_restore --list "${file}" >/dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                log "Backup verification successful."
                return 0
            else
                log "ERROR: Backup verification failed."
                return 1
            fi
        fi
    fi
    
    # For other formats, check if file exists and has size > 0
    if [[ -f "${file}" && -s "${file}" ]]; then
        log "Backup verification successful (file exists and has content)."
        return 0
    else
        log "ERROR: Backup verification failed (file missing or empty)."
        return 1
    fi
}

# Main backup process
main() {
    log "Starting database backup for ${DB_NAME}..."
    
    # Set PGPASSWORD for pg_dump
    export PGPASSWORD="${DB_PASSWORD}"
    
    # Create database backup
    log "Creating backup: ${BACKUP_FILE}"
    
    case "${BACKUP_FORMAT}" in
        "custom")
            pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" \
                -F custom -f "${BACKUP_FILE}" "${DB_NAME}"
            ;;
        "directory")
            mkdir -p "${BACKUP_FILE}"
            pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" \
                -F directory -f "${BACKUP_FILE}" "${DB_NAME}"
            ;;
        "tar")
            pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" \
                -F tar -f "${BACKUP_FILE}" "${DB_NAME}"
            ;;
        "plain")
            pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" \
                -F plain -f "${BACKUP_FILE}" "${DB_NAME}"
            ;;
        *)
            log "ERROR: Unknown backup format: ${BACKUP_FORMAT}"
            exit 1
            ;;
    esac
    
    # Check if backup was created successfully
    if [[ ! -f "${BACKUP_FILE}" ]]; then
        log "ERROR: Backup file was not created."
        exit 1
    fi
    
    # Compress backup
    log "Compressing backup with ${COMPRESSION}..."
    case "${COMPRESSION}" in
        "gzip")
            gzip "${BACKUP_FILE}"
            ;;
        "bzip2")
            bzip2 "${BACKUP_FILE}"
            ;;
        "xz")
            xz "${BACKUP_FILE}"
            ;;
        *)
            log "WARNING: Unknown compression format. Skipping compression."
            COMPRESSED_FILE="${BACKUP_FILE}"
            ;;
    esac
    
    # Verify backup
    if ! verify_backup "${COMPRESSED_FILE}"; then
        log "ERROR: Backup verification failed. Removing corrupted backup."
        rm -f "${COMPRESSED_FILE}"
        exit 1
    fi
    
    # Get backup size
    BACKUP_SIZE=$(du -h "${COMPRESSED_FILE}" | cut -f1)
    log "Backup created successfully: ${COMPRESSED_FILE} (${BACKUP_SIZE})"
    
    # Upload to cloud if configured
    upload_to_s3
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Clear password
    unset PGPASSWORD
    
    log "Backup process completed successfully."
}

# Error handling
trap 'log "ERROR: Backup script failed at line $LINENO"' ERR

# Run main function
main "$@"
