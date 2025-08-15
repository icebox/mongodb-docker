#!/usr/bin/env bash
set -e
mongocli atlas clusters loadSeeds YOUR_CLUSTER_NAME --file seed-data.json
