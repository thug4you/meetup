import 'package:dio/dio.dart';
import '../models/meeting.dart';
import '../models/place.dart';
import 'api_service.dart';

class MeetingService {
  final ApiService _apiService;

  MeetingService(this._apiService);

  // Получить список встреч с фильтрами
  Future<List<Meeting>> getMeetings({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    double? radius,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (category != null) queryParams['category'] = category;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (radius != null) queryParams['radius'] = radius;

      final response = await _apiService.get(
        '/api/meetings',
        queryParameters: queryParams,
      );

      final responseData = response.data;
      final List<dynamic> data = responseData is Map ? (responseData['meetings'] ?? []) : [];
      return data
          .where((json) => json is Map<String, dynamic>)
          .map((json) => Meeting.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Ошибка загрузки встреч: $e');
    }
  }

  // Получить детали встречи
  Future<Meeting> getMeetingById(String id) async {
    try {
      final response = await _apiService.get('/api/meetings/$id');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Неверный формат ответа сервера');
      }
      return Meeting.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Ошибка загрузки встречи: $e');
    }
  }

  // Создать встречу
  Future<Meeting> createMeeting({
    required String title,
    required String description,
    required String category,
    required DateTime dateTime,
    required int duration,
    required int maxParticipants,
    String? placeId, // Сделали опциональным
    double? budget,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/meetings',
        data: {
          'title': title,
          'description': description,
          'category': category,
          'dateTime': dateTime.toIso8601String(),
          'duration': duration,
          'maxParticipants': maxParticipants,
          'placeId': placeId ?? '', // Пустая строка если null
          'budget': budget,
        },
      );

      return Meeting.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Обновить встречу
  Future<Meeting> updateMeeting(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.put(
        '/api/meetings/$id',
        data: updates,
      );

      return Meeting.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Удалить встречу
  Future<void> deleteMeeting(String id) async {
    try {
      await _apiService.delete('/api/meetings/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Присоединиться к встрече
  Future<Meeting> joinMeeting(String id) async {
    try {
      final response = await _apiService.post('/api/meetings/$id/join');
      final data = response.data;
      
      // Бэкенд возвращает { message: '...' } если пользователь уже участник
      if (data is Map<String, dynamic> && data.containsKey('message') && !data.containsKey('id')) {
        // Уже участвует — загружаем актуальные данные встречи
        final meetingResponse = await _apiService.get('/api/meetings/$id');
        return Meeting.fromJson(meetingResponse.data as Map<String, dynamic>);
      }
      
      if (data is! Map<String, dynamic>) {
        // Ответ не является объектом встречи — загружаем данные отдельно
        final meetingResponse = await _apiService.get('/api/meetings/$id');
        return Meeting.fromJson(meetingResponse.data as Map<String, dynamic>);
      }
      
      return Meeting.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Ошибка при присоединении к встрече: $e');
    }
  }

  // Покинуть встречу
  Future<Meeting> leaveMeeting(String id) async {
    try {
      final response = await _apiService.post('/api/meetings/$id/leave');
      final data = response.data;
      
      // Бэкенд может вернуть { error: '...' } если пользователь не участвует
      if (data is! Map<String, dynamic> || !data.containsKey('id')) {
        final meetingResponse = await _apiService.get('/api/meetings/$id');
        return Meeting.fromJson(meetingResponse.data as Map<String, dynamic>);
      }
      
      return Meeting.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Ошибка при выходе из встречи: $e');
    }
  }

  // Сохранить встречу в избранное
  Future<void> saveMeeting(String id) async {
    try {
      await _apiService.post('/api/meetings/$id/save');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Удалить из избранного
  Future<void> unsaveMeeting(String id) async {
    try {
      await _apiService.delete('/api/meetings/$id/save');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Поиск мест для встречи
  Future<List<Place>> searchPlaces({
    required String query,
    String? category,
    double? lat,
    double? lng,
    double? radius,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'query': query,
      };

      if (category != null) queryParams['category'] = category;
      if (lat != null) queryParams['lat'] = lat;
      if (lng != null) queryParams['lng'] = lng;
      if (radius != null) queryParams['radius'] = radius;

      final response = await _apiService.get(
        '/api/places/search',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data is List ? response.data : (response.data['places'] ?? response.data ?? []);
      return data.map((json) => Place.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Создать новое место
  Future<Place> createPlace({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/places',
        data: {
          'name': name,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'description': description,
          'image_url': imageUrl,
        },
      );

      return Place.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    String message;
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map) {
        message = data['message'] as String? ?? data['error'] as String? ?? 'Произошла ошибка при обработке запроса';
      } else {
        message = 'Произошла ошибка при обработке запроса';
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Превышено время ожидания подключения';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Превышено время ожидания ответа';
    } else {
      message = 'Ошибка подключения к серверу';
    }
    return Exception(message);
  }
}
