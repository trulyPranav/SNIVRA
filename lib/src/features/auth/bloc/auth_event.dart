import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// User tapped "Sign in with Google".
class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// User submitted their phone number (first-time Google sign-up).
class AuthPhoneSubmitted extends AuthEvent {
  const AuthPhoneSubmitted({
    required this.supabaseAccessToken,
    required this.phone,
    this.name,
  });

  final String supabaseAccessToken;
  final String phone;
  final String? name;

  @override
  List<Object?> get props => [supabaseAccessToken, phone, name];
}

/// User tapped sign-out.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
