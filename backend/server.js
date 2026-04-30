const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

const pool = require('./config/database');
const redisClient = require('./config/redis');
const { createTables } = require('./models/schema');
const { runMigration } = require('./migrations/add_reviews_and_photos');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Создание таблиц при запуске
createTables();
runMigration();

// Базовый маршрут
app.get('/', (req, res) => {
  res.json({ 
    message: 'Meetup API работает!',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      users: '/api/users',
      meetings: '/api/meetings',
      places: '/api/places',
      chat: '/api/chat',
      notifications: '/api/notifications'
    }
  });
});

// Проверка здоровья сервера
app.get('/health', async (req, res) => {
  try {
    // Проверка PostgreSQL
    await pool.query('SELECT 1');
    
    // Проверка Redis
    await redisClient.ping();
    
    res.json({ 
      status: 'OK',
      database: 'connected',
      redis: 'connected',
      timestamp: new Date()
    });
  } catch (err) {
    res.status(500).json({ 
      status: 'ERROR',
      error: err.message 
    });
  }
});

// API Routes (будем добавлять постепенно)
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/meetings', require('./routes/meetings'));
app.use('/api/places', require('./routes/places'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/meetings', require('./routes/chat')); // Чат внутри встреч
app.use('/api/admin', require('./routes/admin')); // Админ-панель
app.use('/api/reviews', require('./routes/reviews')); // Отзывы о местах
app.use('/api/photos', require('./routes/photos')); // Фото мест

// Обработка ошибок
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Что-то пошло не так!',
    message: err.message 
  });
});

// Запуск сервера
app.listen(PORT, () => {
  console.log(`\n🚀 Сервер запущен на http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health\n`);
});
