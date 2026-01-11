import 'package:flutter/foundation.dart';
import '../../data/models/notification.dart';
import '../../data/services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  Map<String, bool> _settings = {
    'newParticipant': true,
    'meetingUpdate': true,
    'chatMention': true,
    'meetingReminder': true,
  };

  NotificationProvider(this._notificationService);

  // Getters
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  Map<String, bool> get settings => _settings;

  // Загрузить уведомления
  Future<void> loadNotifications({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _notifications = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newNotifications = await _notificationService.getNotifications(
        page: _currentPage,
        limit: 20,
      );

      if (newNotifications.isEmpty) {
        _hasMore = false;
      } else {
        if (refresh) {
          _notifications = newNotifications;
        } else {
          _notifications.addAll(newNotifications);
        }
        _currentPage++;
      }

      // Обновляем количество непрочитанных
      await _updateUnreadCount();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Не удалось загрузить уведомления: $e';
      notifyListeners();
    }
  }

  // Обновить количество непрочитанных
  Future<void> _updateUnreadCount() async {
    try {
      _unreadCount = await _notificationService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Ошибка обновления количества непрочитанных: $e');
    }
  }

  // Отметить как прочитанное
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      // Обновляем локальное состояние
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          message: _notifications[index].message,
          createdAt: _notifications[index].createdAt,
          isRead: true,
          meetingId: _notifications[index].meetingId,
          userId: _notifications[index].userId,
          data: _notifications[index].data,
        );
        
        if (_unreadCount > 0) {
          _unreadCount--;
        }
        
        notifyListeners();
      }
    } catch (e) {
      _error = 'Не удалось отметить уведомление: $e';
      notifyListeners();
    }
  }

  // Отметить все как прочитанные
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();

      // Обновляем локальное состояние
      _notifications = _notifications.map((n) => AppNotification(
        id: n.id,
        type: n.type,
        title: n.title,
        message: n.message,
        createdAt: n.createdAt,
        isRead: true,
        meetingId: n.meetingId,
        userId: n.userId,
        data: n.data,
      )).toList();
      
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = 'Не удалось отметить все уведомления: $e';
      notifyListeners();
    }
  }

  // Удалить уведомление
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      final notification = _notifications.firstWhere((n) => n.id == notificationId);
      if (!notification.isRead && _unreadCount > 0) {
        _unreadCount--;
      }

      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _error = 'Не удалось удалить уведомление: $e';
      notifyListeners();
    }
  }

  // Очистить все уведомления
  Future<void> clearAll() async {
    try {
      await _notificationService.clearAll();
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = 'Не удалось очистить уведомления: $e';
      notifyListeners();
    }
  }

  // Загрузить настройки
  Future<void> loadSettings() async {
    try {
      _settings = await _notificationService.getNotificationSettings();
      notifyListeners();
    } catch (e) {
      print('Ошибка загрузки настроек: $e');
    }
  }

  // Обновить настройки
  Future<void> updateSettings(Map<String, bool> newSettings) async {
    try {
      await _notificationService.updateNotificationSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
    } catch (e) {
      _error = 'Не удалось обновить настройки: $e';
      notifyListeners();
    }
  }

  // Очистить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Получить иконку для типа уведомления
  static String getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.newMeeting:
        return 'event';
      case NotificationType.meetingJoined:
        return 'person_add';
      case NotificationType.meetingTimeChanged:
        return 'update';
      case NotificationType.chatMention:
        return 'chat';
      case NotificationType.newMessage:
        return 'message';
      case NotificationType.report:
        return 'flag';
    }
  }
}
