import 'package:equatable/equatable.dart';

class Saloon extends Equatable {
  const Saloon({
    required this.id,
    required this.name,
    this.code,
    this.locationName,
  });

  final String id;
  final String name;
  final String? code;
  final String? locationName;

  factory Saloon.fromJson(Map<String, dynamic> json) {
    return Saloon(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['hash_code']?.toString(),
      locationName: json['location_name']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, code, locationName];
}

class CreateSaloonRequest extends Equatable {
  const CreateSaloonRequest({
    required this.creationCode,
    required this.name,
    required this.locationName,
    required this.lat,
    required this.lng,
  });

  final String creationCode;
  final String name;
  final String locationName;
  final double lat;
  final double lng;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'creation_code': creationCode,
      'name': name,
      'location': {'lat': lat, 'lng': lng},
      'location_name': locationName,
    };
  }

  @override
  List<Object?> get props => [creationCode, name, locationName, lat, lng];
}

class JoinSaloonRequest extends Equatable {
  const JoinSaloonRequest({required this.code});

  final String code;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'hash_code': code};
  }

  @override
  List<Object?> get props => [code];
}