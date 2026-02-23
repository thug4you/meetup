import 'package:flutter/foundation.dart';
import '../../data/models/message.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/api_service.dart';

enum ChatStatus { initial, connecting, connected, disconnected, error }

class ChatProvider with ChangeNotifier {
  final ChatService _chatService;

  ChatProvider(ApiService apiService) : _chatService = ChatService.instance(apiService);

  ChatStatus _status = ChatStatus.initial;
  List<Message> _messages = [];
  String? _currentMeetingId;
  String? _error;
  bool _isLoadingHistory = false;
  bool _isSending = false;
  int _currentPage = 1;
  bool _hasMoreMessages = true;

  // Getters
  ChatStatus get status => _status;
  List<Message> get messages => _messages;
  String? get error => _error;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isSending => _isSending;
  bool get hasMoreMessages => _hasMoreMessages;

  // Подключиться к чату встречи
  Future<void> connectToChat(String meetingId) async {
    if (_currentMeetingId == meetingId && _status == ChatStatus.connected) {
      return;
    }

    _status = ChatStatus.connecting;
    _error = null;
    _currentMeetingId = meetingId;
    _messages = [];
    _currentPage = 1;
    _hasMoreMessages = true;
    notifyListeners();

    try {
      // Подключаемся к WebSocket
      await _chatService.connectToChat(meetingId);

      // Загружаем историю сообщений
      await loadMessageHistory();

      // Слушаем новые сообщения
      _chatService.messageStream?.listen(
        (message) {
          _addMessage(message);
        },
        onError: (error) {
          _status = ChatStatus.error;
          _error = 'Ошибка получения сообщений: $error';
          notifyListeners();
        },
      );

      _status = ChatStatus.connected;
      notifyListeners();
    } catch (e) {
      _status = ChatStatus.error;
      _error = 'Не удалось подключиться к чату: $e';
      notifyListeners();
    }
  }

  // Загрузить историю сообщений
  Future<void> loadMessageHistory() async {
    if (_currentMeetingId == null || _isLoadingHistory || !_hasMoreMessages) {
      return;
    }

    _isLoadingHistory = true;
    _error = null;
    notifyListeners();

    try {
      final newMessages = await _chatService.getMessageHistory(
        _currentMeetingId!,
        page: _currentPage,
        limit: 50,
      );

      if (newMessages.isEmpty) {
        _hasMoreMessages = false;
      } else {
        // Добавляем в начало списка (более старые сообщения)
        _messages.insertAll(0, newMessages.reversed);
        _currentPage++;
      }

      _isLoadingHistory = false;
      notifyListeners();
    } catch (e) {
      _isLoadingHistory = false;
      _error = 'Не удалось загрузить историю сообщений: $e';
      notifyListeners();
    }
  }

  // Отправить сообщение
  Future<void> sendMessage(String content) async {
    if (_currentMeetingId == null || content.trim().isEmpty || _isSending) {
      return;
    }

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      await _chatService.sendMessage(_currentMeetingId!, content.trim());
      _isSending = false;
      notifyListeners();
    } catch (e) {
      _isSending = false;
      _error = 'Не удалось отправить сообщение: $e';
      notifyListeners();
    }
  }

  // Отметить сообщения как прочитанные
  Future<void> markMessagesAsRead() async {
    if (_currentMeetingId == null) return;

    final unreadMessageIds = _messages
        .where((m) => !m.isRead)
        .map((m) => m.id)
        .toList();

    if (unreadMessageIds.isEmpty) return;

    try {
      await _chatService.markMessagesAsRead(_currentMeetingId!, unreadMessageIds);
      
      // Обновляем локальное состояние
      for (var message in _messages) {
        if (unreadMessageIds.contains(message.id)) {
          // Создаем новый объект с isRead = true
          final index = _messages.indexOf(message);
          _messages[index] = Message(
            id: message.id,
            meetingId: message.meetingId,
            sender: message.sender,
            content: message.content,
            sentAt: message.sentAt,
            isRead: true,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      print('Ошибка отметки сообщений как прочитанных: $e');
    }
  }

  // Удалить сообщение
  Future<void> deleteMessage(String messageId) async {
    if (_currentMeetingId == null) return;

    try {
      await _chatService.deleteMessage(_currentMeetingId!, messageId);
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    } catch (e) {
      _error = 'Не удалось удалить сообщение: $e';
      notifyListeners();
    }
  }

  // Отключиться от чата
  Future<void> disconnect() async {
    await _chatService.disconnect();
    _status = ChatStatus.disconnected;
    _currentMeetingId = null;
    _messages = [];
    _error = null;
    _currentPage = 1;
    _hasMoreMessages = true;
    notifyListeners();
  }

  // Добавить новое сообщение в список
  void _addMessage(Message message) {
    // Проверяем, что сообщение еще не добавлено
    if (!_messages.any((m) => m.id == message.id)) {
      _messages.add(message);
      notifyListeners();
    }
  }

  // Очистить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _chatService.disconnect();
    super.dispose();
  }
}
