# API Тесты для Meetup Backend

## Тестирование создания встречи

### 1. Создание места
```bash
curl -X POST http://localhost:3000/api/places \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Парк Горького",
    "address": "г. Москва, ул. Крымский Вал, 9",
    "latitude": 55.7311,
    "longitude": 37.6019,
    "description": "Центральный парк культуры и отдыха",
    "image_url": "https://example.com/park.jpg"
  }'
```

### 2. Регистрация пользователя
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Тестовый Пользователь"
  }'
```

### 3. Создание встречи
```bash
curl -X POST http://localhost:3000/api/meetings \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Встреча разработчиков",
    "description": "Обсуждение новых технологий",
    "placeId": 1,
    "category": "Технологии",
    "dateTime": "2026-01-25T14:00:00",
    "duration": 120,
    "maxParticipants": 15,
    "budget": 1000,
    "organizerId": 1
  }'
```

### 4. Присоединиться к встрече
```bash
curl -X POST http://localhost:3000/api/meetings/1/join \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 2
  }'
```

### 5. Получить все встречи
```bash
curl http://localhost:3000/api/meetings
```

### 6. Получить уведомления
```bash
curl http://localhost:3000/api/notifications?userId=1
```

### 7. Проверить количество непрочитанных уведомлений
```bash
curl http://localhost:3000/api/notifications/unread-count?userId=1
```

## Проверка данных в базе

### Проверить созданные встречи
```sql
SELECT m.*, p.name as place_name, u.name as organizer_name 
FROM meetings m
LEFT JOIN places p ON m.place_id = p.id
LEFT JOIN users u ON m.organizer_id = u.id;
```

### Проверить участников встреч
```sql
SELECT mp.*, m.title, u.name 
FROM meeting_participants mp
JOIN meetings m ON mp.meeting_id = m.id
JOIN users u ON mp.user_id = u.id;
```

### Проверить уведомления
```sql
SELECT n.*, u.name 
FROM notifications n
JOIN users u ON n.user_id = u.id
ORDER BY n.created_at DESC;
```

## PowerShell команды для тестирования

### Создание встречи
```powershell
$body = @{
    title = "Встреча разработчиков"
    description = "Обсуждение новых технологий"
    placeId = 1
    category = "Технологии"
    dateTime = "2026-01-25T14:00:00"
    duration = 120
    maxParticipants = 15
    budget = 1000
    organizerId = 1
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/meetings" -Method Post -Body $body -ContentType "application/json"
```

### Регистрация пользователя
```powershell
$body = @{
    email = "test@example.com"
    password = "password123"
    name = "Тестовый Пользователь"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/auth/register" -Method Post -Body $body -ContentType "application/json"
```
