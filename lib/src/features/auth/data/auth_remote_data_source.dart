import '../../../core/network/api_client.dart';
import 'auth_models.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<LoginResponse> login(LoginRequest request) async {
    final json = await _apiClient.postJson('/auth/login', body: request.toJson());
    return LoginResponse.fromJson(json);
  }

  Future<AuthSession> verifyOtp(OtpVerificationRequest request) async {
    final json = await _apiClient.postJson('/auth/otp', body: request.toJson());
    return AuthSession.fromJson(json);
  }
}