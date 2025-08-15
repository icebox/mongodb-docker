#!/usr/bin/env bash
set -euo pipefail

# Load env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "ERROR: .env file not found!"
  exit 1
fi

TARGET_URI=${1:-$LOCAL_MONGO_URI}

echo ">>> Seeding MongoDB at $TARGET_URI..."
mongoimport \
  --uri "$TARGET_URI" \
  --collection users \
  --file ./mongo/seeds/users.json \
  --jsonArray

mongoimport \
  --uri "$TARGET_URI" \
  --collection products \
  --file ./mongo/seeds/products.json \
  --jsonArray

echo ">>> Seed completed."
