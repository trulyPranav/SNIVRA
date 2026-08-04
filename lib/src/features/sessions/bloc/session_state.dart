import 'package:equatable/equatable.dart';

import '../data/models/session_model.dart';

sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

class SessionInitial extends SessionState {
  const SessionInitial();
}

// ─── Sessions list ────────────────────────────────────────────────────────────

class SessionLoading extends SessionState {
  const SessionLoading();
}

class SessionLoaded extends SessionState {
  const SessionLoaded({
    required this.saloonId,
    required this.date,
    required this.sessions,
  });

  final String saloonId;
  final String date;
  final List<Session> sessions;

  @override
  List<Object?> get props => [saloonId, date, sessions];
}

class SessionError extends SessionState {
  const SessionError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ─── Availability detail ─────────────────────────────────────────────────────

class SessionAvailabilityLoading extends SessionState {
  const SessionAvailabilityLoading();
}

class SessionAvailabilityLoaded extends SessionState {
  const SessionAvailabilityLoaded({required this.availability});

  final SessionAvailability availability;

  @override
  List<Object?> get props => [availability];
}

class SessionAvailabilityError extends SessionState {
  const SessionAvailabilityError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
