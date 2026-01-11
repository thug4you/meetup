import 'package:dio/dio.dart';
import '../models/user.dart';
import '../models/meeting.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService;

  UserService(this._apiService);

  // Получить профиль пользователя
  Future<User> getUserProfile(String userId) async {
    try {
      final response = await _apiService.get('/users/$userId');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Получить текущего пользователя
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiService.get('/users/me');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Обновить профиль
  Future<User> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
    List<String>? interests,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;
      if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
      if (interests != null) data['interests'] = interests;

      final response = await _apiService.put('/users/me', data: data);
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Получить встречи созданные пользователем
  Future<List<Meeting>> getCreatedMeetings(String userId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiService.get(
        '/users/$userId/meetings/created',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data['meetings'] ?? [];
      return data.map((json) => Meeting.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Получить встречи, в которых участвует пользователь
  Future<List<Meeting>> getJoinedMeetings(String userId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiService.get(
        '/users/$userId/meetings/joined',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data['meetings'] ?? [];
      return data.map((json) => Meeting.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Загрузить аватар
  Future<String> uploadAvatar(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiService.post('/users/me/avatar', data: formData);
      return response.data['avatarUrl'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'] as String;
      }
      return 'Ошибка: ${e.response!.statusCode}';
    }
    return 'Ошибка сети: ${e.message}';
  }
}
