const redis = require('redis');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const redisClient = redis.createClient({
  socket: {
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT,
  },
});

redisClient.on('connect', () => {
  console.log('✓ Подключено к Redis');
});

redisClient.on('error', (err) => {
  console.error('❌ Ошибка Redis:', err);
});

// Подключение к Redis
(async () => {
  try {
    await redisClient.connect();
  } catch (err) {
    console.error('Не удалось подключиться к Redis:', err);
  }
})();

module.exports = redisClient;
