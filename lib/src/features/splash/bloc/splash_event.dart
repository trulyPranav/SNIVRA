import 'package:equatable/equatable.dart';

sealed class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered as soon as the splash page mounts.
class SplashStarted extends SplashEvent {
  const SplashStarted();
}
