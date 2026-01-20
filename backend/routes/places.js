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

    const result = await pool.query(
      'INSERT INTO places (name, address, latitude, longitude, description, image_url) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [name, address, latitude, longitude, description, image_url]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
