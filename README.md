# MongoDB (Docker + Replica Set + Auth)

This project sets up a **MongoDB 8.0.x** instance in Docker for local development with:

- **Authentication** (root + app user)
- **Replica set** enabled for transactions and change streams
- **Persistent data** via Docker volume
- Helper scripts for reset/restart workflows

---

## 📂 Project Structure

```
.
├── Dockerfile.dev
├── docker-compose.yml
├── mongo/
│   ├── mongod.dev.conf                # MongoDB config (auth + replSet)
│   └── init/
│       └── 00-replica-init.js          # JS script: init RS, create users
├── scripts/
│   ├── gen-keyfile.sh                  # Create secure keyfile for internal auth
│   ├── reset-mongo-dev.sh              # Wipe data, rebuild, fresh RS+users
│   └── refresh-mongo.sh                # Restart container without wiping data
├── secrets/
│   └── mongo-keyfile                   # Generated keyfile (gitignored)
├── .env                                # Env vars for credentials/config
└── README.md
```

---

## ⚙️ Configuration

### `.env`

Create `.env` in the project root:

```env
MONGO_INITDB_ROOT_USERNAME=mongo
MONGO_INITDB_ROOT_PASSWORD=change_me_admin_pw
MONGO_DB_NAME=appdb
MONGO_APP_USERNAME=appuser
MONGO_APP_PASSWORD=super_secret_password_change_me
MONGO_REPLICA_SET_NAME=rs0
MONGO_PORT=27017
```

---

## 🛠 Setup Steps

### 1. Generate Keyfile

```bash
chmod +x scripts/gen-keyfile.sh
./scripts/gen-keyfile.sh
```

This creates `secrets/mongo-keyfile` with correct perms for internal replica set auth.

---

### 2. Build & Run for the First Time

```bash
docker compose up -d --build
```

This:

- Starts Mongo with `mongod.dev.conf`
- Mounts init scripts from `mongo/init/`
- On empty DB, `00-replica-init.js` runs:
  - Initiates replica set
  - Creates root + app user


NOTE: `00-replica-init.js` script might fail if it tries to run before Mongo is ready to receive connections. If that happens, follow the steps below: 

### 2b. Init Replica set

Start the container 

```
docker compose up -d
```

Then run the `init-replica.sh` script

```
./scripts/init-replica.sh
```

OR: 

### 2c. Manually initialize

Run this inside the container, as root user:

```
docker exec -it mongo-boilerplate mongosh -u mongo -p --authenticationDatabase admin
```

Then at the mongosh prompt:
```
rs.initiate({
  _id: 'rs0',
  members: [{ _id: 0, host: 'localhost:27017' }]
})
```

Then check:
```
rs.status()
```

myState should be 1 for PRIMARY.

Once this is done, try again from host:

```
mongosh "mongodb://mongo:<your_password>@localhost:27017/appdb?authSource=admin&replicaSet=rs0"
```

It should connect instantly.

---

## Common Workflows

### **🚀 Running Local Dev Mongo**

```bash
docker compose up -d
```

- Starts MongoDB with existing data.

---
### **Reset DB completely** (wipe data + rebuild + re-init RS/users)

```bash
./scripts/reset-mongo-dev.sh
```

- Runs `docker compose down -v` → deletes `mongo_data_dev` volume.
- Forces RS initiation and user creation.
- **Use when** you want a clean slate.

---

### **Restart MongoDB but keep data**

```bash
./scripts/refresh-mongo.sh
```

- Runs `docker compose down` (no `-v`) → keeps data volume.
- Restarts MongoDB with existing data.
- **Use when** you just need to restart after config/env tweaks.

---
### 🛠 Install Mongo CLI Tools
```
brew install mongodb-database-tools # for mongodump/mongorestore
brew tap mongodb/brew && brew install mongocli # for Atlas CLI
```

---

### 🌱 Seeding Data (Manual)


```
npm run seed:local or npm run seed:atlas
```
or:

```
Place .json or .csv files in /mongo/seeds

/mongo/seeds/users.json
/mongo/seeds/products.json
```

Run:
```
./scripts/seed-mongo.sh                   # Seed local dev
./scripts/seed-mongo.sh $ATLAS_MONGO_URI  # Seed Atlas

```

---

### 💾 Backing Up

```
npm run backup:local
npm run backup:atlas
```
or: 

```
./scripts/backup-mongo.sh                   # Backup local
./scripts/backup-mongo.sh $ATLAS_MONGO_URI  # Backup Atlas
```

