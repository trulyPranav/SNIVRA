import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'auth_models.dart';
import 'auth_remote_data_source.dart';

class AuthRepository {
  AuthRepository({required ApiClient apiClient})
      : _remoteDataSource = AuthRemoteDataSource(apiClient: apiClient),
        _apiClient = apiClient;

  final AuthRemoteDataSource _remoteDataSource;
  final ApiClient _apiClient;

  Future<LoginResponse> login({required String phone, String? name}) async {
    try {
      return await _remoteDataSource.login(LoginRequest(phone: phone, name: name));
    } on ApiException catch (error) {
      throw error.toApiError();
    }
  }

  Future<AuthSession> verifyOtp({required String phone, required String otp}) async {
    try {
      final session = await _remoteDataSource.verifyOtp(OtpVerificationRequest(phone: phone, otp: otp));
      _apiClient.accessToken = session.accessToken;
      return session;
    } on ApiException catch (error) {
      throw error.toApiError();
    }
  }

  void clearToken() {
    _apiClient.accessToken = null;
  }
}