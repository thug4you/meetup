import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _apiService = ApiService();
  WebSocketChannel? _channel;
  StreamController<Message>? _messageController;
  String? _currentMeetingId;

  // WebSocket URL (замените на ваш реальный URL)
  static const String _wsBaseUrl = 'ws://localhost:3000/chat';

  // Подключение к чату встречи
  Future<void> connectToChat(String meetingId) async {
    if (_currentMeetingId == meetingId && _channel != null) {
      // Уже подключены к этому чату
      return;
    }

    // Закрыть предыдущее подключение
    await disconnect();

    _currentMeetingId = meetingId;
    _messageController = StreamController<Message>.broadcast();

    try {
      // Получаем токен для авторизации WebSocket
      final token = await _apiService.getAuthToken();
      
      // Подключаемся к WebSocket с параметрами
      final uri = Uri.parse('$_wsBaseUrl/$meetingId?token=$token');
      _channel = WebSocketChannel.connect(uri);

      // Слушаем входящие сообщения
      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data);
            final message = Message.fromJson(json);
            _messageController?.add(message);
          } catch (e) {
            print('Ошибка парсинга сообщения: $e');
          }
        },
        onError: (error) {
          print('WebSocket ошибка: $error');
          _messageController?.addError(error);
        },
        onDone: () {
          print('WebSocket соединение закрыто');
        },
      );
    } catch (e) {
      print('Ошибка подключения к чату: $e');
      rethrow;
    }
  }

  // Отправить сообщение
  Future<void> sendMessage(String meetingId, String content) async {
    if (_channel == null || _currentMeetingId != meetingId) {
      throw Exception('Не подключен к чату встречи');
    }

    try {
      final messageData = {
        'meetingId': meetingId,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _channel!.sink.add(jsonEncode(messageData));
    } catch (e) {
      print('Ошибка отправки сообщения: $e');
      rethrow;
    }
  }

  // Получить историю сообщений через REST API
  Future<List<Message>> getMessageHistory(String meetingId, {int page = 1, int limit = 50}) async {
    try {
      final response = await _apiService.get(
        '/meetings/$meetingId/messages',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.data != null && response.data is List) {
        return (response.data as List)
            .map((json) => Message.fromJson(json))
            .toList();
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
        '/meetings/$meetingId/messages/read',
        data: {'messageIds': messageIds},
      );
    } catch (e) {
      print('Ошибка отметки сообщений как прочитанных: $e');
    }
  }

  // Удалить сообщение
  Future<void> deleteMessage(String meetingId, String messageId) async {
    try {
      await _apiService.delete('/meetings/$meetingId/messages/$messageId');
    } catch (e) {
      print('Ошибка удаления сообщения: $e');
      rethrow;
    }
  }

  // Stream входящих сообщений
  Stream<Message>? get messageStream => _messageController?.stream;

  // Отключиться от чата
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    await _messageController?.close();
    _messageController = null;
    _currentMeetingId = null;
  }

  // Singleton pattern
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();
}
