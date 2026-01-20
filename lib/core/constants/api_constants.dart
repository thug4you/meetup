class ApiConstants {
  // Base URL для API (замените на реальный адрес backend)
  static const String baseUrl = 'http://localhost:3000';
  
  // GraphQL endpoint
  static const String graphqlEndpoint = '$baseUrl/graphql';
  
  // WebSocket endpoint для чата
  static const String wsEndpoint = 'ws://localhost:3000/ws';
  
  // Endpoints
  static const String authLogin = '/api/auth/login';
  static const String authRegister = '/api/auth/register';
  static const String authLogout = '/api/auth/logout';
  static const String authRefresh = '/api/auth/refresh';
  
  // Users
  static const String users = '/api/users';
  
  // Meetings
  static const String meetings = '/api/meetings';
  
  // Places
  static const String places = '/api/places';
  
  // Chat
  static const String chat = '/api/chat';
  
  // Notifications
  static const String notifications = '/api/notifications';
  
  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Yandex Maps API
  static const String yandexMapsApiKey = '18d1f891-dda9-4404-a254-1dbebc8f26a7';
  static const String yandexGeocoderUrl = 'https://geocode-maps.yandex.ru/1.x/';
}
