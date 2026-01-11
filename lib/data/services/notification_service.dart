import '../models/notification.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService;

  NotificationService(this._apiService);

  // Получить список уведомлений
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  }) async {
    try {
      final response = await _apiService.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (isRead != null) 'isRead': isRead,
        },
      );

      if (response.data != null && response.data is List) {
        return (response.data as List)
            .map((json) => AppNotification.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Ошибка загрузки уведомлений: $e');
      rethrow;
    }
  }

  // Получить количество непрочитанных уведомлений
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get('/notifications/unread-count');
      
      if (response.data != null && response.data['count'] != null) {
        return response.data['count'] as int;
      }

      return 0;
    } catch (e) {
      print('Ошибка получения количества непрочитанных: $e');
      return 0;
    }
  }

  // Отметить уведомление как прочитанное
  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiService.put('/notifications/$notificationId/read');
    } catch (e) {
      print('Ошибка отметки уведомления как прочитанного: $e');
      rethrow;
    }
  }

  // Отметить все уведомления как прочитанные
  Future<void> markAllAsRead() async {
    try {
      await _apiService.put('/notifications/read-all');
    } catch (e) {
      print('Ошибка отметки всех уведомлений как прочитанных: $e');
      rethrow;
    }
  }

  // Удалить уведомление
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiService.delete('/notifications/$notificationId');
    } catch (e) {
      print('Ошибка удаления уведомления: $e');
      rethrow;
    }
  }

  // Очистить все уведомления
  Future<void> clearAll() async {
    try {
      await _apiService.delete('/notifications/clear-all');
    } catch (e) {
      print('Ошибка очистки уведомлений: $e');
      rethrow;
    }
  }

  // Получить настройки уведомлений
  Future<Map<String, bool>> getNotificationSettings() async {
    try {
      final response = await _apiService.get('/notifications/settings');
      
      if (response.data != null && response.data is Map) {
        return Map<String, bool>.from(response.data);
      }

      return {
        'newParticipant': true,
        'meetingUpdate': true,
        'chatMention': true,
        'meetingReminder': true,
      };
    } catch (e) {
      print('Ошибка получения настроек уведомлений: $e');
      return {
        'newParticipant': true,
        'meetingUpdate': true,
        'chatMention': true,
        'meetingReminder': true,
      };
    }
  }

  // Обновить настройки уведомлений
  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    try {
      await _apiService.put(
        '/notifications/settings',
        data: settings,
      );
    } catch (e) {
      print('Ошибка обновления настроек уведомлений: $e');
      rethrow;
    }
  }
}
