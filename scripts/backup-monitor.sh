#!/bin/bash

# =============================================================================
# Backup Monitoring and Notification Script
# =============================================================================
# This script monitors backup operations and sends notifications.

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/backups}"
LOG_FILE="${BACKUP_DIR}/monitor.log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Notification settings
NOTIFICATION_EMAIL="${NOTIFICATION_EMAIL:-}"
SMTP_HOST="${SMTP_HOST:-}"
SMTP_PORT="${SMTP_PORT:-587}"
SMTP_USER="${SMTP_USER:-}"
SMTP_PASS="${SMTP_PASS:-}"

# Monitoring thresholds
MAX_BACKUP_SIZE_MB="${MAX_BACKUP_SIZE_MB:-1000}"  # Alert if backup exceeds this size
MIN_BACKUPS_COUNT="${MIN_BACKUPS_COUNT:-1}"       # Alert if fewer than this many backups
MAX_BACKUP_AGE_HOURS="${MAX_BACKUP_AGE_HOURS:-48}" # Alert if oldest backup is older than this

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# Function to send email notification
send_notification() {
    local subject="$1"
    local message="$2"
    
    if [[ -n "${NOTIFICATION_EMAIL}" && -n "${SMTP_HOST}" && -n "${SMTP_USER}" && -n "${SMTP_PASS}" ]]; then
        log "Sending notification to ${NOTIFICATION_EMAIL}: ${subject}"
        
        # Create email content
        local email_content="Subject: ${subject}
From: Backup Monitor <${SMTP_USER}>
To: ${NOTIFICATION_EMAIL}

${message}

---
Backup Monitor
$(date '+%Y-%m-%d %H:%M:%S')
"
        
        # Send email using sendmail or curl
        if command -v sendmail >/dev/null 2>&1; then
            echo "${email_content}" | sendmail -t
        elif command -v curl >/dev/null 2>&1; then
            curl -s --url "smtp://${SMTP_HOST}:${SMTP_PORT}" \
                --mail-from "${SMTP_USER}" \
                --mail-rcpt "${NOTIFICATION_EMAIL}" \
                --user "${SMTP_USER}:${SMTP_PASS}" \
                --ssl-reqd \
                -T <(echo -e "Subject: ${subject}\n\n${message}")
        else
            log "WARNING: No email sending method available. Notification not sent."
            return 1
        fi
        
        if [[ $? -eq 0 ]]; then
            log "Notification sent successfully."
        else
            log "ERROR: Failed to send notification."
            return 1
        fi
    else
        log "Email notification not configured. Skipping notification."
    fi
}

# Function to check backup health
check_backup_health() {
    log "Starting backup health check..."
    
    local alerts=0
    local alert_messages=""
    
    # Check if backup directory exists
    if [[ ! -d "${BACKUP_DIR}" ]]; then
        local msg="CRITICAL: Backup directory does not exist: ${BACKUP_DIR}"
        log "${msg}"
        send_notification "Backup Directory Missing" "${msg}"
        return 1
    fi
    
    # Count backups
    local backup_count=$(find "${BACKUP_DIR}" -name "*_*.dump*" -type f | wc -l)
    log "Found ${backup_count} backup files."
    
    if [[ ${backup_count} -lt ${MIN_BACKUPS_COUNT} ]]; then
        local msg="WARNING: Only ${backup_count} backups found (minimum: ${MIN_BACKUPS_COUNT})"
        log "${msg}"
        alert_messages="${alert_messages}${msg}\n"
        ((alerts++))
    fi
    
    # Check backup sizes
    find "${BACKUP_DIR}" -name "*_*.dump*" -type f -printf "%s %p\n" | while read size file; do
        local size_mb=$((size / 1024 / 1024))
        if [[ ${size_mb} -gt ${MAX_BACKUP_SIZE_MB} ]]; then
            local msg="WARNING: Large backup detected: $(basename "${file}") (${size_mb}MB)"
            log "${msg}"
            alert_messages="${alert_messages}${msg}\n"
            ((alerts++))
        fi
    done
    
    # Check backup ages
    local oldest_backup=$(find "${BACKUP_DIR}" -name "*_*.dump*" -type f -printf "%T@ %p\n" | sort -n | head -1 | cut -d' ' -f2-)
    if [[ -n "${oldest_backup}" ]]; then
        local backup_age_seconds=$(($(date +%s) - $(stat -c %Y "${oldest_backup}")))
        local backup_age_hours=$((backup_age_seconds / 3600))
        
        if [[ ${backup_age_hours} -gt ${MAX_BACKUP_AGE_HOURS} ]]; then
            local msg="WARNING: Oldest backup is ${backup_age_hours} hours old: $(basename "${oldest_backup}")"
            log "${msg}"
            alert_messages="${alert_messages}${msg}\n"
            ((alerts++))
        fi
    fi
    
    # Check recent backup operations
    local recent_logs=$(find "${BACKUP_DIR}" -name "backup.log" -newermt "24 hours ago" | wc -l)
    if [[ ${recent_logs} -eq 0 ]]; then
        local msg="WARNING: No backup activity in the last 24 hours"
        log "${msg}"
        alert_messages="${alert_messages}${msg}\n"
        ((alerts++))
    fi
    
    # Send summary notification if there are alerts
    if [[ ${alerts} -gt 0 ]]; then
        local subject="Backup Health Alert - ${alerts} issues detected"
        local message="Backup health check completed with ${alerts} issues:\n\n${alert_messages}\nPlease review the backup system."
        send_notification "${subject}" "${message}"
        log "Health check completed with ${alerts} alerts."
    else
        log "Health check completed successfully - no issues detected."
    fi
    
    return ${alerts}
}

