require('dotenv').config();
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const target = process.argv[2] || 'local';
const uri = target === 'atlas' ? process.env.ATLAS_MONGO_URI : process.env.LOCAL_MONGO_URI;
const backupDir = process.env.BACKUP_DIR || './backups';

if (!fs.existsSync(backupDir)) {
  fs.mkdirSync(backupDir, { recursive: true });
}

const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
const outPath = path.join(backupDir, `${target}-backup-${timestamp}`);

try {
  console.log(`Backing up ${target} database to ${outPath}...`);
  execSync(`mongodump --uri="${uri}" --out="${outPath}"`, { stdio: 'inherit' });
  console.log('✅ Backup complete');
} catch (err) {
  console.error('❌ Backup failed:', err);
}
