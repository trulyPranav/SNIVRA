import '../../../../core/errors/api_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/saloon_model.dart';

class SaloonRepository {
  SaloonRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Saloon> createSaloon({
    required String creationCode,
    required String name,
    required double lat,
    required double lng,
    required String locationName,
  }) async {
    try {
      final data = await _apiClient.postJson(
        '/saloons/create',
        body: {
          'creation_code': creationCode,
          'name': name,
          'location': {'lat': lat, 'lng': lng},
          'location_name': locationName,
        },
        requiresAuth: true,
      );
      return Saloon.fromJson(data['saloon'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Saloon> joinSaloon({required String hashCode}) async {
    try {
      final data = await _apiClient.postJson(
        '/saloons/join',
        body: {'hash_code': hashCode},
        requiresAuth: true,
      );
      return Saloon.fromJson(data['saloon'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}

ApiError mapSaloonApiException(ApiException e) {
  switch (e.statusCode) {
    case 400:
      return ApiError(
        message: e.message,
        type: ApiErrorType.validation,
        statusCode: 400,
      );
    case 403:
      return ApiError.forbidden(e.message);
    case 404:
      return ApiError.notFound(e.message);
    case 409:
      return ApiError(
        message: e.message,
        type: ApiErrorType.validation,
        statusCode: 409,
      );
    default:
      return ApiError(
        message: e.message.isNotEmpty ? e.message : 'Something went wrong.',
        type: ApiErrorType.unknown,
        statusCode: e.statusCode,
      );
  }
}
