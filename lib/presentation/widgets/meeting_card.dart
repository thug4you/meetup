import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/meeting.dart';

class MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final VoidCallback? onSave;

  const MeetingCard({
    super.key,
    required this.meeting,
    this.onTap,
    this.onJoin,
    this.onLeave,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, HH:mm', 'ru');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и категория
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meeting.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip(context),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Место
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      meeting.place.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Дата и время
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(meeting.startTime),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${meeting.durationMinutes} мин',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Описание
              if (meeting.description.isNotEmpty)
                Text(
                  meeting.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              const SizedBox(height: 12),
              
              // Участники и действия
              Row(
                children: [
                  // Аватары участников
                  _buildParticipantsAvatars(),
                  
                  const SizedBox(width: 8),
                  
                  // Счётчик участников
                  Text(
                    '${meeting.participants.length}/${meeting.maxParticipants}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  
                  const Spacer(),
                  
                  // Кнопка сохранить
                  IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: onSave,
                    color: AppTheme.textSecondaryColor,
                    iconSize: 20,
                  ),
                  
                  const SizedBox(width: 4),
                  
                  // Кнопка действия (присоединиться/покинуть)
                  _buildActionButton(context),
                ],
              ),
              
              // Статус заполненности
              if (meeting.isFull)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Мест нет',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.warningColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        meeting.category,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildParticipantsAvatars() {
    const maxAvatars = 3;
    final displayParticipants = meeting.participants.take(maxAvatars).toList();
    
    return SizedBox(
      height: 32,
      child: Stack(
        children: [
          for (var i = 0; i < displayParticipants.length; i++)
            Positioned(
              left: i * 24.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
                child: displayParticipants[i].avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          displayParticipants[i].avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(displayParticipants[i]),
                        ),
                      )
                    : _buildDefaultAvatar(displayParticipants[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(dynamic user) {
    return Center(
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    // TODO: Проверить через текущего пользователя
    // ignore: dead_code
    const bool isParticipant = false;
    
    // ignore: dead_code
    if (isParticipant) {
      return OutlinedButton(
        onPressed: onLeave,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          side: const BorderSide(color: AppTheme.errorColor),
          foregroundColor: AppTheme.errorColor,
        ),
        child: const Text('Выйти'),
      );
    }
    
    if (meeting.isFull) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Мест нет'),
      );
    }
    
    return ElevatedButton(
      onPressed: onJoin,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: const Text('Присоединиться'),
    );
  }
}
