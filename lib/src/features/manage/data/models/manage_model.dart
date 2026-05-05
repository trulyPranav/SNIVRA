enum BarberRole { owner, barber }

extension BarberRoleX on BarberRole {
  String get apiValue => this == BarberRole.owner ? 'OWNER' : 'BARBER';

  static BarberRole fromJson(String raw) {
    return raw.toUpperCase() == 'OWNER' ? BarberRole.owner : BarberRole.barber;
  }
}

class SaloonMember {
  const SaloonMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.isPrimaryOwner,
    this.joinedAt,
  });

  final String id;
  final String name;
  final String phone;
  final BarberRole role;
  final bool isPrimaryOwner;
  final DateTime? joinedAt;

  factory SaloonMember.fromJson(Map<String, dynamic> json) {
    return SaloonMember(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: BarberRoleX.fromJson(json['role'] as String? ?? 'BARBER'),
      isPrimaryOwner: json['is_primary_owner'] as bool? ?? false,
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'] as String)
          : null,
    );
  }

  SaloonMember copyWith({BarberRole? role}) {
    return SaloonMember(
      id: id,
      name: name,
      phone: phone,
      role: role ?? this.role,
      isPrimaryOwner: isPrimaryOwner,
      joinedAt: joinedAt,
    );
  }
}