# Function to generate backup report
generate_backup_report() {
    log "Generating backup report..."
    
    local report_file="${BACKUP_DIR}/backup_report_${TIMESTAMP}.txt"
    
    cat > "${report_file}" << EOF
Backup System Report
====================
Generated: $(date '+%Y-%m-%d %H:%M:%S')

Backup Directory: ${BACKUP_DIR}

Backup Files Summary:
--------------------
$(find "${BACKUP_DIR}" -name "*_*.dump*" -type f -exec ls -lh {} \; | awk '{print $5, $9}')

Total Backups: $(find "${BACKUP_DIR}" -name "*_*.dump*" -type f | wc -l)

Total Size: $(du -sh "${BACKUP_DIR}"/*_*.dump* 2>/dev/null | awk '{sum+=$1} END {print sum "B"}' || echo "N/A")

Recent Backup Activity:
-----------------------
$(tail -20 "${BACKUP_DIR}/backup.log" 2>/dev/null || echo "No backup log found")

Disk Usage:
-----------
df -h "${BACKUP_DIR}" 2>/dev/null || echo "Unable to get disk usage"

Configuration:
-------------
Retention Days: ${RETENTION_DAYS:-7}
Compression: ${COMPRESSION:-gzip}
Backup Format: ${BACKUP_FORMAT:-custom}
Schedule: ${BACKUP_SCHEDULE:-0 2 * * *}

EOF
    
    log "Backup report generated: ${report_file}"
    
    # Send report if email is configured
    if [[ -n "${NOTIFICATION_EMAIL}" ]]; then
        send_notification "Backup System Report" "Backup system report is attached.\n\n$(cat "${report_file}")"
    fi
}

# Main function
main() {
    case "${1:-check}" in
        "check")
            check_backup_health
            ;;
        "report")
            generate_backup_report
            ;;
        "help")
            echo "Backup Monitoring Script"
            echo "Usage: $0 <command>"
            echo ""
            echo "Commands:"
            echo "  check     Check backup health and send alerts"
            echo "  report    Generate detailed backup report"
            echo "  help      Show this help"
            echo ""
            echo "Environment Variables:"
            echo "  BACKUP_DIR              Backup directory (default: /backups)"
            echo "  NOTIFICATION_EMAIL      Email address for notifications"
            echo "  SMTP_HOST               SMTP server hostname"
            echo "  SMTP_PORT               SMTP server port (default: 587)"
            echo "  SMTP_USER               SMTP username"
            echo "  SMTP_PASS               SMTP password"
            echo "  MAX_BACKUP_SIZE_MB      Alert threshold for backup size (default: 1000)"
            echo "  MIN_BACKUPS_COUNT       Minimum number of backups required (default: 1)"
            echo "  MAX_BACKUP_AGE_HOURS    Maximum age for oldest backup (default: 48)"
            ;;
        *)
            echo "Unknown command: ${1}"
            echo "Use '$0 help' for usage information."
            exit 1
            ;;
    esac
}

# Error handling
trap 'log "ERROR: Monitor script failed at line $LINENO"' ERR

# Run main function
main "$@"
