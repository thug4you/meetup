import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:js' as js;
import '../../../core/theme/app_theme.dart';
import '../../../data/models/meeting.dart';
import '../../../data/services/meeting_service.dart';
import '../chat/meeting_chat_screen.dart';

class MeetingDetailScreen extends StatefulWidget {
  final String meetingId;

  const MeetingDetailScreen({
    super.key,
    required this.meetingId,
  });

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  late MeetingService _meetingService;
  Meeting? _meeting;
  bool _isLoading = true;
  String? _error;
  String? _mapViewId;
  bool _mapInitialized = false;

  @override
  void initState() {
    super.initState();
    _meetingService = MeetingService(context.read());
    _loadMeeting();
  }

  void _initializeMap() {
    if (_meeting == null || _mapInitialized) return;
    
    final lat = _meeting!.place.latitude;
    final lng = _meeting!.place.longitude;
    final placeName = _meeting!.place.name.replaceAll("'", "\\'");
    _mapViewId = 'meeting-map-${widget.meetingId}-${DateTime.now().millisecondsSinceEpoch}';
    
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _mapViewId!,
      (int viewId) {
        final element = html.DivElement()
          ..id = 'map-detail-$viewId'
          ..style.width = '100%'
          ..style.height = '100%';

        // Инициализация карты после загрузки
        Future.delayed(const Duration(milliseconds: 300), () {
          js.context.callMethod('eval', ['''
            (function() {
              ymaps.ready(function() {
                var map = new ymaps.Map('map-detail-$viewId', {
                  center: [$lat, $lng],
                  zoom: 15,
                  controls: ['zoomControl']
                });

                var placemark = new ymaps.Placemark([$lat, $lng], {
                  balloonContent: '$placeName'
                }, {
                  preset: 'islands#redDotIcon'
                });

                map.geoObjects.add(placemark);
                map.behaviors.disable('scrollZoom');
              });
            })();
          ''']);
        });

        return element;
      },
    );
    
    _mapInitialized = true;
    // Обновляем виджет чтобы показать карту
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadMeeting() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final meeting = await _meetingService.getMeetingById(widget.meetingId);
      setState(() {
        _meeting = meeting;
        _isLoading = false;
      });
      // Инициализируем карту после загрузки данных
      _initializeMap();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleJoin() async {
    if (_meeting == null) return;

    try {
      final updatedMeeting = await _meetingService.joinMeeting(_meeting!.id);
      setState(() {
        _meeting = updatedMeeting;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы присоединились к встрече'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleLeave() async {
    if (_meeting == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Покинуть встречу?'),
        content: const Text('Вы уверены, что хотите покинуть эту встречу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Покинуть'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final updatedMeeting = await _meetingService.leaveMeeting(_meeting!.id);
      setState(() {
        _meeting = updatedMeeting;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы покинули встречу'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _meeting != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadMeeting,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_meeting == null) {
      return const Center(
        child: Text('Встреча не найдена'),
      );
    }

    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Divider(height: 1),
              _buildPlaceSection(),
              const Divider(height: 1),
              _buildTimeSection(),
              const Divider(height: 1),
              _buildParticipantsSection(),
              const Divider(height: 1),
              _buildDescriptionSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _meeting!.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.event,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // TODO: Поделиться встречей
          },
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_border),
          onPressed: () async {
            await _meetingService.saveMeeting(_meeting!.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Встреча сохранена'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Категория
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _meeting!.category,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Организатор
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                child: _meeting!.creator.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          _meeting!.creator.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                        ),
                      )
                    : _buildDefaultAvatar(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Организатор',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                    Text(
                      _meeting!.creator.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        _meeting!.creator.name.isNotEmpty ? _meeting!.creator.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPlaceSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Место встречи',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          
          // Реальная карта Яндекс
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: _mapViewId != null
                ? HtmlElementView(viewType: _mapViewId!)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          'Загрузка карты...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
          ),
          
          const SizedBox(height: 12),
          
          // Информация о месте
          Row(
            children: [
              const Icon(
                Icons.place,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _meeting!.place.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_meeting!.place.address.isNotEmpty)
                      Text(
                        _meeting!.place.address,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection() {
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'ru');
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Время',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(_meeting!.startTime),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Продолжительность: ${_meeting!.durationMinutes} мин',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Участники',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '${_meeting!.participants.length}/${_meeting!.maxParticipants}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Список участников
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _meeting!.participants.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final participant = _meeting!.participants[index];
              return Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    child: participant.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              participant.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildParticipantAvatar(participant),
                            ),
                          )
                        : _buildParticipantAvatar(participant),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      participant.name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (participant.id == _meeting!.creator.id)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Организатор',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantAvatar(dynamic user) {
    return Center(
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    if (_meeting!.description.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Описание',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            _meeting!.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    // TODO: Проверить, является ли текущий пользователь участником
    // ignore: dead_code
    const bool isParticipant = false;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // ignore: dead_code
            if (isParticipant) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _handleLeave,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.errorColor),
                    foregroundColor: AppTheme.errorColor,
                  ),
                  child: const Text('Покинуть'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MeetingChatScreen(
                          meetingId: _meeting!.id,
                          meetingTitle: _meeting!.title,
                        ),
                      ),
                    );
                  },
                  child: const Text('Открыть чат'),
                ),
              ),
            ] else ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: _meeting!.isFull ? null : _handleJoin,
                  child: Text(_meeting!.isFull ? 'Мест нет' : 'Присоединиться'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
