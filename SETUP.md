# Meetup - Полное руководство по запуску

## Шаг 1: Установка PostgreSQL и Redis

### Вариант 1: Docker (рекомендуется)

```powershell
# PostgreSQL
docker run -d --name meetup-postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres

# Redis  
docker run -d --name meetup-redis -p 6379:6379 redis
```

### Вариант 2: Установка вручную

**PostgreSQL:**
- Скачать: https://www.postgresql.org/download/windows/
- Установить (пароль: `postgres`, порт: `5432`)

**Redis:**
- Скачать Memurai: https://www.memurai.com/
- Или Redis для Windows: https://github.com/microsoftarchive/redis/releases

## Шаг 2: Запуск Backend

```powershell
# Перейти в папку backend
cd backend

# Установить зависимости
npm install

# Запустить сервер
npm run dev
```

Сервер запустится на http://localhost:3000

### Проверка работы:

```powershell
# Откройте в браузере или через curl
curl http://localhost:3000/health
```

Должно вернуть:
```json
{
  "status": "OK",
  "database": "connected",
  "redis": "connected"
}
```

## Шаг 3: Запуск Flutter приложения

```powershell
# В другом терминале, вернитесь в корень проекта
cd ..

# Установите зависимости Flutter
flutter pub get

# Запустите приложение в Chrome
flutter run -d chrome
```

## Структура проекта

```
meetup/
├── backend/              # Node.js Backend
│   ├── config/          # Настройки БД и Redis
│   ├── models/          # Схемы таблиц
│   ├── routes/          # API endpoints
│   ├── server.js        # Главный файл
│   └── package.json
│
├── lib/                 # Flutter приложение
│   ├── data/
│   │   ├── models/     # Модели данных
│   │   └── services/   # API сервисы
│   ├── presentation/   # UI
│   └── main.dart
│
└── pubspec.yaml
```

## API Endpoints

### Аутентификация
- `POST /api/auth/register` - Регистрация
- `POST /api/auth/login` - Вход

### Встречи
- `GET /api/meetings` - Все встречи
- `GET /api/meetings/:id` - Детали встречи
- `POST /api/meetings` - Создать встречу
- `POST /api/meetings/:id/join` - Присоединиться

### Пользователи
- `GET /api/users/:id` - Профиль
- `PUT /api/users/:id` - Обновить профиль

### Места
- `GET /api/places` - Все места
- `POST /api/places` - Создать место

## Тестирование API

### Регистрация:
```powershell
curl -X POST http://localhost:3000/api/auth/register `
  -H "Content-Type: application/json" `
  -d '{"email":"test@test.ru","password":"12345","name":"Тест"}'
```

### Вход:
```powershell
curl -X POST http://localhost:3000/api/auth/login `
  -H "Content-Type: application/json" `
  -d '{"email":"test@test.ru","password":"12345"}'
```

### Создать место:
```powershell
curl -X POST http://localhost:3000/api/places `
  -H "Content-Type: application/json" `
  -d '{"name":"Парк Горького","address":"Москва, Крымский Вал","latitude":55.731,"longitude":37.603}'
```

### Создать встречу:
```powershell
curl -X POST http://localhost:3000/api/meetings `
  -H "Content-Type: application/json" `
  -d '{"title":"Встреча разработчиков","description":"Обсуждение проектов","place_id":1,"organizer_id":1,"start_time":"2026-01-25T18:00:00","max_participants":10}'
```

## Возможные проблемы

### PostgreSQL не подключается:
- Проверьте что PostgreSQL запущен
- Проверьте пароль в файле `.env`
- Проверьте порт 5432

### Redis не подключается:
- Проверьте что Redis/Memurai запущен
- Проверьте порт 6379

### Flutter не видит backend:
- Убедитесь что backend запущен на порту 3000
- Проверьте `lib/core/constants/api_constants.dart`
- Для реального устройства измените `localhost` на IP компьютера

## Следующие шаги

1. ✅ Backend с PostgreSQL и Redis
2. ✅ Flutter подключен к backend
3. 🔄 Реализовать UI для Flutter
4. 🔄 Добавить WebSocket для чата
5. 🔄 Добавить аутентификацию в Flutter
6. 🔄 Добавить карты (Yandex Maps)
