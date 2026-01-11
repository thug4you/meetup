class ApiConstants {
  // Base URL для API (замените на реальный адрес backend)
  static const String baseUrl = 'http://localhost:3000';
  
  // GraphQL endpoint
  static const String graphqlEndpoint = '$baseUrl/graphql';
  
  // WebSocket endpoint для чата
  static const String wsEndpoint = 'ws://localhost:3000/ws';
  
  // Endpoints
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authLogout = '/auth/logout';
  static const String authRefresh = '/auth/refresh';
  
  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Yandex Maps API
  static const String yandexMapsApiKey = 'YOUR_YANDEX_MAPS_API_KEY';
  static const String yandexGeocoderUrl = 'https://geocode-maps.yandex.ru/1.x/';
}
