import 'package:equatable/equatable.dart';

import '../../auth/data/models/auth_model.dart';

sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

/// Splash animation is still running / token check in progress.
class SplashChecking extends SplashState {
  const SplashChecking();
}

/// Stored token is valid – navigate to home.
class SplashAuthenticated extends SplashState {
  const SplashAuthenticated({required this.user});

  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

/// No stored token / token invalid – navigate to login.
class SplashUnauthenticated extends SplashState {
  const SplashUnauthenticated();
}
