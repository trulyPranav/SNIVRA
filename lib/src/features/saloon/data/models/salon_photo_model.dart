class SalonPhoto {
  const SalonPhoto({
    required this.id,
    required this.photoUrl,
    required this.displayOrder,
    required this.createdAt,
  });

  final String id;
  final String photoUrl;
  final int displayOrder;
  final String createdAt;

  factory SalonPhoto.fromJson(Map<String, dynamic> json) {
    return SalonPhoto(
      id: json['id'] as String,
      photoUrl: json['photo_url'] as String,
      displayOrder: (json['display_order'] as num).toInt(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
