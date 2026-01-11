import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/message_bubble.dart';

class MeetingChatScreen extends StatefulWidget {
  final String meetingId;
  final String meetingTitle;

  const MeetingChatScreen({
    super.key,
    required this.meetingId,
    required this.meetingTitle,
  });

  @override
  State<MeetingChatScreen> createState() => _MeetingChatScreenState();
}

class _MeetingChatScreenState extends State<MeetingChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToChat();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Отключаемся от чата при выходе
    final chatProvider = context.read<ChatProvider>();
    chatProvider.disconnect();
    super.dispose();
  }

  Future<void> _connectToChat() async {
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.connectToChat(widget.meetingId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    
    _messageController.clear();
    await chatProvider.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.meetingTitle),
            Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                String statusText = 'Чат встречи';
                switch (chatProvider.status) {
                  case ChatStatus.connecting:
                    statusText = 'Подключение...';
                    break;
                  case ChatStatus.connected:
                    statusText = 'В сети';
                    break;
                  case ChatStatus.disconnected:
                    statusText = 'Не подключен';
                    break;
                  case ChatStatus.error:
                    statusText = 'Ошибка подключения';
                    break;
                  default:
                    statusText = 'Чат встречи';
                }
                return Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: chatProvider.status == ChatStatus.connected
                            ? AppTheme.successColor
                            : AppTheme.textSecondaryColor,
                      ),
                );
              },
            ),
          ],
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          if (chatProvider.status == ChatStatus.initial ||
              chatProvider.status == ChatStatus.connecting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.error != null) {
            return _buildError(chatProvider.error!, chatProvider);
          }

          // Получаем текущего пользователя из AuthProvider
          return _buildChat(chatProvider);
        },
      ),
    );
  }

  Widget _buildError(String error, ChatProvider chatProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки чата',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => chatProvider.connectToChat(widget.meetingId),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildChat(ChatProvider chatProvider) {
    // Получаем текущего пользователя из AuthProvider
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Пользователь не авторизован'));
    }

    final messages = chatProvider.messages;

    return Column(
      children: [
        // Список сообщений
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет сообщений',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Начните обсуждение встречи',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                      ),
                    ],
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    // Загружаем больше сообщений при прокрутке вверх
                    if (scrollNotification is ScrollEndNotification &&
                        _scrollController.position.pixels <= 100 &&
                        chatProvider.hasMoreMessages &&
                        !chatProvider.isLoadingHistory) {
                      chatProvider.loadMessageHistory();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: messages.length + (chatProvider.isLoadingHistory ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 && chatProvider.isLoadingHistory) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final messageIndex = chatProvider.isLoadingHistory ? index - 1 : index;
                      final message = messages[messageIndex];
                      return MessageBubble(
                        message: message,
                        currentUser: currentUser,
                      );
                    },
                  ),
                ),
        ),

        const Divider(height: 1),

        // Поле ввода сообщения
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.surfaceColor,
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: chatProvider.isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: chatProvider.isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
