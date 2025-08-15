#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "ERROR: .env file not found!"
  exit 1
fi

TARGET_URI=${1:-$LOCAL_MONGO_URI}
DATESTAMP=$(date +"%Y%m%d_%H%M%S")
OUT_DIR="./backups/$DATESTAMP"

echo ">>> Backing up MongoDB from $TARGET_URI to $OUT_DIR..."
mkdir -p "$OUT_DIR"

mongodump \
  --uri "$TARGET_URI" \
  --gzip \
  --out "$OUT_DIR"

echo ">>> Backup completed."
