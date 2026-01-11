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
    return Meeting(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      place: Place.fromJson(json['place'] as Map<String, dynamic>),
      startTime: DateTime.parse(json['startTime'] as String),
      durationMinutes: json['durationMinutes'] as int,
      maxParticipants: json['maxParticipants'] as int,
      participants: (json['participants'] as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
      creator: User.fromJson(json['creator'] as Map<String, dynamic>),
      status: MeetingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MeetingStatus.upcoming,
      ),
      isPrivate: json['isPrivate'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
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
}
