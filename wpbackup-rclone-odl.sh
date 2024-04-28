#!/usr/bin/bash
# --------------------------
# WordPress Backup Script
# Author: Joseph Yap
# Blog: https://josephyap.me
# --------------------------

# Logging
BACKUP_LOG="/var/log/wpbackup.log"
# WordPress Installation Path
WPROOT="/var/www"
# Path to create temporary backup folder; must be inside a duplicacy initialized folder
BACKUP_TEMP_PATH="/root/wpbackup/sites"
# Timezone and datetime used for backup file prefix
CURRTIME=$(TZ="Asia/Singapore" date +"%Y-%m-%d_%H-%M")

# Ensure WPROOT and BACKUP_TEMP_PATH Directories Exist
[ ! -d "$WPROOT" ] && { echo "Error: WPROOT directory $WPROOT does not exist."; exit 1; }
[ ! -d "$BACKUP_TEMP_PATH" ] && mkdir -p "$BACKUP_TEMP_PATH"

# Check if wp CLI installed
command -v wp >/dev/null 2>&1 || { echo >&2 "Error: wp-cli command not found. Please install wp-cli to use this script.."; exit 1; }

# Create array of domains listed in $WPROOT
SITELIST=( $(find "$WPROOT" -maxdepth 1 -type d -exec basename {} \;) )

for SITE in "${SITELIST[@]}"; do
    echo "Backing Up $SITE"
	echo "Backing Up $SITE" >> "$BACKUP_LOG"
    if [ ! -e "$WPROOT/$SITE/wp-config.php" ]; then
        echo "Warning: wp-config.php not found in $WPROOT/$SITE/. Skipping $SITE."
        continue
    fi

    cd "$WPROOT/$SITE/htdocs" || { echo "Error: Failed to cd into $WPROOT/$SITE/htdocs. Skipping $SITE."; continue; }
    if [ ! -e "$BACKUP_TEMP_PATH/$SITE" ]; then
        mkdir -p "$BACKUP_TEMP_PATH/$SITE"
    fi

    # Export database, tarball site directory, compress and save to temporary backup directory
    wp db export "$WPROOT/$SITE/$CURRTIME-$SITE.sql" --path="$WPROOT/$SITE/htdocs" --allow-root
    tar -C "$WPROOT/$SITE" -cf - . | zstd > "$BACKUP_TEMP_PATH/$SITE/$CURRTIME-$SITE.tar.zst"
	rm "$WPROOT/$SITE/$CURRTIME-$SITE.sql"  # Cleanup .sql file after backup each site
	
	# Successful backup message
	echo "$(date) - Backup of $SITE completed successfully" >> "$BACKUP_LOG"
done

# Return to duplicacy directory, do backup, and remove backup folder when done
cd "$BACKUP_TEMP_PATH/.." || { echo "Error: Failed to cd into $BACKUP_TEMP_PATH/.."; exit 1; }
echo "Total Backup Size: $(du -hs "$BACKUP_TEMP_PATH" | cut -f 1)"
rclone copy "$BACKUP_TEMP_PATH" storj-wpbackup:wpbackup/sites/
rm -r "$BACKUP_TEMP_PATH"

# Remove old backup with duplicacy retention policy
rclone delete storj-wpbackup:wpbackup/sites/ --min-age 21d
