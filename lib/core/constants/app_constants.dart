class AppConstants {
  // App info
  static const String appName = 'MeetUp';
  static const String appVersion = '1.0.0';
  
  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';
  
  // Categories для встреч
  static const List<String> meetingCategories = [
    'Кафе/Бар',
    'Прогулка',
    'Спорт',
    'Культура',
    'Развлечения',
    'Обучение',
    'Хобби',
    'Другое',
  ];
  
  // Интересы пользователей
  static const List<String> interests = [
    'Спорт',
    'Музыка',
    'Кино',
    'Путешествия',
    'Фотография',
    'Кулинария',
    'Книги',
    'Игры',
    'Искусство',
    'Технологии',
    'Мода',
    'Природа',
    'Животные',
    'Автомобили',
    'Танцы',
    'Йога',
    'Медитация',
    'Бизнес',
    'Наука',
    'История',
  ];
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Map defaults
  static const double defaultZoom = 12.0;
  static const double defaultLatitude = 55.7558; // Москва
  static const double defaultLongitude = 37.6173;
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 64;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  
  // Meeting limits
  static const int minParticipants = 2;
  static const int maxParticipants = 50;
  static const int defaultParticipants = 5;
}
