#!/usr/bin/bash
# --------------------------
# WordPress Backup Script
# Author: Joseph Yap
# Blog: https://josephyap.me
# --------------------------

# WordPress Installation Path
WPROOT="/var/www"
# Path to create temporary backup folder; must be inside a duplicacy initialized folder
BACKUPPATH="/root/wpbackup/sites"
# Timezone and datetime used for backup file prefix
CURRTIME=$(TZ="Asia/Singapore" date +"%Y-%m-%d_%H-%M")

# Ensure WPROOT and BACKUPPATH Directories Exist
[ ! -d "$WPROOT" ] && { echo "Error: WPROOT directory $WPROOT does not exist."; exit 1; }
[ ! -d "$BACKUPPATH" ] && mkdir -p "$BACKUPPATH"

# Check for wp and duplicacy commands
command -v wp >/dev/null 2>&1 || { echo >&2 "Error: wp command not found. Aborting."; exit 1; }

# Create array of domains listed in $WPROOT
SITELIST=( $(find "$WPROOT" -maxdepth 1 -type d -exec basename {} \;) )

for SITE in "${SITELIST[@]}"; do
    echo "Backing Up $SITE"
    if [ ! -e "$WPROOT/$SITE/wp-config.php" ]; then
        echo "Warning: wp-config.php not found in $WPROOT/$SITE/. Skipping $SITE."
        continue
    fi

    cd "$WPROOT/$SITE/htdocs" || { echo "Error: Failed to cd into $WPROOT/$SITE/htdocs. Skipping $SITE."; continue; }
    if [ ! -e "$BACKUPPATH/$SITE" ]; then
        mkdir -p "$BACKUPPATH/$SITE"
    fi

    tar -C "$WPROOT/$SITE" -cf - . | zstd > "$BACKUPPATH/$SITE/$CURRTIME-$SITE.tar.zst"
    wp db export "$BACKUPPATH/$SITE/$CURRTIME-$SITE.sql" --path="$WPROOT/$SITE/htdocs" --allow-root
    zstd "$BACKUPPATH/$SITE/$CURRTIME-$SITE.sql" -q
    rm "$BACKUPPATH/$SITE/$CURRTIME-$SITE.sql"
done

# Return to duplicacy directory, do backup, and remove backup folder when done
cd "$BACKUPPATH/.." || { echo "Error: Failed to cd into $BACKUPPATH/.."; exit 1; }
echo "Total Backup Size: $(du -hs "$BACKUPPATH" | cut -f 1)"
rclone copy /root/wpbackup/sites storj-wpbackup:wpbackup/sites/
rm -r "$BACKUPPATH"

# Remove old backup with duplicacy retention policy
rclone delete storj-wpbackup:wpbackup/sites/ --min-age 21d
