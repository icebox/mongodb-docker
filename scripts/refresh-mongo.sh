#!/usr/bin/env bash
set -euo pipefail

echo ">>> Restarting MongoDB container (keeping data)..."
docker compose down
docker compose up -d

echo ">>> Waiting for MongoDB to accept connections..."
for i in {1..30}; do
  if docker exec "${MONGODB_CONTAINER_NAME}" mongosh --quiet \
    -u "${MONGO_INITDB_ROOT_USERNAME}" \
    -p "${MONGO_INITDB_ROOT_PASSWORD}" \
    --authenticationDatabase admin \
    --eval 'db.runCommand({ ping: 1 }).ok' >/dev/null 2>&1; then
    echo "MongoDB is ready."
    exit 0
  fi
  sleep 1
done

echo "ERROR: MongoDB did not become ready in time."
exit 1
