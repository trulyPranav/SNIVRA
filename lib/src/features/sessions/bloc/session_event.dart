import 'package:equatable/equatable.dart';

sealed class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

/// Load the three sessions (MORNING / AFTERNOON / EVENING) for [saloonId]
/// on [date] ('YYYY-MM-DD').
class SessionsRequested extends SessionEvent {
  const SessionsRequested({
    required this.saloonId,
    required this.date,
  });

  final String saloonId;
  final String date;

  @override
  List<Object?> get props => [saloonId, date];
}

/// Refresh live per-barber capacity for a specific session.
class SessionAvailabilityRequested extends SessionEvent {
  const SessionAvailabilityRequested({required this.sessionId});

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}
