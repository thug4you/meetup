const pool = require('../config/database');

const createTables = async () => {
  try {
    // Таблица пользователей
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        avatar_url VARCHAR(500),
        bio TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Таблица мест
    await pool.query(`
      CREATE TABLE IF NOT EXISTS places (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        address TEXT NOT NULL,
        latitude DECIMAL(10, 8),
        longitude DECIMAL(11, 8),
        description TEXT,
        image_url VARCHAR(500),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Таблица встреч
    await pool.query(`
      CREATE TABLE IF NOT EXISTS meetings (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        place_id INTEGER REFERENCES places(id),
        organizer_id INTEGER REFERENCES users(id),
        start_time TIMESTAMP NOT NULL,
        end_time TIMESTAMP,
        max_participants INTEGER,
        status VARCHAR(50) DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Таблица участников встреч
    await pool.query(`
      CREATE TABLE IF NOT EXISTS meeting_participants (
        id SERIAL PRIMARY KEY,
        meeting_id INTEGER REFERENCES meetings(id) ON DELETE CASCADE,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        status VARCHAR(50) DEFAULT 'confirmed',
        joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(meeting_id, user_id)
      );
    `);

    // Таблица сообщений чата
    await pool.query(`
      CREATE TABLE IF NOT EXISTS messages (
        id SERIAL PRIMARY KEY,
        meeting_id INTEGER REFERENCES meetings(id) ON DELETE CASCADE,
        user_id INTEGER REFERENCES users(id),
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Таблица уведомлений
    await pool.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        message TEXT,
        type VARCHAR(50),
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Таблица жалоб
    await pool.query(`
      CREATE TABLE IF NOT EXISTS reports (
        id SERIAL PRIMARY KEY,
        reporter_id INTEGER REFERENCES users(id),
        reported_user_id INTEGER REFERENCES users(id),
        meeting_id INTEGER REFERENCES meetings(id),
        reason TEXT NOT NULL,
        status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    console.log('✓ Все таблицы созданы успешно');
  } catch (err) {
    console.error('❌ Ошибка создания таблиц:', err);
  }
};

module.exports = { createTables };
