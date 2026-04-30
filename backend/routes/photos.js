const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { authMiddleware } = require('../middleware/auth');

// Получить фото места
router.get('/place/:placeId', async (req, res) => {
  try {
    const { placeId } = req.params;
    const limit = req.query.limit || 10;
    
    const result = await pool.query(`
      SELECT pp.id, pp.place_id, pp.user_id, pp.photo_url, pp.created_at,
             u.name, u.avatar_url
      FROM place_photos pp
      JOIN users u ON pp.user_id = u.id
      WHERE pp.place_id = $1
      ORDER BY pp.created_at DESC
      LIMIT $2
    `, [placeId, limit]);

    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Загрузить фото (требуется авторизация)
// На production нужно использовать multer + загрузку на S3/облако
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { placeId, photoUrl } = req.body;
    const userId = req.user.id;

    if (!placeId || !photoUrl) {
      return res.status(400).json({ 
        error: 'Обязательные поля не заполнены',
        required: ['placeId', 'photoUrl']
      });
    }

    // Проверяем, существует ли место
    const placeCheck = await pool.query('SELECT id FROM places WHERE id = $1', [placeId]);
    if (placeCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Место не найдено' });
    }

    // Создаём запись фото
    const result = await pool.query(`
      INSERT INTO place_photos (place_id, user_id, photo_url)
      VALUES ($1, $2, $3)
      RETURNING *
    `, [placeId, userId, photoUrl]);

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Ошибка загрузки фото:', err);
    res.status(500).json({ error: err.message });
  }
});

// Удалить фото (только автор)
router.delete('/:photoId', authMiddleware, async (req, res) => {
  try {
    const { photoId } = req.params;
    const userId = req.user.id;

    // Проверяем, что это фото пользователя
    const photoCheck = await pool.query(
      'SELECT id FROM place_photos WHERE id = $1 AND user_id = $2',
      [photoId, userId]
    );

    if (photoCheck.rows.length === 0) {
      return res.status(403).json({ error: 'У вас нет прав на это действие' });
    }

    await pool.query('DELETE FROM place_photos WHERE id = $1', [photoId]);

    res.json({ message: 'Фото удалено' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
