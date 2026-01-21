const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Поиск мест
router.get('/search', async (req, res) => {
  try {
    const { query } = req.query;
    
    if (!query) {
      return res.json([]);
    }

    const result = await pool.query(
      `SELECT * FROM places 
       WHERE name ILIKE $1 OR address ILIKE $1 
       ORDER BY created_at DESC 
       LIMIT 10`,
      [`%${query}%`]
    );

    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Получить все места
router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM places ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Создать место
router.post('/', async (req, res) => {
  try {
    const { name, address, latitude, longitude, description, image_url } = req.body;

    // Валидация обязательных полей
    if (!name || !address) {
      return res.status(400).json({ 
        error: 'Обязательные поля не заполнены',
        required: ['name', 'address']
      });
    }

    // Валидация координат
    if (latitude && (latitude < -90 || latitude > 90)) {
      return res.status(400).json({ error: 'Широта должна быть между -90 и 90' });
    }
    if (longitude && (longitude < -180 || longitude > 180)) {
      return res.status(400).json({ error: 'Долгота должна быть между -180 и 180' });
    }

    const result = await pool.query(
      'INSERT INTO places (name, address, latitude, longitude, description, image_url) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [name, address, latitude || null, longitude || null, description || null, image_url || null]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
