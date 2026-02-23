import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/meeting_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/meeting_card.dart';
import 'package:flutter_application_1/presentation/screens/meeting/meeting_detail_screen.dart';

class MeetingsFeedScreen extends StatefulWidget {
  const MeetingsFeedScreen({super.key});

  @override
  State<MeetingsFeedScreen> createState() => _MeetingsFeedScreenState();
}

class _MeetingsFeedScreenState extends State<MeetingsFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  String _sortOrder = 'newest'; // 'newest' или 'oldest'
  bool _excludeMyMeetings = true; // Изначально исключаем свои встречи

  @override
  void initState() {
    super.initState();
    
    // Загрузить встречи при первом открытии
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeetingProvider>().loadMeetings(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<MeetingProvider>().loadMeetings(refresh: true);
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FiltersBottomSheet(
        currentSortOrder: _sortOrder,
        excludeMyMeetings: _excludeMyMeetings,
        onSortOrderChanged: (order) {
          setState(() => _sortOrder = order);
        },
        onExcludeMyMeetingsChanged: (value) {
          setState(() => _excludeMyMeetings = value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Встречи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Consumer<MeetingProvider>(
        builder: (context, provider, child) {
          // Показать индикатор загрузки при первой загрузке
          if (provider.isLoading && provider.meetings.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Показать ошибку
          if (provider.error != null && provider.meetings.isEmpty) {
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
                      provider.error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.loadMeetings(refresh: true),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          // Показать пустой список
          if (provider.meetings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 80,
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет доступных встреч',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Попробуйте изменить фильтры',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                ],
              ),
            );
          }

          // Показать список встреч
          var filteredMeetings = List.from(provider.meetings);
          
          // Фильтр: исключить мои встречи
          final authProvider = context.read<AuthProvider>();
          final currentUserId = authProvider.currentUser?.id;
          if (_excludeMyMeetings) {
            if (currentUserId != null) {
              filteredMeetings = filteredMeetings.where((m) => m.creator.id != currentUserId).toList();
            }
          }
          
          // Сортировка
          if (_sortOrder == 'oldest') {
            filteredMeetings.sort((a, b) => a.startTime.compareTo(b.startTime));
          } else {
            filteredMeetings.sort((a, b) => b.startTime.compareTo(a.startTime));
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: filteredMeetings.length,
              itemBuilder: (context, index) {
                final meeting = filteredMeetings[index];
                return MeetingCard(
                  meeting: meeting,
                  currentUserId: currentUserId,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MeetingDetailScreen(meetingId: meeting.id),
                      ),
                    );
                  },
                  onJoin: () async {
                    final success = await provider.joinMeeting(meeting.id);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Вы присоединились к встрече'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  },
                  onLeave: () async {
                    final success = await provider.leaveMeeting(meeting.id);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Вы покинули встречу'),
                        ),
                      );
                    }
                  },
                  onSave: () async {
                    final success = await provider.saveMeeting(meeting.id);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Встреча сохранена'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// Модальное окно фильтров
class _FiltersBottomSheet extends StatefulWidget {
  final String currentSortOrder;
  final bool excludeMyMeetings;
  final Function(String) onSortOrderChanged;
  final Function(bool) onExcludeMyMeetingsChanged;

  const _FiltersBottomSheet({
    required this.currentSortOrder,
    required this.excludeMyMeetings,
    required this.onSortOrderChanged,
    required this.onExcludeMyMeetingsChanged,
  });

  @override
  State<_FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<_FiltersBottomSheet> {
  String? _selectedCategory;
  double _radius = 5.0;
  bool _useRadiusFilter = false; // Галочка для радиуса
  late String _sortOrder;
  late bool _excludeMyMeetings;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MeetingProvider>();
    _selectedCategory = provider.selectedCategory;
    _radius = provider.radius ?? 5.0;
    _sortOrder = widget.currentSortOrder;
    _excludeMyMeetings = widget.excludeMyMeetings;
  }

  void _applyFilters() {
    final provider = context.read<MeetingProvider>();
    provider.setCategory(_selectedCategory);
    provider.setRadius(_useRadiusFilter ? _radius : null);
    widget.onSortOrderChanged(_sortOrder);
    widget.onExcludeMyMeetingsChanged(_excludeMyMeetings);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _useRadiusFilter = false;
      _excludeMyMeetings = true;
      _sortOrder = 'newest';
    });
    context.read<MeetingProvider>().clearFilters();
    widget.onSortOrderChanged('newest');
    widget.onExcludeMyMeetingsChanged(true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Фильтры',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Очистить'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Сортировка по времени
                Text(
                  'Сортировка',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward, size: 16),
                            SizedBox(width: 4),
                            Text('Сначала новые'),
                          ],
                        ),
                        selected: _sortOrder == 'newest',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _sortOrder = 'newest');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward, size: 16),
                            SizedBox(width: 4),
                            Text('Сначала старые'),
                          ],
                        ),
                        selected: _sortOrder == 'oldest',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _sortOrder = 'oldest');
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Скрыть мои встречи
                CheckboxListTile(
                  title: const Text('Скрыть мои встречи'),
                  subtitle: const Text('Не показывать встречи, которые я создал'),
                  value: _excludeMyMeetings,
                  onChanged: (value) {
                    setState(() => _excludeMyMeetings = value ?? true);
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 16),

                // Категория
                Text(
                  'Категория',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.meetingCategories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Радиус поиска с галочкой
                Row(
                  children: [
                    Checkbox(
                      value: _useRadiusFilter,
                      onChanged: (value) {
                        setState(() => _useRadiusFilter = value ?? false);
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Радиус поиска: ${_radius.toStringAsFixed(1)} км',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _useRadiusFilter ? null : AppTheme.textSecondaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _radius,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: '${_radius.toStringAsFixed(1)} км',
                  onChanged: _useRadiusFilter ? (value) {
                    setState(() => _radius = value);
                  } : null,
                ),

                const SizedBox(height: 24),

                // Кнопка применить
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Применить'),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
