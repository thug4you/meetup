# 📍 Meetup – Приложение для организации встреч

**Полнофункциональное приложение** для поиска и организации встреч с друзьями, коллегами и единомышленниками.

## 🎯 Основные возможности

- 🔐 **Аутентификация** через JWT с шифрованием паролей
- 📅 **Организация встреч** с выбором места, времени и количества участников
- 🗺️ **Поиск мест** для встреч (кафе, парки, офисы и т. д.)
- 💬 **Встроенный чат** для участников встреч
- 🔔 **Система уведомлений** (в реальном времени через WebSocket)
- 👥 **Профили пользователей** с рейтингами и историей встреч
- 🎛️ **Админ-панель** для управления пользователями и встречами
- 🏷️ **Категоризация и фильтрация** встреч по интересам

## 🛠️ Технологический стек

### Frontend
- **Flutter** + **Dart** – web-приложение
- **Provider** – управление состоянием
- **HTTP-клиент** – взаимодействие с API

### Backend
- **Node.js** + **Express** – REST API и WebSocket
- **PostgreSQL** – основная база данных
- **Redis** – кеширование и очереди
- **JWT** – авторизация
- **bcrypt** – хеширование паролей

### DevOps
- **Docker** (опционально) – контейнеризация

## 📂 Структура проекта

```
meetup/
├── backend/                    # Node.js API сервер
│   ├── config/                 # Конфигурация БД и Redis
│   ├── models/                 # Схемы и логика работы с данными
│   ├── routes/                 # API эндпоинты
│   │   ├── auth.js             # Аутентификация
│   │   ├── users.js            # Управление пользователями
│   │   ├── meetings.js         # Встречи
│   │   ├── places.js           # Места
│   │   ├── chat.js             # Чат
│   │   ├── notifications.js    # Уведомления
│   │   └── admin.js            # Админ-функции
│   ├── migrations/             # Миграции БД
│   ├── middleware/             # Middleware (авторизация и т. д.)
│   ├── server.js               # Главный файл
│   └── package.json            # Зависимости Node.js
│
├── lib/                        # Flutter приложение
│   ├── main.dart               # Точка входа
│   ├── config/                 # Конфигурация и константы
│   ├── core/                   # Ядро (утилиты, сервисы)
│   ├── data/                   # Работа с данными (API, БД)
│   └── presentation/           # UI (экраны и виджеты)
│
├── pubspec.yaml                # Зависимости Flutter
├── SETUP.md                    # Подробное руководство по установке
└── README.md                   # Этот файл
```

## 📋 Требования

- **Flutter SDK** (3.0+)
- **Node.js** (18+)
- **PostgreSQL** (14+)
- **Redis** (6+)
- **npm** или **yarn**

## 🚀 Быстрый старт

### Вариант 1: С Docker (рекомендуется)

1. **Запустите базы данных:**

```bash
docker run -d --name meetup-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres:14

docker run -d --name meetup-redis \
  -p 6379:6379 \
  redis:7
```

2. **Создайте базу данных:**

```bash
psql -U postgres -h localhost -c "CREATE DATABASE meetup_db;"
```

3. **Установите зависимости и запустите backend:**

```bash
cd backend
npm install
npm start
```

4. **В другом терминале запустите Flutter приложение:**

```bash
cd ..
flutter pub get
flutter run -d chrome
```

### Вариант 2: Локальная установка PostgreSQL и Redis

Если Docker недоступен:

1. **Установите PostgreSQL и Redis:**
   - PostgreSQL: https://www.postgresql.org/download/windows/
   - Redis (Memurai для Windows): https://www.memurai.com/

2. **Создайте базу данных:**
   - Откройте pgAdmin или используйте `psql`
   - Создайте БД: `CREATE DATABASE meetup_db;`

3. **Следуйте шагам 3-4 из Варианта 1**

## ⚙️ Конфигурация

### Переменные окружения Backend

Создайте файл `backend/.env`:

```env
# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=meetup_db
DB_USER=postgres
DB_PASSWORD=postgres

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Сервер
PORT=3000
NODE_ENV=development

# JWT
JWT_SECRET=your_super_secret_key_change_this_in_production

# CORS (если нужно)
CORS_ORIGIN=http://localhost:3000
```

