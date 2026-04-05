import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_models.dart';
import 'auth_remote_data_source.dart';

class AuthRepository {
  AuthRepository({required ApiClient apiClient, TokenStorage? tokenStorage})
      : _remoteDataSource = AuthRemoteDataSource(apiClient: apiClient),
        _apiClient = apiClient,
        _tokenStorage = tokenStorage ?? TokenStorage();

  final AuthRemoteDataSource _remoteDataSource;
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<bool> initializeSession() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      _apiClient.accessToken = null;
      return false;
    }
    _apiClient.accessToken = token;
    return true;
  }

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
      await _tokenStorage.saveAccessToken(session.accessToken);
      return session;
    } on ApiException catch (error) {
      throw error.toApiError();
    }
  }

  Future<void> clearToken() async {
    _apiClient.accessToken = null;
    await _tokenStorage.clearAccessToken();
  }
}