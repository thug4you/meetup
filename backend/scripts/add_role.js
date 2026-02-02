const { Client } = require('pg');
require('dotenv').config({ path: '../.env' });

const client = new Client({
  user: 'postgres',
  host: 'localhost',
  database: 'meetup_db',
  password: '111',
  port: 5432
});

async function addRoleColumn() {
  try {
    await client.connect();
    await client.query("ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user'");
    console.log('ROLE_COLUMN_ADDED_SUCCESSFULLY');
    await client.end();
  } catch (err) {
    console.error('Error:', err);
  }
}

addRoleColumn();
