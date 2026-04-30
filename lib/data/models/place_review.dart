class PlaceReview {
  final String id;
  final String placeId;
  final String userId;
  final int rating;
  final String? text;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatarUrl;

  PlaceReview({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.rating,
    this.text,
    required this.createdAt,
    this.userName,
    this.userAvatarUrl,
  });

  factory PlaceReview.fromJson(Map<String, dynamic> json) {
    return PlaceReview(
      id: (json['id'] ?? '').toString(),
      placeId: (json['place_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      rating: json['rating'] as int? ?? 0,
      text: json['text'] as String?,
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
      'rating': rating,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
    };
  }
}

class PlaceRating {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution;

  PlaceRating({
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
  });

  factory PlaceRating.fromJson(Map<String, dynamic> json) {
    return PlaceRating(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      distribution: {
        1: json['distribution']?['1'] as int? ?? 0,
        2: json['distribution']?['2'] as int? ?? 0,
        3: json['distribution']?['3'] as int? ?? 0,
        4: json['distribution']?['4'] as int? ?? 0,
        5: json['distribution']?['5'] as int? ?? 0,
      },
    );
  }
}
