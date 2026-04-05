part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthPhoneChanged extends AuthEvent {
  const AuthPhoneChanged(this.phone);

  final String phone;

  @override
  List<Object?> get props => [phone];
}

class AuthNameChanged extends AuthEvent {
  const AuthNameChanged(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

class AuthOtpChanged extends AuthEvent {
  const AuthOtpChanged(this.otp);

  final String otp;

  @override
  List<Object?> get props => [otp];
}

class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted();
}

class AuthOtpSubmitted extends AuthEvent {
  const AuthOtpSubmitted();
}

class AuthResetRequested extends AuthEvent {
  const AuthResetRequested();
}

class AuthModeToggled extends AuthEvent {
  const AuthModeToggled();
}