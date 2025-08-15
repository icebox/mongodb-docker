require('dotenv').config();
const { MongoClient } = require('mongodb');

const target = process.argv[2] || 'local';
const uri = target === 'atlas' ? process.env.ATLAS_MONGO_URI : process.env.LOCAL_MONGO_URI;

async function seed() {
  console.log(`Seeding ${target} database...`);
  const client = new MongoClient(uri);
  try {
    await client.connect();
    const db = client.db();
    const col = db.collection('example');
    await col.insertMany([
      { name: 'Alice', createdAt: new Date() },
      { name: 'Bob', createdAt: new Date() }
    ]);
    console.log('✅ Seed data inserted');
  } catch (err) {
    console.error('❌ Error seeding database:', err);
  } finally {
    await client.close();
  }
}

seed();