**Backups are stored under /backups/YYYYMMDD_HHMMSS.**

---
### 📥 Restoring from Backup
```
Set RESTORE_FROM=./backups/... in .env then:
npm run restore:local 
npm run restore:atlas
```

or:

```
./scripts/restore-mongo.sh ./backups/20250814_150000
./scripts/restore-mongo.sh ./backups/20250814_150000 $ATLAS_MONGO_URI
```

---

## 🔗 Connecting

### **Compass**

URI format:

```
mongodb://appuser:super_secret_password_change_me@localhost:27017/appdb?authSource=admin&replicaSet=rs0
```

- Host: `localhost`
- Port: `27017`
- Auth DB: `admin`
- Replica Set Name: `rs0`
- TLS: Off (dev only)

---

### **mongosh (host)**

```bash
mongosh "mongodb://appuser:super_secret_password_change_me@localhost:27017/appdb?authSource=admin&replicaSet=rs0"
```

**Test connection:**

```bash
docker exec -it mongo-boilerplate mongosh \
  -u mongo \
  -p \
  --authenticationDatabase admin \
  --eval 'db.adminCommand({ getCmdLineOpts: 1 })'
```

**Success result:**

```
{
  argv: [ 'mongod', '--config', '/etc/mongod.conf', '--auth' ],
  parsed: {
    config: '/etc/mongod.conf',
    net: { bindIp: '0.0.0.0', port: 27017 },
    replication: { replSetName: 'rs0' },
    security: { authorization: 'enabled', keyFile: '/etc/mongo-keyfile/keyfile' },
    storage: { dbPath: '/data/db' },
    systemLog: { destination: 'file', logAppend: true, path: '/dev/stdout' }
  },
  ok: 1
}
```

---

## Running MongoDB on a LAN Dev Server (e.g., Mac mini) for QA Testing

This setup lets you run MongoDB in a Docker container on another machine (such as a Mac mini) and connect to it from your laptop over your local network — creating a pseudo-“local cloud” environment.

---

### 1. Enable LAN Access in `mongod.dev.conf`

Make sure your config has:

```yaml
net:
  bindIp: 0.0.0.0
```

### 2. Expose the Port in docker-compose.yml

```ports:
  - "${MONGO_PORT:-27017}:27017"
```

### 3. Allow Incoming Connections on the Dev Server

```
On macOS (Mac mini):

System Settings → Network → Firewall

Either disable the firewall temporarily (LAN testing only) or add an allow rule for Docker

The first time a remote connection is attempted, macOS may prompt you to allow it
```

### 4. Get the Dev Server’s LAN IP

```env
ipconfig getifaddr en0   # For Wi-Fi

# or
ipconfig getifaddr en1   # For Ethernet

```

### 5. Connect from Your Laptop/etc...

```
mongodb://<APP_USER>:<APP_PASSWORD>@192.168.1.50:27017/<DB_NAME>?authSource=admin&replicaSet=rs0
```

### 6. Optional: Create a Friendly Hostname

You can assign the Mac mini a static IP via your router, then map it in /etc/hosts on your laptop:

```
192.168.1.50 mongo-dev.local
```

### Security Tips

- Always use strong, unique passwords for MONGO_INITDB_ROOT_PASSWORD and MONGO_APP_PASSWORD
- Keep security.authorization enabled in mongod.dev.conf
- Consider restricting bindIp to `127.0.0.1,<LAN_IP>` if you want to limit access to only your dev server and localhost:

```
net:
  bindIp: 127.0.0.1, 192.168.1.50
```

---

## 📌 Notes

- **Persistence**: Data lives in the `mongo_data_dev` named volume. Only `reset-mongo-dev.sh` wipes it.
- **Init Scripts**: `/mongo/init/*.js` only run if `/data/db` is empty.
- **Replica Set**: Required for multi-doc transactions & change streams.
- **Keyfile**: Needed for internal auth when `authorization` + `replication` are enabled.

---

## 🧹 Cleaning Up

To remove everything (containers, images, volumes):

```bash
docker compose down -v --rmi all
```

---

## 🖼 Diagram

```mermaid
flowchart TD
    A[Docker Compose Up] --> B[MongoDB Container]
    B -->|Uses| C[mongod.dev.conf]
    B -->|Runs on empty data dir| D[Init Scripts]
    D -->|rs.initiate| E[Replica Set PRIMARY]
    D -->|createUser| F[Root + App Users]
    E --> G[Ready for Connections]
    F --> G
    G -->|Compass| H[(Local Dev DB)]
    G -->|mongosh| H
```

---
