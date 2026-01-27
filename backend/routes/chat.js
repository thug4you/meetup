const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { authMiddleware } = require('../middleware/auth');

// Получить сообщения встречи
router.get('/:meetingId/messages', authMiddleware, async (req, res) => {
  try {
    const { meetingId } = req.params;
    const { page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;

    // Проверяем, что пользователь участник встречи
    const participantCheck = await pool.query(`
      SELECT 1 FROM meeting_participants 
      WHERE meeting_id = $1 AND user_id = $2
      UNION
      SELECT 1 FROM meetings 
      WHERE id = $1 AND organizer_id = $2
    `, [meetingId, req.user.id]);

    if (participantCheck.rows.length === 0) {
      return res.status(403).json({ error: 'Вы не участник этой встречи' });
    }

    const result = await pool.query(`
      SELECT m.id, m.content, m.created_at as "sentAt",
             json_build_object(
               'id', u.id::text,
               'name', u.name,
               'email', u.email,
               'avatar_url', u.avatar_url
             ) as sender
      FROM messages m
      JOIN users u ON m.user_id = u.id
      WHERE m.meeting_id = $1
      ORDER BY m.created_at DESC
      LIMIT $2 OFFSET $3
    `, [meetingId, limit, offset]);

    // Преобразуем для совместимости с Flutter моделью
    const messages = result.rows.map(row => ({
      id: row.id.toString(),
      meetingId: meetingId,
      sender: row.sender,
      content: row.content,
      sentAt: row.sentAt,
      isRead: true
    }));

    res.json(messages);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Отправить сообщение (REST fallback, основной через WebSocket)
router.post('/:meetingId/messages', authMiddleware, async (req, res) => {
  try {
    const { meetingId } = req.params;
    const { content } = req.body;
    const userId = req.user.id;

    if (!content || content.trim() === '') {
      return res.status(400).json({ error: 'Сообщение не может быть пустым' });
    }

    // Проверяем, что пользователь участник встречи
    const participantCheck = await pool.query(`
      SELECT 1 FROM meeting_participants 
      WHERE meeting_id = $1 AND user_id = $2
      UNION
      SELECT 1 FROM meetings 
      WHERE id = $1 AND organizer_id = $2
    `, [meetingId, userId]);

    if (participantCheck.rows.length === 0) {
      return res.status(403).json({ error: 'Вы не участник этой встречи' });
    }

    const result = await pool.query(`
      INSERT INTO messages (meeting_id, user_id, content)
      VALUES ($1, $2, $3)
      RETURNING id, content, created_at
    `, [meetingId, userId, content.trim()]);

    const message = result.rows[0];

    // Получаем данные отправителя
    const userResult = await pool.query(
      'SELECT id, name, email, avatar_url FROM users WHERE id = $1',
      [userId]
    );

    res.status(201).json({
      id: message.id.toString(),
      meetingId: meetingId,
      sender: userResult.rows[0],
      content: message.content,
      sentAt: message.created_at,
      isRead: false
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Отметить сообщения как прочитанные
router.post('/:meetingId/messages/read', authMiddleware, async (req, res) => {
  try {
    const { meetingId } = req.params;
    const { messageIds } = req.body;

    // В текущей схеме нет поля is_read в messages, 
    // но мы можем добавить эту функциональность в будущем
    
    res.json({ message: 'Сообщения отмечены как прочитанные' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Удалить сообщение
router.delete('/:meetingId/messages/:messageId', authMiddleware, async (req, res) => {
  try {
    const { meetingId, messageId } = req.params;
    const userId = req.user.id;

    // Проверяем, что пользователь автор сообщения
    const messageCheck = await pool.query(
      'SELECT user_id FROM messages WHERE id = $1 AND meeting_id = $2',
      [messageId, meetingId]
    );

    if (messageCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Сообщение не найдено' });
    }

    if (messageCheck.rows[0].user_id !== userId) {
      return res.status(403).json({ error: 'Вы можете удалять только свои сообщения' });
    }

    await pool.query('DELETE FROM messages WHERE id = $1', [messageId]);

    res.json({ message: 'Сообщение удалено' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
