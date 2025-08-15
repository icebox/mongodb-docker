require('dotenv').config();
const { execSync } = require('child_process');

const target = process.argv[2] || 'local';
const uri = target === 'atlas' ? process.env.ATLAS_MONGO_URI : process.env.LOCAL_MONGO_URI;
const backupPath = process.env.RESTORE_FROM;

if (!backupPath) {
  console.error('❌ Please set RESTORE_FROM in .env or pass via CLI');
  process.exit(1);
}

try {
  console.log(`Restoring ${target} database from ${backupPath}...`);
  execSync(`mongorestore --uri="${uri}" "${backupPath}" --drop`, { stdio: 'inherit' });
  console.log('✅ Restore complete');
} catch (err) {
  console.error('❌ Restore failed:', err);
}
