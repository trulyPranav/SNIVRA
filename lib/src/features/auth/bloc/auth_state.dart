import 'package:equatable/equatable.dart';

import '../data/models/auth_model.dart';
import '../../../core/errors/api_error.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial idle state – nothing has happened yet.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// An async operation is in progress.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Backend requires a phone number to complete first-time Google sign-up.
class AuthRequiresPhoneState extends AuthState {
  const AuthRequiresPhoneState({
    required this.supabaseAccessToken,
    required this.email,
    required this.suggestedName,
  });

  final String supabaseAccessToken;
  final String email;
  final String suggestedName;

  @override
  List<Object?> get props => [supabaseAccessToken, email, suggestedName];
}

/// Auth completed successfully.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({
    required this.user,
    required this.accessToken,
  });

  final AuthUser user;
  final String accessToken;

  @override
  List<Object?> get props => [user, accessToken];
}

/// An error occurred.
class AuthFailure extends AuthState {
  const AuthFailure({required this.error});

  final ApiError error;

  @override
  List<Object?> get props => [error];
}
