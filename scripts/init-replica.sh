#!/usr/bin/env bash
set -euo pipefail

# Load env vars
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "ERROR: .env file not found!"
  exit 1
fi

echo ">>> Initiating replica set on container: ${MONGODB_CONTAINER_NAME:-mongo-boilerplate} ..."

docker exec -i "${MONGODB_CONTAINER_NAME:-mongo-boilerplate}" mongosh \
  -u "${MONGO_INITDB_ROOT_USERNAME:-mongo}" \
  -p "${MONGO_INITDB_ROOT_PASSWORD:-password}" \
  --authenticationDatabase admin \
  --eval "
    try {
      rs.initiate({
        _id: 'rs0',
        members: [{ _id: 0, host: 'localhost:27017' }]
      });
    } catch(e) {
      print('Replica set may already be initiated:', e);
    }
    rs.status();
  "

echo ">>> Replica set init attempted. If it was already initiated, you'll see an error above."
