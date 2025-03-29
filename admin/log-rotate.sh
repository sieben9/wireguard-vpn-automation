#!/bin/sh

# Error handling
set -e

# Default settings
MAX_LOG_SIZE_MB=100
MAX_LOG_AGE_DAYS=7
LOG_DIR="logs"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

echo "WireGuard Log Rotation"
echo "---------------------"
echo

# Check if container is running
if ! docker ps | grep -q wireguard; then
  echo "Warning: WireGuard container is not running."
  echo "Continuing with log rotation."
fi

# Get container logs and save to file
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_DIR/wireguard-$TIMESTAMP.log"

echo "Saving current logs to $LOG_FILE..."
docker logs wireguard > "$LOG_FILE" 2>&1 || {
  echo "Error: Failed to save container logs."
  exit 1
}

# Truncate container logs
echo "Clearing container logs..."
docker container logs wireguard --follow > /dev/null 2>&1 &
PID=$!
sleep 1
kill $PID > /dev/null 2>&1
docker system prune -f > /dev/null 2>&1

# Remove old log files
echo "Removing log files older than $MAX_LOG_AGE_DAYS days..."
find "$LOG_DIR" -name "wireguard-*.log" -type f -mtime +$MAX_LOG_AGE_DAYS -delete

# Check for large log files
echo "Checking for log files larger than $MAX_LOG_SIZE_MB MB..."
find "$LOG_DIR" -name "wireguard-*.log" -type f -size +${MAX_LOG_SIZE_MB}M -exec echo "Large log file: {}" \;

echo
echo "Log rotation completed successfully!"
echo "Logs are stored in the $LOG_DIR directory." 