import 'package:equatable/equatable.dart';

class Saloon extends Equatable {
  const Saloon({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.hashCode_,
    required this.ownerId,
    this.openingTime = '09:00:00',
    this.closingTime = '18:00:00',
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String locationName;
  final String hashCode_;
  final String ownerId;
  final String openingTime;
  final String closingTime;

  factory Saloon.fromJson(Map<String, dynamic> json) {
    return Saloon(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationName: json['location_name'] as String? ?? '',
      hashCode_: json['hash_code'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      openingTime: json['opening_time'] as String? ?? '09:00:00',
      closingTime: json['closing_time'] as String? ?? '18:00:00',
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        latitude,
        longitude,
        locationName,
        hashCode_,
        ownerId,
        openingTime,
        closingTime,
      ];
}
