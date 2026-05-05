import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/insights_model.dart';

class InsightsRepository {
  InsightsRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// GET /saloons/:saloon_id/insights?month=YYYY-MM
  /// [month] format: "2026-05". Defaults to current month on the server when omitted.
  Future<SaloonInsights> fetchInsights(
    String saloonId, {
    required String month,
  }) async {
    try {
      final data = await _apiClient.getJson(
        '/saloons/$saloonId/insights',
        queryParameters: {'month': month},
        requiresAuth: true,
      );
      return SaloonInsights.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
