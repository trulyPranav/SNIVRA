import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../data/repository/session_repo.dart';
import 'session_event.dart';
import 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({required SessionRepository sessionRepository})
      : _repo = sessionRepository,
        super(const SessionInitial()) {
    on<SessionsRequested>(_onSessionsRequested);
    on<SessionAvailabilityRequested>(_onAvailabilityRequested);
  }

  final SessionRepository _repo;

  Future<void> _onSessionsRequested(
    SessionsRequested event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());
    try {
      final sessions = await _repo.fetchSessions(
        saloonId: event.saloonId,
        date: event.date,
      );
      emit(SessionLoaded(
        saloonId: event.saloonId,
        date: event.date,
        sessions: sessions,
      ));
    } on ApiException catch (e) {
      emit(SessionError(message: e.message));
    } catch (e) {
      emit(SessionError(message: e.toString()));
    }
  }

  Future<void> _onAvailabilityRequested(
    SessionAvailabilityRequested event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionAvailabilityLoading());
    try {
      final availability =
          await _repo.fetchAvailability(sessionId: event.sessionId);
      emit(SessionAvailabilityLoaded(availability: availability));
    } on ApiException catch (e) {
      emit(SessionAvailabilityError(message: e.message));
    } catch (e) {
      emit(SessionAvailabilityError(message: e.toString()));
    }
  }
}
