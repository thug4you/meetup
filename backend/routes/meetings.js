const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const redisClient = require('../config/redis');

// Получить все встречи
router.get('/', async (req, res) => {
  try {
    // Попытка получить из кеша Redis
    const cached = await redisClient.get('meetings:all');
    
    if (cached) {
      return res.json({
        source: 'cache',
        data: JSON.parse(cached)
      });
    }

    // Получение из базы данных
    const result = await pool.query(`
      SELECT m.*, p.name as place_name, p.address, 
             u.name as organizer_name,
             (SELECT COUNT(*) FROM meeting_participants WHERE meeting_id = m.id) as participants_count
      FROM meetings m
      LEFT JOIN places p ON m.place_id = p.id
      LEFT JOIN users u ON m.organizer_id = u.id
      WHERE m.status = 'active'
      ORDER BY m.start_time ASC
    `);

    // Сохранение в кеш на 5 минут
    await redisClient.setEx('meetings:all', 300, JSON.stringify(result.rows));

    res.json({
      source: 'database',
      data: result.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Получить встречу по ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(`
      SELECT m.*, p.name as place_name, p.address, p.latitude, p.longitude,
             u.name as organizer_name, u.avatar_url as organizer_avatar
      FROM meetings m
      LEFT JOIN places p ON m.place_id = p.id
      LEFT JOIN users u ON m.organizer_id = u.id
      WHERE m.id = $1
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Встреча не найдена' });
    }

    // Получить участников
    const participants = await pool.query(`
      SELECT u.id, u.name, u.avatar_url, mp.joined_at
      FROM meeting_participants mp
      JOIN users u ON mp.user_id = u.id
      WHERE mp.meeting_id = $1
    `, [id]);

    res.json({
      ...result.rows[0],
      participants: participants.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Создать встречу
router.post('/', async (req, res) => {
  try {
    const { title, description, placeId, category, dateTime, duration, maxParticipants, budget } = req.body;
    
    console.log('Создание встречи:', { title, description, placeId, category, dateTime, duration, maxParticipants });
    
    // TODO: Получить organizer_id из JWT токена
    const organizer_id = req.body.organizerId || 1;
    
    // Вычисляем end_time
    const start_time = new Date(dateTime);
    const end_time = new Date(start_time.getTime() + (duration * 60000)); // duration в минутах

    // Если placeId пустой или невалидный, используем null
    const place_id = placeId && placeId !== '' ? parseInt(placeId) : null;

    const result = await pool.query(`
      INSERT INTO meetings (title, description, place_id, organizer_id, start_time, end_time, max_participants)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `, [title, description, place_id, organizer_id, start_time, end_time, maxParticipants || 10]);

    // Очистить кеш
    await redisClient.del('meetings:all');

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Ошибка создания встречи:', err);
    res.status(500).json({ error: err.message });
  }
});

// Присоединиться к встрече
router.post('/:id/join', async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id } = req.body;

    const result = await pool.query(`
      INSERT INTO meeting_participants (meeting_id, user_id)
      VALUES ($1, $2)
      ON CONFLICT (meeting_id, user_id) DO NOTHING
      RETURNING *
    `, [id, user_id]);

    res.json({ message: 'Вы присоединились к встрече', data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
