#!/usr/bin/env bash
set -euo pipefail

# === Load env vars from .env ===
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "ERROR: .env file not found!"
  exit 1
fi

# Default if not set
MONGODB_CONTAINER_NAME="${MONGODB_CONTAINER_NAME}"

echo ">>> Stopping and removing container + volumes..."
docker compose down -v

echo ">>> Rebuilding image..."
docker compose build --no-cache

echo ">>> Starting fresh container..."
docker compose up -d

echo ">>> Waiting for MongoDB to accept connections..."
for i in {1..30}; do
  if docker exec "${MONGODB_CONTAINER_NAME}" mongosh --quiet --eval 'db.runCommand({ ping: 1 }).ok' >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo ">>> Initiating replica set..."
docker exec "${MONGODB_CONTAINER_NAME}" mongosh --quiet --eval \
  "rs.initiate({ _id: \"${MONGO_REPLICA_SET_NAME:-rs0}\", members: [{ _id: 0, host: \"localhost:27017\" }] })"

echo ">>> Creating root user..."
docker exec "${MONGODB_CONTAINER_NAME}" mongosh --quiet --eval \
  "db.getSiblingDB('admin').createUser({
     user: '${MONGO_INITDB_ROOT_USERNAME:-mongo}',
     pwd: '${MONGO_INITDB_ROOT_PASSWORD:-password}',
     roles: [{ role: 'root', db: 'admin' }]
   })"

echo ">>> Creating app user..."
docker exec "${MONGODB_CONTAINER_NAME}" mongosh --quiet -u "${MONGO_INITDB_ROOT_USERNAME:-mongo}" -p "${MONGO_INITDB_ROOT_PASSWORD:-password}" --authenticationDatabase admin --eval \
  "db.getSiblingDB('${MONGO_DB_NAME:-appdb}').createUser({
     user: '${MONGO_APP_USERNAME:-appuser}',
     pwd: '${MONGO_APP_PASSWORD:-password}',
     roles: [{ role: 'readWrite', db: '${MONGO_DB_NAME:-appdb}' }]
   })"

echo ">>> Checking replica set state..."
docker exec "${MONGODB_CONTAINER_NAME}" mongosh --quiet -u "${MONGO_INITDB_ROOT_USERNAME:-mongo}" -p "${MONGO_INITDB_ROOT_PASSWORD:-password}" --authenticationDatabase admin --eval 'rs.status().myState'

echo ">>> DONE. You can now connect via Compass with:"
echo "    mongodb://${MONGO_APP_USERNAME:-appuser}:${MONGO_APP_PASSWORD:-password}@localhost:27017/${MONGO_DB_NAME:-appdb}?authSource=admin&replicaSet=${MONGO_REPLICA_SET_NAME:-rs0}"
echo ">>> Or via mongosh with:"
echo "    mongosh mongodb://${MONGO_APP_USERNAME}:${MONGO_APP_PASSWORD}@localhost:27017/${MONGO_DB_NAME}?authSource=admin&replicaSet=${MONGO_REPLICA_SET_NAME}"
echo ">>> Enjoy your MongoDB development environment!"
echo ">>> To reset, run: ./reset-mongo-dev.sh"
echo ">>> To stop, run: docker compose down"
echo ">>> To remove volumes, run: docker compose down -v"
echo ">>> To rebuild without cache, run: docker compose build --no-cache"
echo ">>> To start fresh, run: docker compose up -d"
echo ">>> For more info, visit: