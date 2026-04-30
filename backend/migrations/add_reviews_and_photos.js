const pool = require('../config/database');

const runMigration = async () => {
  try {
    console.log('Начало миграции: добавление таблиц reviews и photos для мест...');

    // Таблица отзывов о местах
    await pool.query(`
      CREATE TABLE IF NOT EXISTS place_reviews (
        id SERIAL PRIMARY KEY,
        place_id INTEGER REFERENCES places(id) ON DELETE CASCADE NOT NULL,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
        rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
        text TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✓ Таблица place_reviews создана');

    // Таблица фото мест
    await pool.query(`
      CREATE TABLE IF NOT EXISTS place_photos (
        id SERIAL PRIMARY KEY,
        place_id INTEGER REFERENCES places(id) ON DELETE CASCADE NOT NULL,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
        photo_url VARCHAR(500) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✓ Таблица place_photos создана');

    // Добавляем поле average_rating к places
    const ratingCheck = await pool.query(`
      SELECT column_name FROM information_schema.columns 
      WHERE table_name='places' AND column_name='average_rating'
    `);

    if (ratingCheck.rows.length === 0) {
      await pool.query(`
        ALTER TABLE places ADD COLUMN average_rating DECIMAL(3, 2) DEFAULT 0.0;
      `);
      console.log('✓ Добавлен столбец average_rating в таблицу places');
    } else {
      console.log('✓ Столбец average_rating уже существует');
    }

    // Триггер для обновления updated_at в place_reviews
    await pool.query(`
      DROP TRIGGER IF EXISTS update_place_reviews_updated_at ON place_reviews;
      CREATE TRIGGER update_place_reviews_updated_at
        BEFORE UPDATE ON place_reviews
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    `);
    console.log('✓ Триггер для обновления place_reviews создан');

    console.log('✓ Миграция завершена успешно');
  } catch (err) {
    console.error('❌ Ошибка миграции:', err);
  }
};

module.exports = { runMigration };
