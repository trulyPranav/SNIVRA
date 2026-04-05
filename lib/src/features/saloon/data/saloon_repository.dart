import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/saloon_storage.dart';
import 'saloon_models.dart';
import 'saloon_remote_data_source.dart';

class SaloonRepository {
  SaloonRepository({required ApiClient apiClient, SaloonStorage? saloonStorage})
      : _remoteDataSource = SaloonRemoteDataSource(apiClient: apiClient),
        _saloonStorage = saloonStorage ?? SaloonStorage();

  final SaloonRemoteDataSource _remoteDataSource;
  final SaloonStorage _saloonStorage;

  Future<String?> readActiveSaloonId() async {
    return _saloonStorage.readActiveSaloonId();
  }

  Future<void> saveActiveSaloonId(String saloonId) async {
    await _saloonStorage.saveActiveSaloonId(saloonId);
  }

  Future<void> clearActiveSaloonId() async {
    await _saloonStorage.clearActiveSaloonId();
  }

  Future<Saloon> createSaloon({
    required String creationCode,
    required String name,
    required String locationName,
    required double lat,
    required double lng,
  }) async {
    try {
      final saloon = await _remoteDataSource.createSaloon(
        CreateSaloonRequest(
          creationCode: creationCode,
          name: name,
          locationName: locationName,
          lat: lat,
          lng: lng,
        ),
      );
      await saveActiveSaloonId(saloon.id);
      return saloon;
    } on ApiException catch (error) {
      throw error.toApiError();
    }
  }

  Future<Saloon> joinSaloon({required String hashCode}) async {
    try {
      final saloon = await _remoteDataSource.joinSaloon(JoinSaloonRequest(code: hashCode));
      await saveActiveSaloonId(saloon.id);
      return saloon;
    } on ApiException catch (error) {
      throw error.toApiError();
    }
  }
}