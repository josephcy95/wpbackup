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
ADD_DISABLE_WP_CRON=true                        # Add DISABLE_WP_CRON if not defined

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

# Add a divider line and timestamp to the log file
echo -e "\n==========================\nWP Cron Run: $CURRTIME\n==========================" >> "$WPCRON_LOG"

# Create array of sites in the WordPress root directory
SITELIST=( $(find "$WPROOT" -maxdepth 1 -type d -exec basename {} \;) )

for SITE in "${SITELIST[@]}"; do

  # Skip non-WordPress sites with WordOps
  if [ ! -e "$WPROOT/$SITE/wp-config.php" ]; then
    echo "Warning: wp-config.php not found in $WPROOT/$SITE/. Skipping $SITE." >> "$WPCRON_LOG"
    continue
  fi

  # Check if DISABLE_WP_CRON is not defined in wp-config.php (case insensitive)
  if ! grep -qi "define('DISABLE_WP_CRON', true);" "$WPROOT/$SITE/wp-config.php"; then
    if [ "$ADD_DISABLE_WP_CRON" = true ]; then
      echo "Adding DISABLE_WP_CRON to wp-config.php for $SITE." >> "$WPCRON_LOG"

      # Add the line to wp-config.php
      sed -i "/Add any custom values between this line/a\\n\ndefine('DISABLE_WP_CRON', true);\n" "$WPROOT/$SITE/wp-config.php"
    else
      echo "DISABLE_WP_CRON is not defined in wp-config.php for $SITE. Skipping WP Cron." >> "$WPCRON_LOG"
      continue
    fi
  fi

  # Run Wp cron
  echo "Running WP Cron for $SITE" >> "$WPCRON_LOG"
  wp cron event run --due-now --path="$WPROOT/$SITE/htdocs" --allow-root >> "$WPCRON_LOG"
done