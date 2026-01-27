import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/notification.dart' as models;
import '../../../core/theme/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../meeting/meeting_detail_screen.dart';
import '../chat/meeting_chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<NotificationProvider>();
      if (!provider.isLoading && provider.hasMore) {
        provider.loadNotifications();
      }
    }
  }

  Future<void> _loadNotifications() async {
    final provider = context.read<NotificationProvider>();
    await provider.loadNotifications(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.notifications.isEmpty) return const SizedBox();
              
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'mark_all_read') {
                    await provider.markAllAsRead();
                  } else if (value == 'clear_all') {
                    await provider.clearAll();
                  } else if (value == 'settings') {
                    _showSettingsDialog();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 20),
                        SizedBox(width: 12),
                        Text('Отметить все как прочитанные'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, size: 20),
                        SizedBox(width: 12),
                        Text('Очистить все'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 20),
                        SizedBox(width: 12),
                        Text('Настройки'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null && provider.notifications.isEmpty) {
              return _buildError(provider.error!, provider);
            }

            if (provider.notifications.isEmpty) {
              return _buildEmpty();
            }

            return ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.notifications.length + (provider.isLoading ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == provider.notifications.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final notification = provider.notifications[index];
                return _buildNotificationItem(notification, provider);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(String error, NotificationProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'Ошибка загрузки',
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
              onPressed: () => provider.loadNotifications(refresh: true),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет уведомлений',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь будут появляться уведомления\nо ваших встречах',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    models.AppNotification notification,
    NotificationProvider provider,
  ) {
    final icon = _getIconForType(notification.type);
    final color = _getColorForType(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppTheme.errorColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => provider.deleteNotification(notification.id),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          notification.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _handleNotificationTap(notification, provider),
      ),
    );
  }

  IconData _getIconForType(models.NotificationType type) {
    switch (type) {
      case models.NotificationType.newMeeting:
        return Icons.event;
      case models.NotificationType.meetingJoined:
        return Icons.person_add;
      case models.NotificationType.meetingTimeChanged:
        return Icons.update;
      case models.NotificationType.chatMention:
        return Icons.chat;
      case models.NotificationType.newMessage:
        return Icons.message;
      case models.NotificationType.report:
        return Icons.flag;
      case models.NotificationType.meeting:
        return Icons.event_available;
    }
  }

  Color _getColorForType(models.NotificationType type) {
    switch (type) {
      case models.NotificationType.newMeeting:
        return Colors.blue;
      case models.NotificationType.meetingJoined:
        return Colors.green;
      case models.NotificationType.meetingTimeChanged:
        return Colors.orange;
      case models.NotificationType.chatMention:
        return Colors.purple;
      case models.NotificationType.newMessage:
        return Colors.indigo;
      case models.NotificationType.report:
        return Colors.red;
      case models.NotificationType.meeting:
        return Colors.teal;
    }
  }


  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн назад';
    } else {
      return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
    }
  }

  Future<void> _handleNotificationTap(
    models.AppNotification notification,
    NotificationProvider provider,
  ) async {
    // Отмечаем как прочитанное
    if (!notification.isRead) {
      await provider.markAsRead(notification.id);
    }

    // Навигация в зависимости от типа
    if (notification.meetingId != null) {
      if (notification.type == models.NotificationType.chatMention) {
        // Открываем чат
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MeetingChatScreen(
              meetingId: notification.meetingId!,
              meetingTitle: notification.data?['meetingTitle'] ?? 'Чат встречи',
            ),
          ),
        );
      } else {
        // Открываем детали встречи
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MeetingDetailScreen(
              meetingId: notification.meetingId!,
            ),
          ),
        );
      }
    }
  }

  void _showSettingsDialog() {
    final provider = context.read<NotificationProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки уведомлений'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Новый участник'),
                  value: provider.settings['newParticipant'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      provider.settings['newParticipant'] = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Изменение встречи'),
                  value: provider.settings['meetingUpdate'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      provider.settings['meetingUpdate'] = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Упоминания в чате'),
                  value: provider.settings['chatMention'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      provider.settings['chatMention'] = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Напоминания о встречах'),
                  value: provider.settings['meetingReminder'] ?? true,
                  onChanged: (value) {
                    setState(() {
                      provider.settings['meetingReminder'] = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateSettings(provider.settings);
              Navigator.of(context).pop();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
