class User {
  final String id;
  final String email;
  final String? phone;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final List<String> interests;
  final String role; // 'user' or 'admin'
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  User({
    required this.id,
    required this.email,
    this.phone,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.interests = const [],
    this.role = 'user',
    required this.createdAt,
    this.updatedAt,
  });
  
  bool get isAdmin => role == 'admin';
  
  factory User.fromJson(Map<String, dynamic> json) {
    // Обработка interests: может быть List, String (из БД) или null
    List<String> interests = [];
    if (json['interests'] is List) {
      interests = (json['interests'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    } else if (json['interests'] is String) {
      final str = json['interests'] as String;
      if (str.isNotEmpty) {
        interests = str.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
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

    return User(
      id: (json['id'] ?? '').toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      name: json['name']?.toString() ?? 'Пользователь',
      avatarUrl: json['avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      interests: interests,
      role: json['role']?.toString() ?? 'user',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'name': name,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'interests': interests,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  
  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? name,
    String? avatarUrl,
    String? bio,
    List<String>? interests,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
