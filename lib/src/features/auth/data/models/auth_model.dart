import 'package:equatable/equatable.dart';

enum UserRole { customer, barber, owner }

UserRole _roleFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'BARBER':
      return UserRole.barber;
    case 'OWNER':
      return UserRole.owner;
    default:
      return UserRole.customer;
  }
}

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
    this.saloons = const [],
  });

  final String id;
  final String phone;
  final String name;
  final UserRole role;
  final List<UserSaloon> saloons;

  bool get isOwnerOrBarber =>
      role == UserRole.owner || role == UserRole.barber;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final saloonsList = (json['saloons'] as List<dynamic>?)
            ?.map((e) => UserSaloon.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return AuthUser(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String? ?? '',
      role: _roleFromString(json['role'] as String?),
      saloons: saloonsList,
    );
  }

  @override
  List<Object?> get props => [id, phone, name, role, saloons];
}

class UserSaloon extends Equatable {
  const UserSaloon({
    required this.id,
    required this.name,
    required this.hashCode_,
    required this.ownerId,
    this.isOpen,
  });

  final String id;
  final String name;
  final String hashCode_;
  final String ownerId;

  /// Reflects the live `is_open` flag from the server (null if not yet known).
  final bool? isOpen;

  factory UserSaloon.fromJson(Map<String, dynamic> json) {
    return UserSaloon(
      id: json['id'] as String,
      name: json['name'] as String,
      hashCode_: json['hash_code'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      isOpen: json['is_open'] as bool?,
    );
  }

  @override
  List<Object?> get props => [id, name, hashCode_, ownerId, isOpen];
}
