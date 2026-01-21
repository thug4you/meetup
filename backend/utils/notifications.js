const pool = require('../config/database');

/**
 * Создает уведомление для пользователя
 * @param {number} userId - ID пользователя
 * @param {string} title - Заголовок уведомления
 * @param {string} message - Текст уведомления
 * @param {string} type - Тип уведомления (meeting, system, chat, etc.)
 * @returns {Promise<Object>} Созданное уведомление
 */
async function createNotification(userId, title, message, type = 'system') {
  try {
    const result = await pool.query(
      'INSERT INTO notifications (user_id, title, message, type) VALUES ($1, $2, $3, $4) RETURNING *',
      [userId, title, message, type]
    );
    return result.rows[0];
  } catch (err) {
    console.error('Ошибка создания уведомления:', err);
    throw err;
  }
}

/**
 * Создает уведомления для нескольких пользователей
 * @param {Array<number>} userIds - Массив ID пользователей
 * @param {string} title - Заголовок уведомления
 * @param {string} message - Текст уведомления
 * @param {string} type - Тип уведомления
 */
async function createBulkNotifications(userIds, title, message, type = 'system') {
  try {
    const values = userIds.map((userId, index) => {
      const offset = index * 4;
      return `($${offset + 1}, $${offset + 2}, $${offset + 3}, $${offset + 4})`;
    }).join(', ');

    const params = userIds.flatMap(userId => [userId, title, message, type]);

    await pool.query(
      `INSERT INTO notifications (user_id, title, message, type) VALUES ${values}`,
      params
    );
  } catch (err) {
    console.error('Ошибка создания массовых уведомлений:', err);
    throw err;
  }
}

module.exports = {
  createNotification,
  createBulkNotifications
};
