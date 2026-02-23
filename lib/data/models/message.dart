import 'user.dart';

class Message {
  final String id;
  final String meetingId;
  final User sender;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  
  Message({
    required this.id,
    required this.meetingId,
    required this.sender,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });
  
  factory Message.fromJson(Map<String, dynamic> json) {
    // Поддержка как camelCase так и snake_case
    // sender может быть объектом или собран из полей верхнего уровня
    User sender;
    if (json['sender'] is Map<String, dynamic>) {
      sender = User.fromJson(json['sender'] as Map<String, dynamic>);
    } else {
      // Данные отправителя на верхнем уровне (из JOIN запроса)
      sender = User(
        id: (json['user_id'] ?? json['sender_id'] ?? '').toString(),
        email: json['sender_email']?.toString() ?? '',
        name: json['sender_name']?.toString() ?? json['name']?.toString() ?? 'Пользователь',
        createdAt: DateTime.now(),
      );
    }

    final sentAtStr = json['sentAt'] ?? json['sent_at'] ?? json['created_at'];
    
    DateTime sentAt;
    try {
      sentAt = sentAtStr != null
          ? DateTime.parse(sentAtStr.toString())
          : DateTime.now();
    } catch (_) {
      sentAt = DateTime.now();
    }

    return Message(
      id: (json['id'] ?? '').toString(),
      meetingId: (json['meetingId'] ?? json['meeting_id'] ?? '').toString(),
      sender: sender,
      content: json['content']?.toString() ?? '',
      sentAt: sentAt,
      isRead: json['isRead'] as bool? ?? json['is_read'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meetingId': meetingId,
      'sender': sender.toJson(),
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
    };
  }
  
  Message copyWith({
    String? id,
    String? meetingId,
    User? sender,
    String? content,
    DateTime? sentAt,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
