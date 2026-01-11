import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/place.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/meeting_service.dart';
import '../../../data/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class MapPickerScreen extends StatefulWidget {
  final Place? initialPlace;
  final double? initialLatitude;
  final double? initialLongitude;

  const MapPickerScreen({
    super.key,
    this.initialPlace,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  late MeetingService _meetingService;
  
  Place? _selectedPlace;
  double _currentLatitude = 55.751244; // Москва по умолчанию
  double _currentLongitude = 37.618423;
  bool _isLoading = false;
  List<Place> _searchResults = [];
  final String _mapViewId = 'yandex-map-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _meetingService = MeetingService(context.read<ApiService>());
    _selectedPlace = widget.initialPlace;
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _currentLatitude = widget.initialLatitude!;
      _currentLongitude = widget.initialLongitude!;
    }
    _initializeMap();
    _getCurrentLocation();
  }

  void _initializeMap() {
    // Регистрируем HTML элемент для карты
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _mapViewId,
      (int viewId) {
        final element = html.DivElement()
          ..id = 'map-container-$viewId'
          ..style.width = '100%'
          ..style.height = '100%';

        // Инициализация карты после загрузки
        Future.delayed(const Duration(milliseconds: 500), () {
          _createYandexMap(element.id);
        });

        return element;
      },
    );
  }

  void _createYandexMap(String containerId) {
    // Создаем карту через Yandex Maps API
    js.context.callMethod('eval', ['''
      (function() {
        ymaps.ready(function() {
          var map = new ymaps.Map('$containerId', {
            center: [$_currentLatitude, $_currentLongitude],
            zoom: 12,
            controls: ['zoomControl', 'geolocationControl']
          });

          var placemark = new ymaps.Placemark([$_currentLatitude, $_currentLongitude], {}, {
            preset: 'islands#redDotIcon',
            draggable: true
          });

          map.geoObjects.add(placemark);

          // Обработчик перемещения метки
          placemark.events.add('dragend', function (e) {
            var coords = placemark.geometry.getCoordinates();
            window.parent.postMessage({
              type: 'mapMarkerMoved',
              latitude: coords[0],
              longitude: coords[1]
            }, '*');
          });

          // Обработчик клика по карте
          map.events.add('click', function (e) {
            var coords = e.get('coords');
            placemark.geometry.setCoordinates(coords);
            window.parent.postMessage({
              type: 'mapMarkerMoved',
              latitude: coords[0],
              longitude: coords[1]
            }, '*');
          });

          // Сохраняем ссылку на карту и метку
          window.yandexMapInstance = map;
          window.yandexPlacemark = placemark;
        });
      })();
    ''']);

    // Слушаем сообщения от карты
    html.window.onMessage.listen((event) {
      if (event.data is Map && event.data['type'] == 'mapMarkerMoved') {
        setState(() {
          _currentLatitude = event.data['latitude'];
          _currentLongitude = event.data['longitude'];
        });
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentLatitude = position.latitude;
          _currentLongitude = position.longitude;
        });
        
        // Обновляем центр карты
        _updateMapCenter(_currentLatitude, _currentLongitude);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось получить местоположение')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateMapCenter(double lat, double lng) {
    js.context.callMethod('eval', ['''
      (function() {
        if (window.yandexMapInstance && window.yandexPlacemark) {
          window.yandexMapInstance.setCenter([$lat, $lng], 14);
          window.yandexPlacemark.geometry.setCoordinates([$lat, $lng]);
        }
      })();
    ''']);
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _meetingService.searchPlaces(query: query);
      setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка поиска: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectPlace(Place place) {
    setState(() {
      _selectedPlace = place;
      _currentLatitude = place.latitude;
      _currentLongitude = place.longitude;
      _searchResults = [];
      _searchController.clear();
    });
    
    _updateMapCenter(place.latitude, place.longitude);
  }

  void _confirmSelection() {
    if (_selectedPlace != null) {
      Navigator.pop(context, _selectedPlace);
    } else {
      // Создаем место из текущих координат
      final newPlace = Place(
        id: '',
        name: 'Выбранная точка',
        address: 'Координаты: $_currentLatitude, $_currentLongitude',
        latitude: _currentLatitude,
        longitude: _currentLongitude,
        rating: 0.0,
      );
      Navigator.pop(context, newPlace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор места на карте'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Моё местоположение',
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск мест...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                if (value.length >= 3) {
                  _searchPlaces(value);
                } else {
                  setState(() => _searchResults = []);
                }
              },
            ),
          ),

          // Результаты поиска
          if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.place),
                    title: Text(place.name),
                    subtitle: Text(place.address),
                    onTap: () => _selectPlace(place),
                  );
                },
              ),
            ),

          // Выбранное место
          if (_selectedPlace != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedPlace!.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _selectedPlace!.address,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedPlace = null),
                  ),
                ],
              ),
            ),

          // Карта
          Expanded(
            child: Stack(
              children: [
                HtmlElementView(viewType: _mapViewId),
                if (_isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),

          // Информация о координатах
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.surfaceColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 8),
                Text(
                  '${_currentLatitude.toStringAsFixed(6)}, ${_currentLongitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                ),
              ],
            ),
          ),

          // Кнопка подтверждения
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmSelection,
                  child: const Text('Выбрать это место'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Очищаем карту
    js.context.callMethod('eval', ['''
      (function() {
        if (window.yandexMapInstance) {
          window.yandexMapInstance.destroy();
          window.yandexMapInstance = null;
          window.yandexPlacemark = null;
        }
      })();
    ''']);
    super.dispose();
  }
}
