import 'package:dio/dio.dart';
import '../models/meeting.dart';
import '../models/place.dart';
import '../models/place_review.dart';
import '../models/place_photo.dart';
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
      final meetings = data
          .where((json) => json is Map<String, dynamic>)
          .map((json) => Meeting.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Дополнительный фильтр: исключаем завершённые встречи и встречи, время которых прошло
      final now = DateTime.now();
      return meetings.where((m) {
        final isCompleted = m.status == MeetingStatus.completed;
        final hasPassed = m.endTime.isBefore(now);
        return !isCompleted && !hasPassed;
      }).toList();
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
          if (placeId != null) 'placeId': placeId,
          if (budget != null) 'budget': budget,
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

  // Поиск мест для встречи (с фильтрами)
  Future<List<Place>> searchPlaces({
    String? query,
    String? category,
    double? lat,
    double? lng,
    double? radius,
    double? minBill,
    double? maxBill,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (query != null && query.isNotEmpty) queryParams['query'] = query;
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      if (lat != null) queryParams['lat'] = lat;
      if (lng != null) queryParams['lng'] = lng;
      if (radius != null) queryParams['radius'] = radius;
      if (minBill != null) queryParams['min_bill'] = minBill;
      if (maxBill != null) queryParams['max_bill'] = maxBill;

      final response = await _apiService.get(
        '/api/places/search',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data is List ? response.data : (response.data['places'] ?? response.data ?? []);
      return data
          .where((json) => json is Map<String, dynamic>)
          .map((json) => Place.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Ошибка поиска заведений: $e');
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
    String? category,
    double? averageBill,
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
          'category': category,
          'average_bill': averageBill,
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

  // Получить отзывы о месте
  Future<List<PlaceReview>> getPlaceReviews(String placeId) async {
    try {
      final response = await _apiService.get('/api/reviews/place/$placeId');
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .where((json) => json is Map<String, dynamic>)
          .map((json) => PlaceReview.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Ошибка загрузки отзывов: $e');
    }
  }

  // Получить рейтинг места
  Future<PlaceRating> getPlaceRating(String placeId) async {
    try {
      final response = await _apiService.get('/api/reviews/place/$placeId/rating');
      return PlaceRating.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Ошибка загрузки рейтинга: $e');
    }
  }

  // Создать отзыв
  Future<PlaceReview> createReview({
    required String placeId,
    required int rating,
    String? text,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/reviews',
        data: {
          'placeId': placeId,
          'rating': rating,
          if (text != null) 'text': text,
        },
      );
      return PlaceReview.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Ошибка создания отзыва: $e');
    }
  }

  // Обновить отзыв
  Future<PlaceReview> updateReview({
    required String reviewId,
    int? rating,
    String? text,
  }) async {
    try {
      final response = await _apiService.put(
        '/api/reviews/$reviewId',
        data: {
          if (rating != null) 'rating': rating,
          if (text != null) 'text': text,
        },
      );
      return PlaceReview.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Ошибка обновления отзыва: $e');
    }
  }

  // Удалить отзыв
  Future<void> deleteReview(String reviewId) async {
    try {
      await _apiService.delete('/api/reviews/$reviewId');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Ошибка удаления отзыва: $e');
    }
  }

  // Получить фото места
  Future<List<PlacePhoto>> getPlacePhotos(String placeId, {int limit = 10}) async {
    try {
      final response = await _apiService.get(
        '/api/photos/place/$placeId',
        queryParameters: {'limit': limit},
      );
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .where((json) => json is Map<String, dynamic>)
          .map((json) => PlacePhoto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Ошибка загрузки фото: $e');
    }
  }

  // Загрузить фото места
  Future<PlacePhoto> uploadPlacePhoto({
    required String placeId,
    required String photoUrl,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/photos',
        data: {
          'placeId': placeId,
          'photoUrl': photoUrl,
        },
      );
      return PlacePhoto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Ошибка загрузки фото: $e');
    }
  }

  // Удалить фото
  Future<void> deletePhoto(String photoId) async {
    try {
      await _apiService.delete('/api/photos/$photoId');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Ошибка удаления фото: $e');
    }
  }

  // Создать уведомление о завершённой встречи
  Future<void> createMeetingEndedNotification(String meetingId) async {
    try {
      await _apiService.post('/api/notifications/meeting-ended/$meetingId', data: {});
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Ошибка создания уведомления: $e');
    }
  }
}
