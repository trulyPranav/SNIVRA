import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/manage_model.dart';

class ManageRepository {
  ManageRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// GET /saloons/:saloon_id/manage/barbers
  Future<List<SaloonMember>> fetchMembers(String saloonId) async {
    try {
      final data = await _apiClient.getJson(
        '/saloons/$saloonId/manage/barbers',
        requiresAuth: true,
      );
      final list = (data['barbers'] as List<dynamic>?) ?? [];
      return list
          .map((e) => SaloonMember.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// PATCH /saloons/:saloon_id/manage/barbers/:barber_id/role
  Future<String> updateRole({
    required String saloonId,
    required String barberId,
    required BarberRole role,
  }) async {
    try {
      final data = await _apiClient.patchJson(
        '/saloons/$saloonId/manage/barbers/$barberId/role',
        body: {'role': role.apiValue},
        requiresAuth: true,
      );
      return data['message'] as String? ?? 'Role updated';
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// DELETE /saloons/:saloon_id/manage/barbers/:barber_id
  Future<String> removeMember({
    required String saloonId,
    required String barberId,
  }) async {
    try {
      final data = await _apiClient.deleteJson(
        '/saloons/$saloonId/manage/barbers/$barberId',
        requiresAuth: true,
      );
      return data['message'] as String? ?? 'Barber removed from saloon';
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
