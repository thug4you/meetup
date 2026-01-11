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
    return Message(
      id: json['id'] as String,
      meetingId: json['meetingId'] as String,
      sender: User.fromJson(json['sender'] as Map<String, dynamic>),
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
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
