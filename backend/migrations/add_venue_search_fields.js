const pool = require('../config/database');

const migrate = async () => {
  try {
    // Добавляем category и average_bill к таблице places
    await pool.query(`
      ALTER TABLE places 
      ADD COLUMN IF NOT EXISTS category VARCHAR(100),
      ADD COLUMN IF NOT EXISTS average_bill DECIMAL(10, 2);
    `);

    console.log('✓ Поля category и average_bill добавлены в таблицу places');
  } catch (err) {
    console.error('❌ Ошибка миграции:', err.message);
  } finally {
    await pool.end();
  }
};

migrate();
