import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/saloon_storage.dart';
import '../../../core/storage/token_storage.dart';
import '../data/repository/auth_repo.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
    required TokenStorage tokenStorage,
    required SaloonStorage saloonStorage,
  })  : _repo = authRepository,
        _tokenStorage = tokenStorage,
        _saloonStorage = saloonStorage,
        super(const AuthInitial()) {
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthPhoneSubmitted>(_onPhoneSubmitted);
    on<AuthSignOutRequested>(_onSignOut);
  }

  final AuthRepository _repo;
  final TokenStorage _tokenStorage;
  final SaloonStorage _saloonStorage;

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final supabaseToken = await _repo.signInWithGoogle();
      final result = await _repo.exchangeGoogleToken(supabaseToken);

      if (result is AuthSuccess) {
        await _persist(result);
        emit(AuthAuthenticated(
            user: result.user, accessToken: result.accessToken));
      } else if (result is AuthRequiresPhone) {
        emit(AuthRequiresPhoneState(
          supabaseAccessToken: result.supabaseAccessToken,
          email: result.email,
          suggestedName: result.suggestedName,
        ));
      }
    } on ApiException catch (e) {
      emit(AuthFailure(error: mapApiException(e)));
    } catch (e) {
      emit(AuthFailure(error: mapApiException(ApiException(message: e.toString()))));
    }
  }

  Future<void> _onPhoneSubmitted(
    AuthPhoneSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _repo.exchangeGoogleToken(
        event.supabaseAccessToken,
        phone: event.phone,
        name: event.name,
      );

      if (result is AuthSuccess) {
        await _persist(result);
        emit(AuthAuthenticated(
            user: result.user, accessToken: result.accessToken));
      } else if (result is AuthRequiresPhone) {
        // Should not happen at this stage, but handle gracefully.
        emit(AuthRequiresPhoneState(
          supabaseAccessToken: result.supabaseAccessToken,
          email: result.email,
          suggestedName: result.suggestedName,
        ));
      }
    } on ApiException catch (e) {
      emit(AuthFailure(error: mapApiException(e)));
    } catch (e) {
      emit(AuthFailure(error: mapApiException(ApiException(message: e.toString()))));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.signOut();
    await Future.wait([
      _tokenStorage.clearAccessToken(),
      _saloonStorage.clearActiveSaloonId(),
    ]);
    emit(const AuthInitial());
  }

  Future<void> _persist(AuthSuccess result) async {
    await _tokenStorage.saveAccessToken(result.accessToken);
    if (result.user.saloons.isNotEmpty) {
      await _saloonStorage.saveActiveSaloonId(result.user.saloons.first.id);
    }
  }
}
