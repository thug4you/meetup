# Meetup Backend API

Backend сервер для приложения Meetup на Node.js с PostgreSQL и Redis.

## Установка PostgreSQL и Redis

### Windows:

**PostgreSQL:**
1. Скачать: https://www.postgresql.org/download/windows/
2. Установить (пароль по умолчанию: `postgres`)
3. Или через Chocolatey: `choco install postgresql`

**Redis:**
1. Скачать: https://github.com/microsoftarchive/redis/releases
2. Или использовать Docker: `docker run -d -p 6379:6379 redis`
3. Или Memurai (Redis для Windows): https://www.memurai.com/

### Через Docker (проще):

```bash
# PostgreSQL
docker run -d --name meetup-postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres

# Redis
docker run -d --name meetup-redis -p 6379:6379 redis
```

## Установка зависимостей

```bash
cd backend
npm install
```

## Настройка

1. Скопируйте `.env.example` в `.env`:
```bash
copy .env.example .env
```

2. Отредактируйте `.env` с вашими настройками базы данных

## Запуск

### Разработка (с автоперезагрузкой):
```bash
npm run dev
```

### Продакшн:
```bash
npm start
```

Сервер запустится на http://localhost:3000

## API Endpoints

### Аутентификация
- `POST /api/auth/register` - Регистрация
- `POST /api/auth/login` - Вход

### Пользователи
- `GET /api/users/:id` - Получить профиль
- `PUT /api/users/:id` - Обновить профиль

### Встречи
- `GET /api/meetings` - Все встречи (кешируется в Redis)
- `GET /api/meetings/:id` - Детали встречи
- `POST /api/meetings` - Создать встречу
- `POST /api/meetings/:id/join` - Присоединиться к встрече

### Места
- `GET /api/places` - Все места
- `POST /api/places` - Создать место

## Проверка работы

```bash
# Проверка здоровья сервера
curl http://localhost:3000/health

# Регистрация
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"12345","name":"Test User"}'
```

## Структура базы данных

- `users` - Пользователи
- `places` - Места для встреч
- `meetings` - Встречи
- `meeting_participants` - Участники встреч
- `messages` - Сообщения чата
- `notifications` - Уведомления
- `reports` - Жалобы

## Использование Redis

Redis используется для:
- Кеширования списка встреч (5 минут TTL)
- Сессий пользователей (в будущем)
- Real-time функционала

## Безопасность

- Пароли хешируются с bcrypt
- JWT токены для авторизации
- CORS настроен для Flutter приложения
