#!/usr/bin/env bash
# =============================================================================
# Gulflands Database Backup Script
# Usage: ./scripts/backup.sh [--prune-after-days N]
# Requires: MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE env vars
# =============================================================================
set -euo pipefail

# --- Configuration ---
BACKUP_DIR="${BACKUP_DIR:-/var/backups/gulflands}"
PRUNE_DAYS="${1:-7}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/gulflands_${TIMESTAMP}.sql.gz"
LOG_FILE="${BACKUP_DIR}/backup.log"

# Required environment variables
: "${MYSQL_HOST:?MYSQL_HOST is not set}"
: "${MYSQL_USER:?MYSQL_USER is not set}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is not set}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE is not set}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

# --- Create backup directory if not exists ---
mkdir -p "${BACKUP_DIR}"

log "Starting backup of database '${MYSQL_DATABASE}' on host '${MYSQL_HOST}'"

# --- Run mysqldump (piped directly into gzip, no plaintext on disk) ---
MYSQL_PWD="${MYSQL_PASSWORD}" mysqldump \
    --host="${MYSQL_HOST}" \
    --user="${MYSQL_USER}" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --set-gtid-purged=OFF \
    --hex-blob \
    --max_allowed_packet=64M \
    "${MYSQL_DATABASE}" \
    | gzip -9 > "${BACKUP_FILE}"

BACKUP_SIZE=$(du -sh "${BACKUP_FILE}" | cut -f1)
log "Backup complete: ${BACKUP_FILE} (${BACKUP_SIZE})"

# --- Optional: Upload to S3 ---
if [[ -n "${S3_BUCKET:-}" ]]; then
    log "Uploading to s3://${S3_BUCKET}/backups/$(basename ${BACKUP_FILE})"
    aws s3 cp "${BACKUP_FILE}" "s3://${S3_BUCKET}/backups/$(basename ${BACKUP_FILE})" \
        --storage-class STANDARD_IA
    log "S3 upload complete"
fi

# --- Prune old local backups ---
log "Pruning backups older than ${PRUNE_DAYS} days"
find "${BACKUP_DIR}" -name "gulflands_*.sql.gz" -mtime "+${PRUNE_DAYS}" -delete

log "Backup job finished successfully"
