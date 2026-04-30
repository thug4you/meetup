const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { authMiddleware } = require('../middleware/auth');

// Получить отзывы для места
router.get('/place/:placeId', async (req, res) => {
  try {
    const { placeId } = req.params;
    
    const result = await pool.query(`
      SELECT pr.id, pr.place_id, pr.user_id, pr.rating, pr.text, pr.created_at,
             u.name, u.avatar_url
      FROM place_reviews pr
      JOIN users u ON pr.user_id = u.id
      WHERE pr.place_id = $1
      ORDER BY pr.created_at DESC
    `, [placeId]);

    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Получить рейтинг места
router.get('/place/:placeId/rating', async (req, res) => {
  try {
    const { placeId } = req.params;
    
    const result = await pool.query(`
      SELECT 
        COUNT(*) as total,
        AVG(rating) as average,
        SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) as five_star,
        SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END) as four_star,
        SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END) as three_star,
        SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END) as two_star,
        SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END) as one_star
      FROM place_reviews
      WHERE place_id = $1
    `, [placeId]);

    const rating = result.rows[0];
    res.json({
      averageRating: parseFloat(rating.average) || 0,
      totalReviews: parseInt(rating.total),
      distribution: {
        5: parseInt(rating.five_star) || 0,
        4: parseInt(rating.four_star) || 0,
        3: parseInt(rating.three_star) || 0,
        2: parseInt(rating.two_star) || 0,
        1: parseInt(rating.one_star) || 0,
      }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Создать отзыв (требуется авторизация)
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { placeId, rating, text } = req.body;
    const userId = req.user.id;

    if (!placeId || !rating) {
      return res.status(400).json({ 
        error: 'Обязательные поля не заполнены',
        required: ['placeId', 'rating']
      });
    }

    if (rating < 1 || rating > 5) {
      return res.status(400).json({ error: 'Рейтинг должен быть от 1 до 5' });
    }

    // Проверяем, существует ли место
    const placeCheck = await pool.query('SELECT id FROM places WHERE id = $1', [placeId]);
    if (placeCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Место не найдено' });
    }

    // Создаём отзыв
    const result = await pool.query(`
      INSERT INTO place_reviews (place_id, user_id, rating, text)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [placeId, userId, rating, text || null]);

    const review = result.rows[0];

    // Обновляем средний рейтинг места
    const ratingResult = await pool.query(`
      UPDATE places 
      SET average_rating = (SELECT AVG(rating) FROM place_reviews WHERE place_id = $1)
      WHERE id = $1
      RETURNING average_rating
    `, [placeId]);

    res.status(201).json({
      ...review,
      averageRating: parseFloat(ratingResult.rows[0]?.average_rating || 0)
    });
  } catch (err) {
    console.error('Ошибка создания отзыва:', err);
    res.status(500).json({ error: err.message });
  }
});

// Обновить отзыв (только автор)
router.put('/:reviewId', authMiddleware, async (req, res) => {
  try {
    const { reviewId } = req.params;
    const { rating, text } = req.body;
    const userId = req.user.id;

    // Проверяем, что это отзыв пользователя
    const reviewCheck = await pool.query(
      'SELECT place_id FROM place_reviews WHERE id = $1 AND user_id = $2',
      [reviewId, userId]
    );

    if (reviewCheck.rows.length === 0) {
      return res.status(403).json({ error: 'У вас нет прав на это действие' });
    }

    const placeId = reviewCheck.rows[0].place_id;

    const result = await pool.query(`
      UPDATE place_reviews 
      SET rating = $1, text = $2, updated_at = NOW()
      WHERE id = $3
      RETURNING *
    `, [rating || null, text || null, reviewId]);

    // Обновляем средний рейтинг места
    await pool.query(`
      UPDATE places 
      SET average_rating = (SELECT AVG(rating) FROM place_reviews WHERE place_id = $1)
      WHERE id = $1
    `, [placeId]);

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Удалить отзыв (только автор)
router.delete('/:reviewId', authMiddleware, async (req, res) => {
  try {
    const { reviewId } = req.params;
    const userId = req.user.id;

    // Проверяем, что это отзыв пользователя
    const reviewCheck = await pool.query(
      'SELECT place_id FROM place_reviews WHERE id = $1 AND user_id = $2',
      [reviewId, userId]
    );

    if (reviewCheck.rows.length === 0) {
      return res.status(403).json({ error: 'У вас нет прав на это действие' });
    }

    const placeId = reviewCheck.rows[0].place_id;

    await pool.query('DELETE FROM place_reviews WHERE id = $1', [reviewId]);

    // Обновляем средний рейтинг места
    await pool.query(`
      UPDATE places 
      SET average_rating = (SELECT AVG(rating) FROM place_reviews WHERE place_id = $1)
      WHERE id = $1
    `, [placeId]);

    res.json({ message: 'Отзыв удалён' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
