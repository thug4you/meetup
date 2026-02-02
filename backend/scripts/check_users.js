const { Client } = require('pg');

const client = new Client({
  user: 'postgres',
  host: 'localhost',
  database: 'meetup_db',
  password: '111',
  port: 5432
});

async function checkUsers() {
  try {
    await client.connect();
    const res = await client.query('SELECT id, email, name, role FROM users');
    console.log('=== USERS IN DATABASE ===');
    console.log(JSON.stringify(res.rows, null, 2));
    await client.end();
  } catch (err) {
    console.error('Error:', err);
  }
}

checkUsers();
