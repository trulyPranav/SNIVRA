import 'package:equatable/equatable.dart';

enum BarberRole { owner, barber }

BarberRole _barberRoleFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'OWNER':
      return BarberRole.owner;
    default:
      return BarberRole.barber;
  }
}

class SaloonBarber extends Equatable {
  const SaloonBarber({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.isAvailable,
  });

  final String id;
  final String name;
  final String phone;
  final BarberRole role;
  final bool isAvailable;

  SaloonBarber copyWith({bool? isAvailable}) => SaloonBarber(
        id: id,
        name: name,
        phone: phone,
        role: role,
        isAvailable: isAvailable ?? this.isAvailable,
      );

  factory SaloonBarber.fromJson(Map<String, dynamic> json) {
    return SaloonBarber(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: _barberRoleFromString(json['role'] as String?),
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, role, isAvailable];
}

class SaloonService extends Equatable {
  const SaloonService({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.durationMinutes,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? description;
  final double? price;
  final int? durationMinutes;
  final bool isActive;

  SaloonService copyWith({
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    bool? isActive,
  }) =>
      SaloonService(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        isActive: isActive ?? this.isActive,
      );

  factory SaloonService.fromJson(Map<String, dynamic> json) {
    return SaloonService(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      durationMinutes: json['duration_minutes'] as int?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, name, description, price, durationMinutes, isActive];
}
