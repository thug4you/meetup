const { Client } = require('pg');
const bcrypt = require('bcrypt');

const client = new Client({
  user: 'postgres',
  host: 'localhost',
  database: 'meetup_db',
  password: '111',
  port: 5432
});

async function createAdmin() {
  try {
    await client.connect();
    
    const email = 'admin@meetup.com';
    const password = 'admin123';
    const name = 'Администратор';
    
    // Проверяем, есть ли уже админ
    const existing = await client.query('SELECT id FROM users WHERE email = $1', [email]);
    
    if (existing.rows.length > 0) {
      // Обновляем роль существующего пользователя
      await client.query("UPDATE users SET role = 'admin' WHERE email = $1", [email]);
      console.log('Существующий пользователь обновлён до админа');
    } else {
      // Создаём нового админа
      const hashedPassword = await bcrypt.hash(password, 10);
      await client.query(
        "INSERT INTO users (email, password, name, role) VALUES ($1, $2, $3, 'admin')",
        [email, hashedPassword, name]
      );
      console.log('Новый администратор создан');
    }
    
    console.log('========================================');
    console.log('Данные для входа в админ-панель:');
    console.log('Email: admin@meetup.com');
    console.log('Пароль: admin123');
    console.log('========================================');
    
    await client.end();
  } catch (err) {
    console.error('Ошибка:', err);
  }
}

createAdmin();
