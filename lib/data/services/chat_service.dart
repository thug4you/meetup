import 'dart:async';
import '../models/message.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _apiService;
  String? _currentMeetingId;
  Timer? _pollingTimer;
  StreamController<Message>? _messageController;
  final Set<String> _knownMessageIds = {};

  ChatService(this._apiService);

  // Подключение к чату встречи (REST polling)
  Future<void> connectToChat(String meetingId) async {
    if (_currentMeetingId == meetingId && _pollingTimer != null) {
      return;
    }

    // Закрыть предыдущее подключение
    await disconnect();

    _currentMeetingId = meetingId;
    _messageController = StreamController<Message>.broadcast();
    _knownMessageIds.clear();

    // Polling каждые 3 секунды
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollNewMessages();
    });
  }

  Future<void> _pollNewMessages() async {
    if (_currentMeetingId == null) return;

    try {
      final response = await _apiService.get(
        '/api/meetings/$_currentMeetingId/messages',
        queryParameters: {
          'page': 1,
          'limit': 50,
        },
      );

      if (response.data != null && response.data is List) {
        final messages = (response.data as List)
            .where((json) => json is Map<String, dynamic>)
            .map((json) => Message.fromJson(json as Map<String, dynamic>))
            .toList();

        for (final message in messages) {
          if (!_knownMessageIds.contains(message.id)) {
            _knownMessageIds.add(message.id);
            _messageController?.add(message);
          }
        }
      }
    } catch (e) {
      // Тихо игнорируем ошибки polling
      print('Polling ошибка: $e');
    }
  }

  // Отправить сообщение через REST API
  Future<Message> sendMessage(String meetingId, String content) async {
    try {
      final response = await _apiService.post(
        '/api/meetings/$meetingId/messages',
        data: {'content': content},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final message = Message.fromJson(data);
        _knownMessageIds.add(message.id);
        return message;
      }
      throw Exception('Неверный формат ответа');
    } catch (e) {
      print('Ошибка отправки сообщения: $e');
      rethrow;
    }
  }

  // Получить историю сообщений через REST API
  Future<List<Message>> getMessageHistory(String meetingId, {int page = 1, int limit = 50}) async {
    try {
      final response = await _apiService.get(
        '/api/meetings/$meetingId/messages',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.data != null && response.data is List) {
        final messages = (response.data as List)
            .where((json) => json is Map<String, dynamic>)
            .map((json) => Message.fromJson(json as Map<String, dynamic>))
            .toList();

        for (final msg in messages) {
          _knownMessageIds.add(msg.id);
        }

        return messages;
      }

      return [];
    } catch (e) {
      print('Ошибка загрузки истории сообщений: $e');
      rethrow;
    }
  }

  // Отметить сообщения как прочитанные
  Future<void> markMessagesAsRead(String meetingId, List<String> messageIds) async {
    try {
      await _apiService.post(
        '/api/meetings/$meetingId/messages/read',
        data: {'messageIds': messageIds},
      );
    } catch (e) {
      print('Ошибка отметки сообщений как прочитанных: $e');
    }
  }

  // Удалить сообщение
  Future<void> deleteMessage(String meetingId, String messageId) async {
    try {
      await _apiService.delete('/api/meetings/$meetingId/messages/$messageId');
    } catch (e) {
      print('Ошибка удаления сообщения: $e');
      rethrow;
    }
  }

  // Stream входящих сообщений
  Stream<Message>? get messageStream => _messageController?.stream;

  // Отключиться от чата
  Future<void> disconnect() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    await _messageController?.close();
    _messageController = null;
    _currentMeetingId = null;
    _knownMessageIds.clear();
  }

  // Singleton pattern
  static ChatService? _instance;
  factory ChatService.instance(ApiService apiService) {
    _instance ??= ChatService(apiService);
    return _instance!;
  }
}
