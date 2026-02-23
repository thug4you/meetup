const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const redisClient = require('../config/redis');
const { createNotification } = require('../utils/notifications');
const { authMiddleware, optionalAuth } = require('../middleware/auth');

// Получить все встречи (публичный доступ с опциональной авторизацией)
router.get('/', optionalAuth, async (req, res) => {
  try {
    // Попытка получить из кеша Redis
    const cached = await redisClient.get('meetings:all');
    
    if (cached) {
      return res.json({
        source: 'cache',
        meetings: JSON.parse(cached)
      });
    }

    // Получение из базы данных
    const result = await pool.query(`
      SELECT m.*, p.name as place_name, p.address, p.latitude, p.longitude,
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
      meetings: result.rows
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
      SELECT u.id, u.name, u.email, u.avatar_url, mp.joined_at
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

// Создать встречу (требуется авторизация)
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { title, description, placeId, category, dateTime, duration, maxParticipants, budget } = req.body;
    
    // Валидация обязательных полей
    if (!title || !dateTime) {
      return res.status(400).json({ 
        error: 'Обязательные поля не заполнены',
        required: ['title', 'dateTime']
      });
    }
    
    console.log('Создание встречи:', { title, description, placeId, category, dateTime, duration, maxParticipants, budget });
    
    // Получаем organizer_id из JWT токена
    const organizer_id = req.user.id;
    
    // Вычисляем end_time
    const start_time = new Date(dateTime);
    if (isNaN(start_time.getTime())) {
      return res.status(400).json({ error: 'Неверный формат даты и времени' });
    }
    const end_time = new Date(start_time.getTime() + ((duration || 60) * 60000)); // duration в минутах

    // Если placeId пустой или невалидный, используем null
    const place_id = placeId && placeId !== '' ? parseInt(placeId) : null;

    // Проверяем, что место существует, если placeId указан
    if (place_id) {
      const placeCheck = await pool.query('SELECT id FROM places WHERE id = $1', [place_id]);
      if (placeCheck.rows.length === 0) {
        return res.status(400).json({ error: 'Место с указанным ID не найдено' });
      }
    }

    const result = await pool.query(`
      INSERT INTO meetings (title, description, place_id, organizer_id, start_time, end_time, max_participants, category, budget)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *
    `, [title, description, place_id, organizer_id, start_time, end_time, maxParticipants || 10, category || null, budget || null]);

    const meeting = result.rows[0];

    // Автоматически добавляем организатора в участники
    await pool.query(`
      INSERT INTO meeting_participants (meeting_id, user_id)
      VALUES ($1, $2)
      ON CONFLICT (meeting_id, user_id) DO NOTHING
    `, [meeting.id, organizer_id]);

    // Создать уведомление для организатора
    try {
      await createNotification(
        organizer_id,
        'Встреча создана',
        `Ваша встреча "${title}" успешно создана`,
        'meeting'
      );
    } catch (notifErr) {
      console.error('Ошибка создания уведомления:', notifErr);
      // Не прерываем выполнение, если не удалось создать уведомление
    }

    // Очистить кеш
    await redisClient.del('meetings:all');

    res.status(201).json(meeting);
  } catch (err) {
    console.error('Ошибка создания встречи:', err);
    res.status(500).json({ error: err.message });
  }
});

// Присоединиться к встрече (требуется авторизация)
router.post('/:id/join', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    // Получаем user_id из JWT токена
    const user_id = req.user.id;

    // Проверяем, существует ли встреча и не превышен ли лимит участников
    const meetingCheck = await pool.query(`
      SELECT m.id, m.max_participants, 
             (SELECT COUNT(*) FROM meeting_participants WHERE meeting_id = m.id) as current_participants
      FROM meetings m
      WHERE m.id = $1 AND m.status = 'active'
    `, [id]);

    if (meetingCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Встреча не найдена или неактивна' });
    }

    const meeting = meetingCheck.rows[0];
    if (meeting.max_participants && meeting.current_participants >= meeting.max_participants) {
      return res.status(400).json({ error: 'Превышен лимит участников' });
    }

    const result = await pool.query(`
      INSERT INTO meeting_participants (meeting_id, user_id)
      VALUES ($1, $2)
      ON CONFLICT (meeting_id, user_id) DO NOTHING
      RETURNING *
    `, [id, user_id]);

    if (result.rows.length === 0) {
      return res.json({ message: 'Вы уже участвуете в этой встрече' });
    }

    // Очистить кеш
    await redisClient.del('meetings:all');

    // Возвращаем обновлённую встречу с участниками
    const meetingResult = await pool.query(`
      SELECT m.*, p.name as place_name, p.address, p.latitude, p.longitude,
             u.name as organizer_name, u.avatar_url as organizer_avatar
      FROM meetings m
      LEFT JOIN places p ON m.place_id = p.id
      LEFT JOIN users u ON m.organizer_id = u.id
      WHERE m.id = $1
    `, [id]);

    const participants = await pool.query(`
      SELECT u.id, u.name, u.avatar_url, u.email, mp.joined_at
      FROM meeting_participants mp
      JOIN users u ON mp.user_id = u.id
      WHERE mp.meeting_id = $1
    `, [id]);

    res.json({
      ...meetingResult.rows[0],
      participants: participants.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Покинуть встречу (требуется авторизация)
router.post('/:id/leave', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const user_id = req.user.id;

    // Проверяем, участвует ли пользователь в встрече
    const participantCheck = await pool.query(`
      SELECT * FROM meeting_participants 
      WHERE meeting_id = $1 AND user_id = $2
    `, [id, user_id]);

    if (participantCheck.rows.length === 0) {
      return res.status(400).json({ error: 'Вы не участвуете в этой встрече' });
    }

    // Удаляем пользователя из участников
    await pool.query(`
      DELETE FROM meeting_participants 
      WHERE meeting_id = $1 AND user_id = $2
    `, [id, user_id]);

    // Очистить кеш
    await redisClient.del('meetings:all');

    // Возвращаем обновлённую встречу
    const meetingResult = await pool.query(`
      SELECT m.*, p.name as place_name, p.address, p.latitude, p.longitude,
             u.name as organizer_name, u.avatar_url as organizer_avatar
      FROM meetings m
      LEFT JOIN places p ON m.place_id = p.id
      LEFT JOIN users u ON m.organizer_id = u.id
      WHERE m.id = $1
    `, [id]);

    const participants = await pool.query(`
      SELECT u.id, u.name, u.avatar_url, u.email, mp.joined_at
      FROM meeting_participants mp
      JOIN users u ON mp.user_id = u.id
      WHERE mp.meeting_id = $1
    `, [id]);

    res.json({
      ...meetingResult.rows[0],
      participants: participants.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Удалить встречу (требуется авторизация, только создатель)
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const user_id = req.user.id;

    // Проверяем, является ли пользователь организатором
    const meeting = await pool.query(
      'SELECT organizer_id FROM meetings WHERE id = $1',
      [id]
    );

    if (meeting.rows.length === 0) {
      return res.status(404).json({ error: 'Встреча не найдена' });
    }

    if (meeting.rows[0].organizer_id !== user_id) {
      return res.status(403).json({ error: 'Только организатор может удалить встречу' });
    }

    await pool.query('DELETE FROM meetings WHERE id = $1', [id]);

    // Очистить кеш
    await redisClient.del('meetings:all');

    res.json({ message: 'Встреча удалена' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
