#!/usr/bin/bash

# --------------------------
# WordPress Backup Script
# Author: Joseph Yap
# Blog: https://josephyap.me
# --------------------------

# ---------------------------
# Configuration (Modify as Needed)
# ---------------------------

RCLONE_REMOTE="storj-wpbackup:wpbackup/sites/"   # Rclone remote location
WPROOT="/var/www"                                # WordPress installation path
BACKUP_LOG="/var/log/wpbackup.log"               # Log file location
CURRTIME=$(TZ="Asia/Singapore" date +"%Y-%m-%d_%H-%M")  # Timezone and format

# ---------------------------
# Pre-Backup Checks
# ---------------------------

# Check if Rclone is installed
if ! command -v rclone >/dev/null 2>&1; then
  echo "Error: Rclone is not installed or not in your PATH. Please install Rclone." >> "$BACKUP_LOG"
  exit 1
fi

# Test Rclone remote location
if ! rclone ls "$RCLONE_REMOTE" >/dev/null 2>&1; then
  echo "Error: Rclone remote location '$RCLONE_REMOTE' does not exist or is not writable. Aborting." >> "$BACKUP_LOG"
  exit 1
fi

# Ensure WordPress root directory exists
if [ ! -d "$WPROOT" ]; then
  echo "Error: WPROOT directory $WPROOT does not exist." >> "$BACKUP_LOG"
  exit 1
fi

# Check if wp-cli is installed
if ! command -v wp >/dev/null 2>&1; then
  echo "Error: wp-cli command not found. Please install wp-cli to use this script." >> "$BACKUP_LOG"
  exit 1
fi

# Create temporary backup directory
BACKUP_TEMP_PATH=$(mktemp -d)
if [ ! -d "$BACKUP_TEMP_PATH" ]; then
  echo "Error: Failed to create temporary directory." >> "$BACKUP_LOG"
  exit 1
fi

# ---------------------------
# Backup Process
# ---------------------------

# Create array of sites in the WordPress root directory
SITELIST=( $(find "$WPROOT" -maxdepth 1 -type d -exec basename {} \;) )

for SITE in "${SITELIST[@]}"; do
  echo "Backing Up $SITE" >> "$BACKUP_LOG"

  if [ ! -e "$WPROOT/$SITE/wp-config.php" ]; then
    echo "Warning: wp-config.php not found in $WPROOT/$SITE/. Skipping $SITE." >> "$BACKUP_LOG"
    continue
  fi

  cd "$WPROOT/$SITE/htdocs" || { echo "Error: Failed to cd into $WROOT/$SITE/htdocs. Skipping $SITE." >> "$BACKUP_LOG"; continue; }

  if [ ! -e "$BACKUP_TEMP_PATH/$SITE" ]; then
    mkdir -p "$BACKUP_TEMP_PATH/$SITE"
  fi

  # Export database and compress site directory
  wp db export "$WPROOT/$SITE/$CURRTIME-$SITE.sql" --path="$WPROOT/$SITE/htdocs" --allow-root
  tar -C "$WPROOT/$SITE" -cf - . | zstd > "$BACKUP_TEMP_PATH/$SITE/$CURRTIME-$SITE.tar.zst"
  rm "$WPROOT/$SITE/$CURRTIME-$SITE.sql"  # Cleanup

  echo "$(date) - Backup of $SITE completed successfully" >> "$BACKUP_LOG"
done

# ---------------------------
# Remote Transfer (Rclone)
# ---------------------------

cd "$BACKUP_TEMP_PATH/.." || { echo "Error: Failed to cd into $BACKUP_TEMP_PATH/.."; exit 1; }

echo "Total Backup Size: $(du -hs "$BACKUP_TEMP_PATH" | cut -f 1)" >> "$BACKUP_LOG"

echo "Sending backup to remote:" >> "$BACKUP_LOG"
rclone copy "$BACKUP_TEMP_PATH" "$RCLONE_REMOTE" >> "$BACKUP_LOG" 2>&1

# Cleanup temporary directory
rm -r "$BACKUP_TEMP_PATH"

# ---------------------------
# Remote Cleanup (Rclone)
# ---------------------------

echo "Cleaning up old backups:" >> "$BACKUP_LOG"
rclone delete "$RCLONE_REMOTE" --min-age 21d >> "$BACKUP_LOG" 2>&1
