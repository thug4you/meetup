const pool = require('../config/database');

async function migrate() {
  try {
    console.log('Начало миграции: добавление полей category и budget в таблицу meetings...');

    // Проверяем, существует ли столбец category
    const categoryCheck = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name='meetings' AND column_name='category'
    `);

    if (categoryCheck.rows.length === 0) {
      await pool.query(`
        ALTER TABLE meetings ADD COLUMN category VARCHAR(100);
      `);
      console.log('✓ Добавлен столбец category');
    } else {
      console.log('✓ Столбец category уже существует');
    }

    // Проверяем, существует ли столбец budget
    const budgetCheck = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name='meetings' AND column_name='budget'
    `);

    if (budgetCheck.rows.length === 0) {
      await pool.query(`
        ALTER TABLE meetings ADD COLUMN budget DECIMAL(10, 2);
      `);
      console.log('✓ Добавлен столбец budget');
    } else {
      console.log('✓ Столбец budget уже существует');
    }

    // Создаем функцию для триггера updated_at, если не существует
    await pool.query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
    `);
    console.log('✓ Функция update_updated_at_column создана');

    // Создаем триггер для meetings
    await pool.query(`
      DROP TRIGGER IF EXISTS update_meetings_updated_at ON meetings;
      CREATE TRIGGER update_meetings_updated_at
        BEFORE UPDATE ON meetings
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    `);
    console.log('✓ Триггер для meetings создан');

    // Создаем триггер для users
    await pool.query(`
      DROP TRIGGER IF EXISTS update_users_updated_at ON users;
      CREATE TRIGGER update_users_updated_at
        BEFORE UPDATE ON users
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    `);
    console.log('✓ Триггер для users создан');

    console.log('✅ Миграция завершена успешно!');
  } catch (err) {
    console.error('❌ Ошибка миграции:', err);
    throw err;
  }
}

// Запуск миграции
if (require.main === module) {
  migrate()
    .then(() => {
      console.log('Миграция выполнена');
      process.exit(0);
    })
    .catch((err) => {
      console.error('Ошибка:', err);
      process.exit(1);
    });
}

module.exports = { migrate };
