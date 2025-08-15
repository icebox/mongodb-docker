#!/usr/bin/env bash
set -euo pipefail
mkdir -p secrets
umask 177
# 756 random bits; Mongo requires strict perms and ownership for the keyFile.
openssl rand -base64 756 > secrets/mongo-keyfile
chmod 400 secrets/mongo-keyfile


echo "secrets/mongo-keyfile created (chmod 400)."
echo "To use this keyfile, set the environment variable MONGO_KEYFILE_PATH to 'secrets/mongo-keyfile'."
echo "You can also set MONGO_KEYFILE_PATH in your .env file for convenience."
echo "Remember to add 'secrets/mongo-keyfile' to your .gitignore to avoid committing it to version control."
echo "Make sure to secure this keyfile, as it is critical for MongoDB replica set authentication."
echo "You can also use the MONGO_KEYFILE_PATH environment variable in your Docker Compose file to mount the keyfile into the container."
echo "Example Docker Compose snippet:"
echo "  volumes:"
echo "    - ./secrets/mongo-keyfile:/etc/secrets/mongo-keyfile"
echo "  environment:"
echo "    - MONGO_KEYFILE_PATH=/etc/secrets/mongo-keyfile"
echo "This will ensure the keyfile is available inside the MongoDB container with the correct permissions."
echo "Remember to restart your MongoDB container after creating or updating the keyfile." 