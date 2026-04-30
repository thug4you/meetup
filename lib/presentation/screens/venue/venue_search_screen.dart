import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/place.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/meeting_service.dart';
import '../../../data/services/location_service.dart';

class VenueSearchScreen extends StatefulWidget {
  final double? initialBudgetPerPerson;
  final int? initialParticipants;
  final double? initialRadiusKm;

  const VenueSearchScreen({
    super.key,
    this.initialBudgetPerPerson,
    this.initialParticipants,
    this.initialRadiusKm,
  });

  @override
  State<VenueSearchScreen> createState() => _VenueSearchScreenState();
}

class _VenueSearchScreenState extends State<VenueSearchScreen> {
  final _searchController = TextEditingController();
  final _locationService = LocationService();
  Timer? _debounce;

  // Быстрые категории
  static const List<String> _quickCategories = [
    'Кафе',
    'Ресторан',
    'Бар',
    'Кофейня',
    'Фастфуд',
    'Спортзал',
    'Парк',
    'Кинотеатр',
    'Музей',
    'Боулинг',
    'Караоке',
  ];

  String? _selectedCategory;
  double? _userLat;
  double? _userLng;
  double? _budgetPerPerson;
  double _radiusKm = 5.0;
  int _participants = 2;
  bool _locationLoading = true;
  bool _isSearching = false;
  bool _isSaving = false;
  List<Map<String, dynamic>> _results = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _budgetPerPerson = widget.initialBudgetPerPerson;
    _participants = widget.initialParticipants ?? _participants;
    _radiusKm = widget.initialRadiusKm ?? _radiusKm;
    _requestLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _userLat = position.latitude;
          _userLng = position.longitude;
          _locationLoading = false;
        });
      } else if (mounted) {
        setState(() => _locationLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _search);
  }

  void _onCategoryTap(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;
      } else {
        _selectedCategory = category;
      }
    });
    _search();
  }

  Future<void> _search() async {
    final userText = _searchController.text.trim();
    final category = _selectedCategory ?? '';
    final query = '$category $userText'.trim();

    if (query.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final params = <String, dynamic>{'text': query};
      if (_userLat != null) params['lat'] = _userLat;
      if (_userLng != null) params['lng'] = _userLng;
      if (_radiusKm > 0) params['radius'] = _radiusKm;
      if (_budgetPerPerson != null) params['max_bill'] = _budgetPerPerson;

      final response = await apiService.get(
        '/api/places/yandex-search',
        queryParameters: params,
      );

      if (mounted) {
        setState(() {
          _results = response.data is List
              ? (response.data as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList()
              : [];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка поиска';
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectVenue(Map<String, dynamic> venue) async {
    setState(() => _isSaving = true);

    try {
      final apiService = context.read<ApiService>();
      final meetingService = context.read<MeetingService>();

      final name = venue['name']?.toString() ?? 'Заведение';
      final address = venue['address']?.toString() ?? '';

      // Геокодируем адрес для получения координат
      double lat = _userLat ?? 55.7558;
      double lng = _userLng ?? 37.6173;

      try {
        final geoResponse = await apiService.get(
          '/api/places/geocode',
          queryParameters: {'address': '$name, $address'},
        );
        if (geoResponse.data is Map) {
          final geoLat = geoResponse.data['latitude'];
          final geoLng = geoResponse.data['longitude'];
          if (geoLat != null) lat = (geoLat as num).toDouble();
          if (geoLng != null) lng = (geoLng as num).toDouble();
        }
      } catch (_) {
        // Если геокодирование не сработало — используем координаты пользователя
      }

      // Определяем категорию из тегов Яндекса
      final tags = venue['tags'] as List?;
      final tag = (tags != null && tags.isNotEmpty) ? tags.first.toString() : null;

      // Сохраняем место в нашу БД и получаем ID
      final place = await meetingService.createPlace(
        name: name,
        address: address,
        latitude: lat,
        longitude: lng,
        category: _mapTag(tag),
        averageBill: _budgetPerPerson,
      );

      if (mounted) Navigator.pop(context, place);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String? _mapTag(String? tag) {
    const map = {
      'food': 'Кафе',
      'cafe': 'Кафе',
      'bar': 'Бар',
      'restaurant': 'Ресторан',
      'fastfood': 'Фастфуд',
      'sport': 'Спортзал',
      'cinema': 'Кинотеатр',
      'museum': 'Музей',
      'entertainment': 'Развлечения',
      'shop': 'Магазин',
    };
    return map[tag] ?? tag;
  }

  IconData _tagIcon(List? tags) {
    if (tags == null || tags.isEmpty) return Icons.place;
    final tag = tags.first.toString();
    switch (tag) {
      case 'food':
      case 'cafe':
        return Icons.local_cafe;
      case 'bar':
        return Icons.local_bar;
      case 'restaurant':
        return Icons.restaurant;
      case 'fastfood':
        return Icons.fastfood;
      case 'sport':
        return Icons.fitness_center;
      case 'cinema':
        return Icons.movie;
      case 'museum':
        return Icons.museum;
      case 'shop':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.celebration;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Поиск заведения')),
      body: Column(
        children: [
          if (_budgetPerPerson != null || _participants > 2 || _radiusKm != 5.0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_budgetPerPerson != null)
                    Chip(label: Text('Бюджет: ${_budgetPerPerson!.toStringAsFixed(0)} ₽')),
                  Chip(label: Text('Людей: $_participants')),
                  Chip(label: Text('Радиус: ${_radiusKm.toStringAsFixed(0)} км')),
                ],
              ),
            ),

          // Поле поиска
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Название заведения...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Категории-чипы
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _quickCategories.length,
              itemBuilder: (context, index) {
                final cat = _quickCategories[index];
                final isSelected = _selectedCategory == cat;
                return FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => _onCategoryTap(cat),
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  checkmarkColor: AppTheme.primaryColor,
                );
              },
            ),
          ),

          // Статус геолокации
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _locationLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Определяем местоположение...',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  )
                : _userLat != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.my_location, size: 14, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Поиск рядом с вами',
                            style: TextStyle(color: Colors.green.shade600, fontSize: 12),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off, size: 14, color: Colors.orange.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Геолокация недоступна',
                            style: TextStyle(color: Colors.orange.shade600, fontSize: 12),
                          ),
                        ],
                      ),
          ),

          const Divider(height: 1),

          // Результаты
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                            const SizedBox(height: 8),
                            Text(_error!, style: const TextStyle(color: AppTheme.errorColor)),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: _search, child: const Text('Повторить')),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.store_mall_directory_outlined,
                                    size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  _searchController.text.isEmpty && _selectedCategory == null
                                      ? 'Введите название или выберите категорию'
                                      : 'Ничего не найдено',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            children: [
                              ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _results.length,
                                itemBuilder: (context, index) =>
                                    _buildResultCard(_results[index]),
                              ),
                              if (_isSaving)
                                Container(
                                  color: Colors.black26,
                                  child: const Center(
                                    child: Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(height: 16),
                                            Text('Сохраняем заведение...'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> venue) {
    final tags = venue['tags'] as List?;
    final averageBill = venue['average_bill'];
    final distanceText = venue['distanceText']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isSaving ? null : () => _selectVenue(venue),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Иконка
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_tagIcon(tags), color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              // Инфо
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue['name']?.toString() ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      venue['address']?.toString() ?? '',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tags != null && tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: tags
                              .take(3)
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _mapTag(tag.toString()) ?? tag.toString(),
                                      style: const TextStyle(
                                          fontSize: 11, color: AppTheme.primaryColor),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    if (averageBill != null || distanceText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (averageBill != null)
                              Text(
                                'Средний чек: ${averageBill.toString()} ₽',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            if (distanceText != null)
                              Text(
                                'Рядом: $distanceText',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Расстояние
              if (venue['distanceText'] != null) ...[
                const SizedBox(width: 8),
                Column(
                  children: [
                    Icon(Icons.near_me, size: 16, color: Colors.grey.shade500),
                    const SizedBox(height: 2),
                    Text(
                      venue['distanceText'].toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
