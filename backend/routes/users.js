const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { authMiddleware } = require('../middleware/auth');

// Получить текущего пользователя (me) - требуется авторизация
router.get('/me', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    
    const result = await pool.query(
      'SELECT id, email, name, avatar_url, bio, created_at FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Получить профиль пользователя
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(
      'SELECT id, email, name, avatar_url, bio, created_at FROM users WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Обновить профиль текущего пользователя (требуется авторизация)
router.put('/me', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, bio, avatar_url } = req.body;

    const result = await pool.query(
      'UPDATE users SET name = COALESCE($1, name), bio = COALESCE($2, bio), avatar_url = COALESCE($3, avatar_url) WHERE id = $4 RETURNING id, email, name, avatar_url, bio',
      [name, bio, avatar_url, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Не удалось обновить профиль' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Обновить профиль пользователя по ID (требуется авторизация, только свой профиль)
router.put('/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const { name, bio, avatar_url } = req.body;

    // Проверяем, что пользователь редактирует свой профиль
    if (parseInt(id) !== userId) {
      return res.status(403).json({ error: 'Вы можете редактировать только свой профиль' });
    }

    const result = await pool.query(
      'UPDATE users SET name = COALESCE($1, name), bio = COALESCE($2, bio), avatar_url = COALESCE($3, avatar_url) WHERE id = $4 RETURNING id, email, name, avatar_url, bio',
      [name, bio, avatar_url, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Не удалось обновить профиль' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Получить созданные встречи пользователя
router.get('/:id/meetings/created', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      SELECT m.*, p.name as place_name, p.address, p.latitude, p.longitude
      FROM meetings m
      LEFT JOIN places p ON m.place_id = p.id
      WHERE m.organizer_id = $1
      ORDER BY m.start_time DESC
    `, [id]);

    res.json({ meetings: result.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Получить встречи в которых участвует пользователь
router.get('/:id/meetings/joined', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      SELECT m.*, p.name as place_name, p.address, p.latitude, p.longitude
      FROM meetings m
      LEFT JOIN places p ON m.place_id = p.id
      INNER JOIN meeting_participants mp ON m.id = mp.meeting_id
      WHERE mp.user_id = $1
      ORDER BY m.start_time DESC
    `, [id]);

    res.json({ meetings: result.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
