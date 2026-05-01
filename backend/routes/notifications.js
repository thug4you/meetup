const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { authMiddleware } = require('../middleware/auth');

// Получить уведомления пользователя (требуется авторизация)
router.get('/', authMiddleware, async (req, res) => {
  try {
    // Получаем user_id из JWT токена
    const userId = req.user.id;
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

// Получить количество непрочитанных уведомлений (требуется авторизация)
router.get('/unread-count', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await pool.query(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = $1 AND is_read = false',
      [userId]
    );

    res.json({ count: parseInt(result.rows[0].count) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Отметить уведомление как прочитанное (требуется авторизация)
router.put('/:id/read', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const result = await pool.query(
      'UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2 RETURNING *',
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Уведомление не найдено' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Отметить все уведомления как прочитанные (требуется авторизация)
router.put('/read-all', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;

    await pool.query(
      'UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false',
      [userId]
    );

    res.json({ message: 'Все уведомления отмечены как прочитанные' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Удалить уведомление (требуется авторизация)
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const result = await pool.query(
      'DELETE FROM notifications WHERE id = $1 AND user_id = $2 RETURNING *',
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Уведомление не найдено' });
    }

    res.json({ message: 'Уведомление удалено' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Очистить все уведомления (требуется авторизация)
router.delete('/clear-all', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;

    await pool.query(
      'DELETE FROM notifications WHERE user_id = $1',
      [userId]
    );

    res.json({ message: 'Все уведомления удалены' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Создать уведомление о завершённой встречи для пользователя (требуется авторизация)
router.post('/meeting-ended/:meetingId', authMiddleware, async (req, res) => {
  try {
    const { meetingId } = req.params;
    const userId = req.user.id;

    // Проверяем, что пользователь участник встречи
    const participantCheck = await pool.query(`
      SELECT 1 FROM meeting_participants 
      WHERE meeting_id = $1 AND user_id = $2
    `, [meetingId, userId]);

    if (participantCheck.rows.length === 0) {
      return res.status(403).json({ error: 'Вы не участник этой встречи' });
    }

    // Получаем информацию о встречи
    const meetingResult = await pool.query(`
      SELECT title FROM meetings WHERE id = $1
    `, [meetingId]);

    if (meetingResult.rows.length === 0) {
      return res.status(404).json({ error: 'Встреча не найдена' });
    }

    const meetingTitle = meetingResult.rows[0].title;

    // Проверяем, не создано ли уже уведомление об этом
    const existingNotif = await pool.query(`
      SELECT id FROM notifications 
      WHERE user_id = $1 AND type = 'meeting_ended' AND reference_type = 'meeting' AND reference_id = $2
    `, [userId, meetingId]);

    if (existingNotif.rows.length > 0) {
      return res.status(200).json({ message: 'Уведомление уже существует' });
    }

    // Создаём уведомление
    const result = await pool.query(`
      INSERT INTO notifications (user_id, title, content, type, reference_type, reference_id)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `, [userId, 'Встреча завершена', `Ваша встреча "${meetingTitle}" завершилась. Оставьте отзыв о месте!`, 'meeting_ended', 'meeting', meetingId]);

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Ошибка создания уведомления о завершённой встречи:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