## 📡 API Эндпоинты

### Аутентификация (`/api/auth`)
- `POST /api/auth/register` – регистрация нового пользователя
- `POST /api/auth/login` – вход в систему
- `POST /api/auth/logout` – выход

### Пользователи (`/api/users`)
- `GET /api/users/:id` – получить профиль
- `PUT /api/users/:id` – обновить профиль
- `GET /api/users/:id/meetings` – встречи пользователя

### Встречи (`/api/meetings`)
- `GET /api/meetings` – список всех встреч
- `GET /api/meetings/:id` – детали встречи
- `POST /api/meetings` – создать встречу
- `PUT /api/meetings/:id` – редактировать встречу
- `POST /api/meetings/:id/join` – присоединиться к встрече
- `POST /api/meetings/:id/leave` – покинуть встречу

### Места (`/api/places`)
- `GET /api/places` – список мест
- `POST /api/places` – создать место
- `PUT /api/places/:id` – редактировать место

### Чат (`/api/chat`)
- `WS /api/chat/:meetingId` – WebSocket для чата встречи
- `GET /api/chat/:meetingId/messages` – история сообщений

### Уведомления (`/api/notifications`)
- `GET /api/notifications` – список уведомлений
- `PUT /api/notifications/:id/read` – отметить как прочитанное

### Админ (`/api/admin`)
- `GET /api/admin/users` – список всех пользователей
- `DELETE /api/admin/users/:id` – удалить пользователя
- `GET /api/admin/stats` – статистика

## 🧪 Тестирование API

### Пример: Регистрация

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "securePassword123",
    "name": "Иван Петров"
  }'
```

### Пример: Вход

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "securePassword123"
  }'
```

### Проверка здоровья сервера

```bash
curl http://localhost:3000/health
```

Ответ:
```json
{
  "status": "OK",
  "database": "connected",
  "redis": "connected"
}
```

## 📚 Полезные команды

### Backend

```bash
# Запуск с автоперезагрузкой (требует nodemon)
npm run dev

# Обычный запуск
npm start

# Проверка конфигурации БД
npm run check-schema

# Создание админ-пользователя
npm run create-admin

# Добавление роли пользователю
npm run add-role
```

### Flutter

```bash
# Получить зависимости
flutter pub get

# Запустить на web (Chrome)
flutter run -d chrome

# Собрать web-версию для production
flutter build web

# Список доступных устройств
flutter devices

# Обновления пакетов
flutter pub outdated
```

## ⚠️ Типичные проблемы и решения

### PostgreSQL не подключается
- Проверьте, запущен ли PostgreSQL: `psql -U postgres`
- Убедитесь, что параметры в `.env` верны (хост, порт, пароль)
- Проверьте файл брандмауэра Windows (позволить порт 5432)

### Redis не подключается
- Проверьте, запущен ли Redis/Memurai
- Убедитесь, что он слушает на порту 6379
- Для Memurai: проверьте, установлен ли как сервис

### `/health` возвращает ошибку
Вероятные причины:
- БД не запущена или неверные учетные данные
- Redis не запущена
- Миграции не применены

Решение:
```bash
# Перепроверьте подключение
npm run check-users  # проверить подключение к БД
```

### Flutter не может подключиться к backend
- Убедитесь, что backend запущен на `http://localhost:3000`
- На физическом устройстве используйте IP компьютера вместо `localhost`
- Проверьте файл `lib/core/constants/api_constants.dart`

## 📖 Дополнительная информация

- Подробное руководство по установке: см. [SETUP.md](SETUP.md)
- Документация API: см. [backend/API_TESTS.md](backend/API_TESTS.md)
- Улучшения БД: см. [backend/DATABASE_IMPROVEMENTS.md](backend/DATABASE_IMPROVEMENTS.md)

## 🔐 Безопасность

- Все пароли хешируются с помощью **bcrypt**
- Авторизация через **JWT**-токены
- CORS настроен для безопасности
- В production обязательно:
  - Изменить `JWT_SECRET`
  - Использовать HTTPS
  - Установить сильный пароль для БД

## 📝 Лицензия

MIT License – свободно используйте и распространяйте.
