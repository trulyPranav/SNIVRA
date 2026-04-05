import 'package:equatable/equatable.dart';

class AuthSaloon extends Equatable {
  const AuthSaloon({
    required this.id,
    required this.name,
    this.saloonHashCode,
  });

  final String id;
  final String name;
  final String? saloonHashCode;

  factory AuthSaloon.fromJson(Map<String, dynamic> json) {
    return AuthSaloon(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      saloonHashCode: json['hash_code']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, saloonHashCode];
}

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
    this.isActive,
    this.saloons = const [],
  });

  final String id;
  final String phone;
  final String name;
  final String role;
  final bool? isActive;
  final List<AuthSaloon> saloons;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final saloonsJson = (json['saloons'] as List?) ?? const [];
    return AuthUser(
      id: json['id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'CUSTOMER',
      isActive: json['is_active'] as bool?,
      saloons: saloonsJson
          .whereType<Map>()
          .map((item) => AuthSaloon.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [id, phone, name, role, isActive, saloons];
}

class LoginRequest extends Equatable {
  const LoginRequest({required this.phone, this.name});

  final String phone;
  final String? name;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'phone': phone,
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
    };
  }

  @override
  List<Object?> get props => [phone, name];
}

class LoginResponse extends Equatable {
  const LoginResponse({
    required this.message,
    required this.isNewUser,
    required this.phone,
  });

  final String message;
  final bool isNewUser;
  final String phone;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message']?.toString() ?? '',
      isNewUser: json['is_new_user'] == true,
      phone: json['phone']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [message, isNewUser, phone];
}

class AuthSession extends Equatable {
  const AuthSession({
    required this.message,
    required this.user,
    required this.accessToken,
    required this.tokenType,
  });

  final String message;
  final AuthUser user;
  final String accessToken;
  final String tokenType;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      message: json['message']?.toString() ?? '',
      user: AuthUser.fromJson((json['user'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{}),
      accessToken: json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'Bearer',
    );
  }

  @override
  List<Object?> get props => [message, user, accessToken, tokenType];
}

class OtpVerificationRequest extends Equatable {
  const OtpVerificationRequest({required this.phone, required this.otp});

  final String phone;
  final String otp;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'phone': phone,
      'otp': otp,
    };
  }

  @override
  List<Object?> get props => [phone, otp];
}