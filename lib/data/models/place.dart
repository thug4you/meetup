class Place {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? description;
  final List<String> photos;
  final double? rating;
  final String? phone;
  final String? website;
  final Map<String, String>? workingHours;
  
  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.description,
    this.photos = const [],
    this.rating,
    this.phone,
    this.website,
    this.workingHours,
  });
  
  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'].toString(),
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String?,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      rating: (json['rating'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      workingHours: (json['workingHours'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as String)),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'photos': photos,
      'rating': rating,
      'phone': phone,
      'website': website,
      'workingHours': workingHours,
    };
  }
}
