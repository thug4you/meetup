import 'user.dart';
import 'place.dart';

enum MeetingStatus {
  upcoming,
  active,
  completed,
  cancelled,
}

class Meeting {
  final String id;
  final String title;
  final String description;
  final String category;
  final Place place;
  final DateTime startTime;
  final int durationMinutes;
  final int maxParticipants;
  final List<User> participants;
  final User creator;
  final MeetingStatus status;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  Meeting({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.place,
    required this.startTime,
    required this.durationMinutes,
    required this.maxParticipants,
    required this.participants,
    required this.creator,
    required this.status,
    this.isPrivate = false,
    required this.createdAt,
    this.updatedAt,
  });
  
  bool get isFull => participants.length >= maxParticipants;
  int get availableSlots => maxParticipants - participants.length;
  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));
  
  factory Meeting.fromJson(Map<String, dynamic> json) {
    // Создаем минимальный Place если его нет
    Place place;
    if (json['place'] != null) {
      place = Place.fromJson(json['place'] as Map<String, dynamic>);
    } else {
      // Пытаемся получить данные места из полей верхнего уровня
      final placeName = json['place_name'] as String? ?? 'Не указано';
      final address = json['address'] as String? ?? '';
      final latitude = json['latitude'] ?? json['place_latitude'] ?? 0.0;
      final longitude = json['longitude'] ?? json['place_longitude'] ?? 0.0;
      
      place = Place(
        id: json['place_id']?.toString() ?? '0',
        name: placeName,
        address: address,
        latitude: _parseDouble(latitude),
        longitude: _parseDouble(longitude),
      );
    }
    
    // Создаем минимального User если его нет
    final creator = json['creator'] != null
        ? User.fromJson(json['creator'] as Map<String, dynamic>)
        : User(
            id: json['organizer_id']?.toString() ?? '0',
            email: '',
            name: json['organizer_name'] as String? ?? 'Организатор',
            createdAt: DateTime.now(),
          );
    
    return Meeting(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Другое',
      place: place,
      startTime: json['start_time'] != null 
          ? DateTime.parse(json['start_time'] as String)
          : DateTime.now(),
      durationMinutes: json['duration'] as int? ?? 
          (json['end_time'] != null && json['start_time'] != null
              ? DateTime.parse(json['end_time'] as String)
                  .difference(DateTime.parse(json['start_time'] as String))
                  .inMinutes
              : 60),
      maxParticipants: json['max_participants'] as int? ?? json['maxParticipants'] as int? ?? 10,
      participants: json['participants'] is List
          ? (json['participants'] as List<dynamic>)
              .map((e) => User.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      creator: creator,
      status: MeetingStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'active'),
        orElse: () => MeetingStatus.active,
      ),
      isPrivate: json['isPrivate'] as bool? ?? json['is_private'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'place': place.toJson(),
      'startTime': startTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'maxParticipants': maxParticipants,
      'participants': participants.map((e) => e.toJson()).toList(),
      'creator': creator.toJson(),
      'status': status.name,
      'isPrivate': isPrivate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  
  Meeting copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    Place? place,
    DateTime? startTime,
    int? durationMinutes,
    int? maxParticipants,
    List<User>? participants,
    User? creator,
    MeetingStatus? status,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Meeting(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      place: place ?? this.place,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participants: participants ?? this.participants,
      creator: creator ?? this.creator,
      status: status ?? this.status,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Вспомогательная функция для парсинга double из разных типов
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    return 0.0;
  }
}
