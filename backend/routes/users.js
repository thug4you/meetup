const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Получить текущего пользователя (me)
router.get('/me', async (req, res) => {
  try {
    // TODO: получить ID из JWT токена
    // Пока используем ID из query параметра для тестирования
    const userId = req.query.id || 1;
    
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

// Обновить профиль
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, bio, avatar_url } = req.body;

    const result = await pool.query(
      'UPDATE users SET name = $1, bio = $2, avatar_url = $3, updated_at = CURRENT_TIMESTAMP WHERE id = $4 RETURNING id, email, name, avatar_url, bio',
      [name, bio, avatar_url, id]
    );

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
      SELECT m.*, p.name as place_name, p.address
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
      SELECT m.*, p.name as place_name, p.address
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
