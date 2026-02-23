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
  final String? organizerName; // Для админки
  final String? organizerEmail; // Для админки
  
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
    this.organizerName,
    this.organizerEmail,
  });
  
  bool get isFull => participants.length >= maxParticipants;
  int get availableSlots => maxParticipants - participants.length;
  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));
  
  factory Meeting.fromJson(Map<String, dynamic> json) {
    // Создаем минимальный Place если его нет
    Place place;
    if (json['place'] != null && json['place'] is Map<String, dynamic>) {
      place = Place.fromJson(json['place'] as Map<String, dynamic>);
    } else {
      // Пытаемся получить данные места из полей верхнего уровня
      final placeName = json['place_name']?.toString() ?? 'Не указано';
      final address = json['address']?.toString() ?? '';
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
    User creator;
    if (json['creator'] != null && json['creator'] is Map<String, dynamic>) {
      creator = User.fromJson(json['creator'] as Map<String, dynamic>);
    } else {
      creator = User(
        id: json['organizer_id']?.toString() ?? '0',
        email: '',
        name: json['organizer_name']?.toString() ?? 'Организатор',
        createdAt: DateTime.now(),
      );
    }

    // Безопасный парсинг дат
    DateTime startTime;
    try {
      startTime = json['start_time'] != null
          ? DateTime.parse(json['start_time'].toString())
          : DateTime.now();
    } catch (_) {
      startTime = DateTime.now();
    }

    int durationMinutes = 60;
    try {
      if (json['duration'] != null) {
        durationMinutes = json['duration'] is int
            ? json['duration'] as int
            : int.tryParse(json['duration'].toString()) ?? 60;
      } else if (json['end_time'] != null && json['start_time'] != null) {
        final endTime = DateTime.parse(json['end_time'].toString());
        durationMinutes = endTime.difference(startTime).inMinutes;
      }
    } catch (_) {
      durationMinutes = 60;
    }

    DateTime createdAt;
    try {
      createdAt = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now();
    } catch (_) {
      createdAt = DateTime.now();
    }

    DateTime? updatedAt;
    try {
      updatedAt = json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null;
    } catch (_) {
      updatedAt = null;
    }

    // Безопасный парсинг max_participants
    int maxParticipants = 10;
    final maxP = json['max_participants'] ?? json['maxParticipants'];
    if (maxP is int) {
      maxParticipants = maxP;
    } else if (maxP != null) {
      maxParticipants = int.tryParse(maxP.toString()) ?? 10;
    }

    // Безопасный парсинг участников
    List<User> participants = [];
    if (json['participants'] is List) {
      participants = (json['participants'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((e) => User.fromJson(e))
          .toList();
    }

    return Meeting(
      id: (json['id'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Другое',
      place: place,
      startTime: startTime,
      durationMinutes: durationMinutes,
      maxParticipants: maxParticipants,
      participants: participants,
      creator: creator,
      status: MeetingStatus.values.firstWhere(
        (e) => e.name == (json['status']?.toString() ?? 'active'),
        orElse: () => MeetingStatus.active,
      ),
      isPrivate: json['isPrivate'] as bool? ?? json['is_private'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      organizerName: json['organizer_name']?.toString(),
      organizerEmail: json['organizer_email']?.toString(),
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
