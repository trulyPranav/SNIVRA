import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/saloon_storage.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/data/repository/auth_repo.dart';
import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc({
    required AuthRepository authRepository,
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    required SaloonStorage saloonStorage,
  })  : _authRepo = authRepository,
        _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        _saloonStorage = saloonStorage,
        super(const SplashChecking()) {
    on<SplashStarted>(_onStarted);
  }

  final AuthRepository _authRepo;
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final SaloonStorage _saloonStorage;

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    // Minimum splash display time (lets the animation play).
    await Future.delayed(const Duration(milliseconds: 2000));

    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      emit(const SplashUnauthenticated());
      return;
    }

    try {
      _apiClient.accessToken = token;
      final user = await _authRepo.fetchCurrentUser();

      // Restore active saloon from profile if not already stored.
      if (user.saloons.isNotEmpty) {
        final stored = await _saloonStorage.readActiveSaloonId();
        if (stored == null || stored.isEmpty) {
          await _saloonStorage.saveActiveSaloonId(user.saloons.first.id);
        }
      }

      emit(SplashAuthenticated(user: user));
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 404) {
        await _tokenStorage.clearAccessToken();
        await _saloonStorage.clearActiveSaloonId();
        _apiClient.accessToken = null;
      }
      emit(const SplashUnauthenticated());
    } catch (_) {
      emit(const SplashUnauthenticated());
    }
  }
}
