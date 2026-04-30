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
                  MarkerLayer(
                    markers: mapMeetings.map((meeting) {
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
                    }).toList(),
                  ),
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
