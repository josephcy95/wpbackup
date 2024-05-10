#!/usr/bin/bash

# --------------------------
# Simple bash script to run wp cron for multiple sites installed with wordops
# --------------------------

# ---------------------------
# Configuration (Modify as Needed)
# ---------------------------

WPROOT="/var/www"                                # WordPress installation path
WPCRON_LOG="/var/log/wpcron.log"               # Log file location
CURRTIME=$(TZ="Asia/Singapore" date +"%Y-%m-%d_%H-%M")  # Timezone and format

# ---------------------------
# Pre-run check
# ---------------------------


# Ensure WordPress root directory exists
if [ ! -d "$WPROOT" ]; then
  echo "Error: WPROOT directory $WPROOT does not exist." >> "$WPCRON_LOG"
  exit 1
fi

# Check if wp-cli is installed
if ! command -v wp >/dev/null 2>&1; then
  echo "Error: wp-cli command not found. Please install wp-cli to use this script." >> "$WPCRON_LOG"
  exit 1
fi

# ---------------------------
# Run wp cron for all sites
# ---------------------------

# Create array of sites in the WordPress root directory
SITELIST=( $(find "$WPROOT" -maxdepth 1 -type d -exec basename {} \;) )

for SITE in "${SITELIST[@]}"; do

  # Skip non wordpress site with wordops
  if [ ! -e "$WPROOT/$SITE/wp-config.php" ]; then
    echo "Warning: wp-config.php not found in $WPROOT/$SITE/. Skipping $SITE." >> "$WPCRON_LOG"
    continue
  fi

  # Run Wp cron
  echo "Running WP Cron for $SITE" >> "$WPCRON_LOG"
  wp cron event run --due-now --path="$WPROOT/$SITE/htdocs" --allow-root >> "$WPCRON_LOG"
done