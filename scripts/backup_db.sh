#!/bin/bash
set -e

# Configuration
BACKUP_DIR="/tmp/db-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="wordpress_backup_$TIMESTAMP.sql"
S3_BUCKET="${S3_BACKUP_BUCKET}"

# Get RDS endpoint from Terraform output
RDS_ENDPOINT=$(terraform output -raw rds_address)
DB_NAME="${DB_NAME:-wordpress}"
DB_USER="${DB_USER:-admin}"
DB_PASSWORD="${DB_PASSWORD}"

# Create backup directory
mkdir -p $BACKUP_DIR

# Dump database
mysqldump -h $RDS_ENDPOINT -u $DB_USER -p$DB_PASSWORD $DB_NAME > $BACKUP_DIR/$BACKUP_FILE

# Compress backup
gzip $BACKUP_DIR/$BACKUP_FILE

# Upload to S3 (optional)
if [ ! -z "$S3_BUCKET" ]; then
  aws s3 cp $BACKUP_DIR/${BACKUP_FILE}.gz s3://$S3_BUCKET/backups/
  echo "Backup uploaded to S3"
fi

# Clean up old backups (keep last 7 days)
find $BACKUP_DIR -type f -name "*.gz" -mtime +7 -delete

echo "Backup completed: ${BACKUP_FILE}.gz"
