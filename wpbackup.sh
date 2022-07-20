#!/usr/bin/bash
# --------------------------
# WordPress Backup Script
# Author: Joseph Yap
# Blog: https://josephyap.me
# --------------------------

# Save logs
# LOGFILE=$(pwd)/wpbackup.log
# exec > $LOGFILE 2>&1

# WordPress Installation Path
WPROOT=/var/www
#path to create temporary backup folder, must be inside duplicacy initialized folder
BACKUPPATH=/root/wpbackup/sites
#timezone and datetime use for backup file prefix
CURRTIME=$(TZ="Asia/Singapore" date +"%Y-%m-%d_%H-%M")

# Create array() of domains  listed in $WPROOT
SITELIST=()
for DIR in "$WPROOT"/*/ ; do
    DIR2=${DIR%/}
    DIR3=${DIR2##*/}
    if [[ ${DIR3} = *"."* ]]; then
        SITELIST+=( "$DIR3" )
    fi
done

# SITELIST=($(ls -d $WPROOT/* | awk -F '/' '{print $NF}'))

for SITE in "${SITELIST[@]}"; do
    echo Backing Up "$SITE"
    cd "$WPROOT/$SITE/htdocs" || exit
    if [ ! -e "$BACKUPPATH/$SITE" ]; then
        mkdir -p "$BACKUPPATH/$SITE"
    fi

    tar -C "$WPROOT/$SITE" -cf - . | zstd > "$BACKUPPATH/$SITE/$CURRTIME-$SITE.tar.zst"

    wp db export "$BACKUPPATH/$SITE/$CURRTIME-$SITE".sql --path="$WPROOT/$SITE/htdocs" --allow-root
    zstd "$BACKUPPATH/$SITE/$CURRTIME-$SITE".sql -q
    rm "$BACKUPPATH/$SITE/$CURRTIME-$SITE".sql

    
done

# Return to duplicacy directory do backup and remove backup folder when done
cd $BACKUPPATH/.. || exit
echo "Total Backup Size: $(du -hs $BACKUPPATH | cut -f 1)"
duplicacy backup -stats -threads 20
rm -r $BACKUPPATH

# Remove old backup with duplicacy retention policy https://forum.duplicacy.com/t/prune-command-details/1005
duplicacy prune -keep 0:360 -keep 30:180 -keep 7:30 -keep 1:7 -threads 20

# Remove unreference chunks
# duplicacy prune -exhaustive -threads 20
