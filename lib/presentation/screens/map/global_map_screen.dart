import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/meeting.dart';
import '../../providers/meeting_provider.dart';
import '../meeting/meeting_detail_screen.dart';
import '../../../data/services/location_service.dart';

class GlobalMapScreen extends StatefulWidget {
  const GlobalMapScreen({super.key});

  @override
  State<GlobalMapScreen> createState() => _GlobalMapScreenState();
}

class _GlobalMapScreenState extends State<GlobalMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  LatLng _center = const LatLng(55.7558, 37.6173); // Москва по умолчанию
  LatLng? _userLocation;
  bool _isLoadingLoc = true;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    // Получаем текущие координаты пользователя
    try {
      final pos = await _locationService.getCurrentPosition();
      if (pos != null && mounted) {
        setState(() {
          _center = LatLng(pos.latitude, pos.longitude);
          _userLocation = _center;
        });
        _mapController.move(_center, 13.0);
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoadingLoc = false;
      });
      // Обновляем список встреч, чтобы на карте были актуальные
      context.read<MeetingProvider>().loadMeetings();
    }
  }

  void _openMeeting(Meeting meeting) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeetingDetailScreen(meetingId: meeting.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта встреч'),
      ),
      body: Consumer<MeetingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.meetings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Фильтруем встречи: только те, у которых есть координаты места
          final mapMeetings = provider.meetings.where((m) {
            return m.place.latitude != 0 && m.place.longitude != 0;
          }).toList();

          final markers = <Marker>[
            if (_userLocation != null)
              Marker(
                point: _userLocation!,
                width: 56,
                height: 56,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 24),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.blue, size: 16),
                  ],
                ),
              ),
            ...mapMeetings.map((meeting) {
              final lat = meeting.place.latitude;
              final lng = meeting.place.longitude;
              return Marker(
                point: LatLng(lat, lng),
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () => _showMeetingBottomSheet(meeting),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            )
                          ]
                        ),
                        child: const Icon(Icons.people, color: Colors.white, size: 20),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor, size: 16),
                    ],
                  ),
                ),
              );
            }),
          ];

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 11.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),

              // Кнопка геолокации
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  heroTag: 'myLocBtn',
                  backgroundColor: Colors.white,
                  onPressed: () async {
                    try {
                      final pos = await _locationService.getCurrentPosition();
                      if (pos != null) {
                        _mapController.move(LatLng(pos.latitude, pos.longitude), 14.0);
                      }
                    } catch (_) {}
                  },
                  child: const Icon(Icons.my_location, color: AppTheme.primaryColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMeetingBottomSheet(Meeting meeting) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final distanceText = _userLocation == null
            ? null
            : '${(_locationService.calculateDistance(
              _userLocation!.latitude,
              _userLocation!.longitude,
              meeting.place.latitude,
              meeting.place.longitude,
            ) / 1000).toStringAsFixed(1)} км';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meeting.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      meeting.place.name,
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (distanceText != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.near_me, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('От вас: $distanceText', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
              if (meeting.place.category != null || meeting.place.averageBill != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (meeting.place.category != null)
                      Chip(label: Text(meeting.place.category!)),
                    if (meeting.place.averageBill != null)
                      Chip(label: Text('Средний чек: ${meeting.place.averageBill!.toStringAsFixed(0)} ₽')),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _openMeeting(meeting);
                  },
                  child: const Text('Перейти к встрече'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
