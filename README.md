# Meetup

Полноценное приложение для организации встреч:
- Flutter-клиент (web/desktop/mobile)
- Node.js backend API
- PostgreSQL для основной базы данных
- Redis для кеша и realtime-задач

## Стек

- Flutter + Dart
- Node.js + Express
- PostgreSQL
- Redis
- JWT (авторизация)

## Структура проекта

```text
meetup/
	lib/                 # Flutter-клиент
	backend/             # Node.js API
		config/            # Подключения к БД и Redis
		routes/            # API-маршруты
		models/            # Схема/логика таблиц
		migrations/        # Миграции
```

## Требования

- Flutter SDK
- Node.js 18+
- PostgreSQL 14+
- Redis 6+

## Быстрый старт

### 1. Установка зависимостей

В корне проекта:

```bash
flutter pub get
```

В папке backend:

```bash
cd backend
npm install
```

### 2. Настройка окружения backend

Скопируйте файл с примером переменных:

```bash
cd backend
copy .env.example .env
```

Заполните `backend/.env`:

```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=meetup_db
DB_USER=postgres
DB_PASSWORD=your_password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Server
PORT=3000
JWT_SECRET=your_secret_key_change_this

# Environment
NODE_ENV=development
```

### 3. Поднимите PostgreSQL и Redis

Вариант через Docker:

```bash
docker run -d --name meetup-postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres
docker run -d --name meetup-redis -p 6379:6379 redis
```

Создайте базу данных `meetup_db` в PostgreSQL.

### 4. Запуск backend

```bash
cd backend
npm start
```

Backend по умолчанию доступен на `http://localhost:3000`.

Проверка здоровья:

```bash
curl http://localhost:3000/health
```

### 5. Запуск Flutter-клиента

Из корня проекта:

```bash
flutter run -d chrome
```

Или для Windows desktop:

```bash
flutter run -d windows
```

## Полезные команды

Backend:

```bash
npm run dev   # запуск с nodemon
npm start     # обычный запуск
```

Flutter:

```bash
flutter devices
flutter pub outdated
```

## Типичные проблемы

### `/health` возвращает `ERROR`

Проверьте:
- Запущен ли PostgreSQL на порту `5432`
- Запущен ли Redis на порту `6379`
- Совпадают ли значения в `backend/.env`

### Ошибка подключения к Redis при старте

Если потом в логах появляется `Подключено к Redis`, это обычно кратковременный таймаут при запуске.

## API

Основные префиксы маршрутов:
- `/api/auth`
- `/api/users`
- `/api/meetings`
- `/api/places`
- `/api/notifications`
- `/api/admin`

## Лицензия

Добавьте нужную лицензию (например, MIT), если планируете публиковать репозиторий публично.
