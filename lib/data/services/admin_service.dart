import '../models/user.dart';
import '../models/meeting.dart';
import 'api_service.dart';

class AdminService {
  final ApiService _apiService;

  AdminService(this._apiService);

  // ==================== СТАТИСТИКА ====================
  
  Future<Map<String, dynamic>> getStats() async {
    final response = await _apiService.get('/api/admin/stats');
    return response.data as Map<String, dynamic>;
  }

  // ==================== ПОЛЬЗОВАТЕЛИ ====================
  
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    final response = await _apiService.get(
      '/api/admin/users',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search.isNotEmpty) 'search': search,
      },
    );
    
    final data = response.data as Map<String, dynamic>;
    return {
      'users': (data['users'] as List)
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList(),
      'total': data['total'] as int,
      'page': data['page'] as int,
      'limit': data['limit'] as int,
    };
  }

  Future<User> getUser(String userId) async {
    final response = await _apiService.get('/api/admin/users/$userId');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _apiService.put(
      '/api/admin/users/$userId/role',
      data: {'role': role},
    );
  }

  Future<void> deleteUser(String userId) async {
    await _apiService.delete('/api/admin/users/$userId');
  }

  // ==================== ВСТРЕЧИ ====================
  
  Future<Map<String, dynamic>> getMeetings({
    int page = 1,
    int limit = 20,
    String status = '',
    String search = '',
  }) async {
    final response = await _apiService.get(
      '/api/admin/meetings',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status.isNotEmpty) 'status': status,
        if (search.isNotEmpty) 'search': search,
      },
    );
    
    final data = response.data as Map<String, dynamic>;
    return {
      'meetings': (data['meetings'] as List)
          .map((json) => Meeting.fromJson(json as Map<String, dynamic>))
          .toList(),
      'total': data['total'] as int,
      'page': data['page'] as int,
      'limit': data['limit'] as int,
    };
  }

  Future<Meeting> getMeeting(String meetingId) async {
    final response = await _apiService.get('/api/admin/meetings/$meetingId');
    return Meeting.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateMeetingStatus(String meetingId, String status) async {
    await _apiService.put(
      '/api/admin/meetings/$meetingId/status',
      data: {'status': status},
    );
  }

  Future<void> deleteMeeting(String meetingId) async {
    await _apiService.delete('/api/admin/meetings/$meetingId');
  }
}
