class PlacePhoto {
  final String id;
  final String placeId;
  final String userId;
  final String photoUrl;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatarUrl;

  PlacePhoto({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.photoUrl,
    required this.createdAt,
    this.userName,
    this.userAvatarUrl,
  });

  factory PlacePhoto.fromJson(Map<String, dynamic> json) {
    return PlacePhoto(
      id: (json['id'] ?? '').toString(),
      placeId: (json['place_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      photoUrl: json['photo_url'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      userName: json['name'] as String?,
      userAvatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placeId': placeId,
      'userId': userId,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
    };
  }
}
