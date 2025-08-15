#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <backup_dir> [target_uri]"
  exit 1
fi

BACKUP_DIR="$1"
TARGET_URI=${2:-$LOCAL_MONGO_URI}

if [ ! -d "$BACKUP_DIR" ]; then
  echo "ERROR: Backup directory '$BACKUP_DIR' not found!"
  exit 1
fi

echo ">>> Restoring backup from $BACKUP_DIR to $TARGET_URI..."
mongorestore \
  --uri "$TARGET_URI" \
  --gzip \
  --drop \
  "$BACKUP_DIR"

echo ">>> Restore completed."
