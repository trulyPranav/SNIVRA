import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
    this.isActive,
  });

  final String id;
  final String phone;
  final String name;
  final String role;
  final bool? isActive;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'CUSTOMER',
      isActive: json['is_active'] as bool?,
    );
  }

  @override
  List<Object?> get props => [id, phone, name, role, isActive];
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