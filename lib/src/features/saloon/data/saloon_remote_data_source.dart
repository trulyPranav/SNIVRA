import '../../../core/network/api_client.dart';
import 'saloon_models.dart';

class SaloonRemoteDataSource {
  SaloonRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Saloon> createSaloon(CreateSaloonRequest request) async {
    final json = await _apiClient.postJson('/saloons/create', body: request.toJson(), requiresAuth: true);
    return Saloon.fromJson((json['saloon'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{});
  }

  Future<Saloon> joinSaloon(JoinSaloonRequest request) async {
    final json = await _apiClient.postJson('/saloons/join', body: request.toJson(), requiresAuth: true);
    return Saloon.fromJson((json['saloon'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{});
  }
}