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

      final List<dynamic> data = response.data['meetings'] ?? [];
      return data.map((json) => Meeting.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Получить детали встречи
  Future<Meeting> getMeetingById(String id) async {
    try {
      final response = await _apiService.get('/api/meetings/$id');
      return Meeting.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
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
    required String placeId,
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
          'placeId': placeId,
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
        '/meetings/$id',
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
      await _apiService.delete('/meetings/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Присоединиться к встрече
  Future<Meeting> joinMeeting(String id) async {
    try {
      final response = await _apiService.post('/meetings/$id/join');
      return Meeting.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Покинуть встречу
  Future<Meeting> leaveMeeting(String id) async {
    try {
      final response = await _apiService.post('/meetings/$id/leave');
      return Meeting.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Сохранить встречу в избранное
  Future<void> saveMeeting(String id) async {
    try {
      await _apiService.post('/meetings/$id/save');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Удалить из избранного
  Future<void> unsaveMeeting(String id) async {
    try {
      await _apiService.delete('/meetings/$id/save');
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

      final List<dynamic> data = response.data['places'] ?? [];
      return data.map((json) => Place.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'];
      return message ?? 'Произошла ошибка при обработке запроса';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Превышено время ожидания подключения';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Превышено время ожидания ответа';
    } else {
      return 'Ошибка подключения к серверу';
    }
  }
}
