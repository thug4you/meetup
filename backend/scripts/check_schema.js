const pool = require('../config/database');

async function checkSchema() {
  try {
    const result = await pool.query(`
      SELECT column_name, data_type, character_maximum_length 
      FROM information_schema.columns 
      WHERE table_name='meetings' 
      ORDER BY ordinal_position
    `);

    console.log('\n📋 Структура таблицы meetings:');
    console.log('════════════════════════════════════════════');
    result.rows.forEach(col => {
      const length = col.character_maximum_length ? `(${col.character_maximum_length})` : '';
      console.log(`  • ${col.column_name.padEnd(20)} : ${col.data_type}${length}`);
    });
    console.log('════════════════════════════════════════════\n');

    await pool.end();
  } catch (err) {
    console.error('Ошибка:', err);
    process.exit(1);
  }
}

checkSchema();
