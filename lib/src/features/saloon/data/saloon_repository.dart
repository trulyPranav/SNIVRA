import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'saloon_models.dart';
import 'saloon_remote_data_source.dart';

class SaloonRepository {
  SaloonRepository({required ApiClient apiClient}) : _remoteDataSource = SaloonRemoteDataSource(apiClient: apiClient);

  final SaloonRemoteDataSource _remoteDataSource;

  Future<Saloon> createSaloon({
    required String creationCode,
    required String name,
    required String locationName,
    required double lat,
    required double lng,
  }) async {
    try {
      return await _remoteDataSource.createSaloon(
        CreateSaloonRequest(
          creationCode: creationCode,
          name: name,
          locationName: locationName,
          lat: lat,
          lng: lng,
        ),
      );
    } on ApiException catch (error) {
      throw error.toApiError();
    }
  }

  Future<Saloon> joinSaloon({required String hashCode}) async {
    try {
      return await _remoteDataSource.joinSaloon(JoinSaloonRequest(code: hashCode));
    } on ApiException catch (error) {
      throw error.toApiError();
    }
  }
}