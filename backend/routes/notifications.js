const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Получить уведомления пользователя
router.get('/', async (req, res) => {
  try {
    // TODO: получить user_id из JWT токена
    const userId = req.query.userId || 1;
    const { page = 1, limit = 20, isRead } = req.query;
    const offset = (page - 1) * limit;

    let query = `
      SELECT * FROM notifications 
      WHERE user_id = $1
    `;
    const params = [userId];

    if (isRead !== undefined) {
      query += ` AND is_read = $${params.length + 1}`;
      params.push(isRead === 'true');
    }

    query += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);

    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Получить количество непрочитанных уведомлений
router.get('/unread-count', async (req, res) => {
  try {
    const userId = req.query.userId || 1;

    const result = await pool.query(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = $1 AND is_read = false',
      [userId]
    );

    res.json({ count: parseInt(result.rows[0].count) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Отметить уведомление как прочитанное
router.put('/:id/read', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      'UPDATE notifications SET is_read = true WHERE id = $1 RETURNING *',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Уведомление не найдено' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Отметить все уведомления как прочитанные
router.put('/mark-all-read', async (req, res) => {
  try {
    const userId = req.query.userId || 1;

    await pool.query(
      'UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false',
      [userId]
    );

    res.json({ message: 'Все уведомления отмечены как прочитанные' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
