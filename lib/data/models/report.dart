enum ReportType {
  meeting,
  user,
  message,
}

enum ReportReason {
  spam,
  harassment,
  inappropriateContent,
  falseInformation,
  other,
}

class Report {
  final String id;
  final ReportType type;
  final ReportReason reason;
  final String description;
  final String reporterId;
  final String? targetId; // ID встречи, пользователя или сообщения
  final DateTime createdAt;
  final String? status; // pending, reviewed, resolved

  Report({
    required this.id,
    required this.type,
    required this.reason,
    required this.description,
    required this.reporterId,
    this.targetId,
    required this.createdAt,
    this.status,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: (json['id'] ?? '').toString(),
      type: ReportType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['type'] ?? ''),
        orElse: () => ReportType.meeting,
      ),
      reason: ReportReason.values.firstWhere(
        (e) => e.toString().split('.').last == (json['reason'] ?? ''),
        orElse: () => ReportReason.other,
      ),
      description: json['description'] as String? ?? '',
      reporterId: (json['reporterId'] ?? json['reporter_id'] ?? '').toString(),
      targetId: (json['targetId'] ?? json['reported_user_id'] ?? json['meeting_id'])?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'reason': reason.toString().split('.').last,
      'description': description,
      'reporterId': reporterId,
      'targetId': targetId,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  static String getReasonText(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return 'Спам';
      case ReportReason.harassment:
        return 'Оскорбления/Домогательства';
      case ReportReason.inappropriateContent:
        return 'Неприемлемый контент';
      case ReportReason.falseInformation:
        return 'Ложная информация';
      case ReportReason.other:
        return 'Другое';
    }
  }
}
