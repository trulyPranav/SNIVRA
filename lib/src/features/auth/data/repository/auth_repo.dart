import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../core/errors/api_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/auth_model.dart';

/// Wraps the Google Sign-In → Supabase → SNIVRA backend auth flow.
class AuthRepository {
  AuthRepository({required ApiClient apiClient, GoogleSignIn? googleSignIn})
      : _apiClient = apiClient,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              // The web client ID from your Google Cloud project
              // (same one registered in Supabase Google provider).
              serverClientId: const String.fromEnvironment(
                'GOOGLE_WEB_CLIENT_ID',
              ),
            );

  final ApiClient _apiClient;
  final GoogleSignIn _googleSignIn;

  /// Step 1 – Trigger native Google sign-in and exchange for a Supabase
  /// session. Returns the Supabase access token.
  Future<String> signInWithGoogle() async {
    try {
      // Trigger the Google sign-in picker.
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const ApiException(message: 'Sign-in cancelled by user.');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw const ApiException(
            message: 'Failed to obtain Google ID token.');
      }

      // Exchange with Supabase to get a Supabase session.
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      final supabaseAccessToken = response.session?.accessToken;
      if (supabaseAccessToken == null) {
        throw const ApiException(
            message: 'Failed to establish Supabase session.');
      }

      return supabaseAccessToken;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Step 2a – Send the Supabase access token to the SNIVRA backend.
  /// Returns an [AuthGoogleResult] that is either [AuthSuccess] or
  /// [AuthRequiresPhone].
  Future<AuthGoogleResult> exchangeGoogleToken(String supabaseAccessToken,
      {String? phone, String? name}) async {
    try {
      final body = <String, dynamic>{
        'access_token': supabaseAccessToken,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (name != null && name.isNotEmpty) 'name': name,
      };
      final data = await _apiClient.postJson('/auth/google', body: body);

      if (data['requires_phone'] == true) {
        return AuthRequiresPhone(
          supabaseAccessToken: supabaseAccessToken,
          email: data['email'] as String? ?? '',
          suggestedName: data['suggested_name'] as String? ?? '',
        );
      }

      final snivraToken = data['access_token'] as String?;
      final userJson = data['user'] as Map<String, dynamic>?;
      if (snivraToken == null || userJson == null) {
        throw const ApiException(message: 'Unexpected response from server.');
      }

      return AuthSuccess(
        accessToken: snivraToken,
        user: AuthUser.fromJson(userJson),
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches the current user profile. Used by splash to validate a stored
  /// token.
  Future<AuthUser> fetchCurrentUser() async {
    try {
      final data = await _apiClient.getJson('/users/me', requiresAuth: true);
      final userJson = data['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        throw const ApiException(message: 'User data missing in response.');
      }
      return AuthUser.fromJson(userJson);
    } on ApiException {
      rethrow;
    }
  }

  /// Sign out – clears Google session and Supabase session.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }
}

/// Sealed result of the Google token exchange.
sealed class AuthGoogleResult {}

class AuthSuccess extends AuthGoogleResult {
  AuthSuccess({required this.accessToken, required this.user});
  final String accessToken;
  final AuthUser user;
}

class AuthRequiresPhone extends AuthGoogleResult {
  AuthRequiresPhone({
    required this.supabaseAccessToken,
    required this.email,
    required this.suggestedName,
  });
  final String supabaseAccessToken;
  final String email;
  final String suggestedName;
}

/// Maps an [ApiException] to an [ApiError].
ApiError mapApiException(ApiException e) {
  switch (e.statusCode) {
    case 400:
      return ApiError.validation(e.message);
    case 401:
      return ApiError.unauthorized(e.message);
    case 403:
      return ApiError.forbidden(e.message);
    case 404:
      return ApiError.notFound(e.message);
    case 409:
      return ApiError.validation(e.message);
    default:
      if (e.message.contains('reach')) return ApiError.network(e.message);
      return ApiError.server(e.message);
  }
}
