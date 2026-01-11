import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/meeting.dart';
import '../../providers/meeting_provider.dart';
import '../../widgets/meeting_card.dart';
import '../meeting/meeting_detail_screen.dart';

enum SortBy {
  time,
  relevance,
  participants,
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  SortBy _sortBy = SortBy.time;
  String? _selectedCategory;
  DateTimeRange? _dateRange;
  double _radius = 10.0;
  int _minParticipants = 0;
  int _maxParticipants = 50;
  bool _onlyAvailable = false;

  bool _isSearching = false;
  List<Meeting> _searchResults = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Можно добавить пагинацию для поиска
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final provider = context.read<MeetingProvider>();
      
      // Применяем фильтры
      if (_selectedCategory != null) {
        provider.setCategory(_selectedCategory);
      }
      if (_dateRange != null) {
        provider.setDateRange(_dateRange!.start, _dateRange!.end);
      }
      provider.setRadius(_radius);

      await provider.loadMeetings(refresh: true);

      // Фильтруем результаты по поисковому запросу
      var results = provider.meetings.where((meeting) {
        final queryLower = _searchQuery.toLowerCase();
        return meeting.title.toLowerCase().contains(queryLower) ||
            meeting.description.toLowerCase().contains(queryLower) ||
            meeting.place.name.toLowerCase().contains(queryLower) ||
            meeting.place.address.toLowerCase().contains(queryLower);
      }).toList();

      // Фильтруем по количеству участников
      results = results.where((meeting) {
        final currentParticipants = meeting.participants.length;
        return currentParticipants >= _minParticipants && 
               currentParticipants <= _maxParticipants;
      }).toList();

      // Фильтруем только доступные
      if (_onlyAvailable) {
        results = results.where((meeting) {
          return meeting.status != MeetingStatus.cancelled &&
                 meeting.participants.length < meeting.maxParticipants;
        }).toList();
      }

      // Сортируем результаты
      results = _sortResults(results);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  List<Meeting> _sortResults(List<Meeting> meetings) {
    switch (_sortBy) {
      case SortBy.time:
        meetings.sort((a, b) => a.startTime.compareTo(b.startTime));
        break;
      case SortBy.relevance:
        // Сортировка по релевантности (по количеству совпадений в поиске)
        meetings.sort((a, b) {
          final queryLower = _searchQuery.toLowerCase();
          final aScore = _calculateRelevanceScore(a, queryLower);
          final bScore = _calculateRelevanceScore(b, queryLower);
          return bScore.compareTo(aScore);
        });
        break;
      case SortBy.participants:
        meetings.sort((a, b) => b.participants.length.compareTo(a.participants.length));
        break;
    }
    return meetings;
  }

  int _calculateRelevanceScore(Meeting meeting, String query) {
    int score = 0;
    if (meeting.title.toLowerCase().contains(query)) score += 3;
    if (meeting.description.toLowerCase().contains(query)) score += 2;
    if (meeting.place.name.toLowerCase().contains(query)) score += 1;
    if (meeting.place.address.toLowerCase().contains(query)) score += 1;
    return score;
  }

  void _showFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFiltersSheet(),
    );
  }

  Widget _buildFiltersSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Фильтры',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            setModalState(() {
                              _selectedCategory = null;
                              _dateRange = null;
                              _radius = 10.0;
                              _minParticipants = 0;
                              _maxParticipants = 50;
                              _onlyAvailable = false;
                            });
                          });
                        },
                        child: const Text('Сбросить'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

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
                            setModalState(() {
                              _selectedCategory = selected ? category : null;
                            });
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Период времени
                  Text(
                    'Период времени',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppTheme.primaryColor,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      
                      if (picked != null) {
                        setState(() {
                          setModalState(() {
                            _dateRange = picked;
                          });
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _dateRange != null
                                ? '${DateFormat('dd.MM.yyyy').format(_dateRange!.start)} - ${DateFormat('dd.MM.yyyy').format(_dateRange!.end)}'
                                : 'Выберите период',
                            style: TextStyle(
                              color: _dateRange != null 
                                  ? AppTheme.textPrimaryColor 
                                  : AppTheme.textHintColor,
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Радиус поиска
                  Text(
                    'Радиус поиска: ${_radius.toStringAsFixed(0)} км',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: _radius,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${_radius.toStringAsFixed(0)} км',
                    onChanged: (value) {
                      setState(() {
                        setModalState(() {
                          _radius = value;
                        });
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Количество участников
                  Text(
                    'Количество участников: $_minParticipants - $_maxParticipants',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: RangeValues(_minParticipants.toDouble(), _maxParticipants.toDouble()),
                    min: 0,
                    max: 50,
                    divisions: 50,
                    labels: RangeLabels(
                      _minParticipants.toString(),
                      _maxParticipants.toString(),
                    ),
                    onChanged: (values) {
                      setState(() {
                        setModalState(() {
                          _minParticipants = values.start.toInt();
                          _maxParticipants = values.end.toInt();
                        });
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Только доступные
                  CheckboxListTile(
                    title: const Text('Только доступные встречи'),
                    subtitle: const Text('Не отменённые и с местами'),
                    value: _onlyAvailable,
                    onChanged: (value) {
                      setState(() {
                        setModalState(() {
                          _onlyAvailable = value ?? false;
                        });
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 24),

                  // Кнопка применить
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _performSearch();
                      },
                      child: const Text('Применить фильтры'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск встреч'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по названию, описанию, месту...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                if (value.length >= 3) {
                  _performSearch();
                } else if (value.isEmpty) {
                  setState(() => _searchResults = []);
                }
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _performSearch();
                }
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Фильтры и сортировка
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.surfaceColor,
            child: Row(
              children: [
                // Кнопка фильтров
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFiltersSheet,
                    icon: const Icon(Icons.filter_list),
                    label: Text(
                      _getActiveFiltersText(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Сортировка
                DropdownButton<SortBy>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort),
                  items: const [
                    DropdownMenuItem(
                      value: SortBy.time,
                      child: Text('По времени'),
                    ),
                    DropdownMenuItem(
                      value: SortBy.relevance,
                      child: Text('По релевантности'),
                    ),
                    DropdownMenuItem(
                      value: SortBy.participants,
                      child: Text('По участникам'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                        if (_searchResults.isNotEmpty) {
                          _searchResults = _sortResults(_searchResults);
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Результаты поиска
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  String _getActiveFiltersText() {
    final filters = <String>[];
    if (_selectedCategory != null) filters.add(_selectedCategory!);
    if (_dateRange != null) filters.add('Даты');
    if (_radius != 10.0) filters.add('${_radius.toInt()} км');
    if (_minParticipants > 0 || _maxParticipants < 50) filters.add('Участники');
    if (_onlyAvailable) filters.add('Доступные');
    
    return filters.isEmpty ? 'Фильтры' : filters.join(', ');
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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
              'Ошибка поиска',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Начните поиск',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Введите название, описание или место встречи',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Ничего не найдено',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить запрос или фильтры',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Найдено: ${_searchResults.length}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          );
        }

        final meeting = _searchResults[index - 1];
        return MeetingCard(
          meeting: meeting,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MeetingDetailScreen(
                  meetingId: meeting.id,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
