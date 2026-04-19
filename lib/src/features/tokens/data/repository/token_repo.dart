import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';

class TokenRepository {
  const TokenRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Registers [fcmToken] with the backend so the server can send push
  /// notifications to this device. Requires a valid access token on
  /// [ApiClient] (call after authentication).
  Future<void> registerFcmToken(String fcmToken) async {
    try {
      await _apiClient.postJson(
        '/tokens/fcm',
        body: {'token': fcmToken},
        requiresAuth: true,
      );
    } on ApiException {
      // Token registration is best-effort; swallow errors to avoid
      // disrupting the normal app flow.
      rethrow;
    }
  }
}
