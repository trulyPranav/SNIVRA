import '../../../../core/network/api_client.dart';
import '../models/session_model.dart';

class SessionRepository {
  SessionRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Fetch (and auto-create) the three sessions for [saloonId] on [date].
  ///
  /// [date] must be formatted as 'YYYY-MM-DD'.
  Future<List<Session>> fetchSessions({
    required String saloonId,
    required String date,
  }) async {
    final data = await _apiClient.getJson(
      '/sessions/$saloonId',
      queryParameters: {'date': date},
      requiresAuth: true,
    );
    final list = (data['sessions'] as List<dynamic>?) ?? [];
    return list
        .map((e) => Session.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch detailed per-barber availability for a specific session.
  Future<SessionAvailability> fetchAvailability({
    required String sessionId,
  }) async {
    final data = await _apiClient.getJson(
      '/sessions/$sessionId/availability',
      requiresAuth: true,
    );
    return SessionAvailability.fromJson(data as Map<String, dynamic>);
  }
}
