import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/home_model.dart';

class HomeRepository {
  HomeRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// GET /saloons/:saloon_id/barbers
  Future<List<SaloonBarber>> fetchBarbers(String saloonId) async {
    try {
      final data = await _apiClient.getJson(
        '/saloons/$saloonId/barbers',
        requiresAuth: true,
      );
      return (data['barbers'] as List<dynamic>)
          .map((e) => SaloonBarber.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// PATCH /saloons/:saloon_id/open
  /// Returns the confirmed is_open value from the API response.
  Future<bool> setSaloonOpen(String saloonId, {required bool isOpen}) async {
    try {
      final data = await _apiClient.patchJson(
        '/saloons/$saloonId/open',
        body: {'is_open': isOpen},
        requiresAuth: true,
      );
      final saloon = data['saloon'] as Map<String, dynamic>?;
      return (saloon?['is_open'] as bool?) ?? isOpen;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// POST /saloons/:saloon_id/availability
  /// [barberId] is optional: null = caller sets for themselves;
  /// owner can pass another barber's id.
  Future<void> setBarberUnavailable({
    required String saloonId,
    required DateTime unavailableFrom,
    required DateTime unavailableUntil,
    String? barberId,
  }) async {
    try {
      await _apiClient.postJson(
        '/saloons/$saloonId/availability',
        body: {
          'unavailable_from': unavailableFrom.toUtc().toIso8601String(),
          'unavailable_until': unavailableUntil.toUtc().toIso8601String(),
          if (barberId != null) 'barber_id': barberId,
        },
        requiresAuth: true,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// DELETE /saloons/:saloon_id/availability
  /// [barberId] is optional body field (owner only, to target another barber).
  Future<void> restoreBarberAvailability({
    required String saloonId,
    String? barberId,
  }) async {
    try {
      await _apiClient.deleteJson(
        '/saloons/$saloonId/availability',
        body: barberId != null ? {'barber_id': barberId} : null,
        requiresAuth: true,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// GET /saloons/:saloon_id/services
  Future<List<SaloonService>> fetchServices(String saloonId) async {
    try {
      final data = await _apiClient.getJson(
        '/saloons/$saloonId/services',
        requiresAuth: false,
      );
      return (data['services'] as List<dynamic>)
          .map((e) => SaloonService.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// POST /saloons/:saloon_id/services — owner only
  Future<SaloonService> addService(
    String saloonId, {
    required String name,
    String? description,
    double? price,
    int? durationMinutes,
  }) async {
    try {
      final data = await _apiClient.postJson(
        '/saloons/$saloonId/services',
        body: {
          'name': name,
          if (description != null) 'description': description,
          if (price != null) 'price': price,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
        },
        requiresAuth: true,
      );
      return SaloonService.fromJson(data['service'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// PATCH /saloons/:saloon_id/services/:service_id — owner only
  Future<SaloonService> updateService(
    String saloonId,
    String serviceId, {
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    bool? isActive,
  }) async {
    try {
      final data = await _apiClient.patchJson(
        '/saloons/$saloonId/services/$serviceId',
        body: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (price != null) 'price': price,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
          if (isActive != null) 'is_active': isActive,
        },
        requiresAuth: true,
      );
      return SaloonService.fromJson(data['service'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// DELETE /saloons/:saloon_id/services/:service_id — owner only
  Future<void> deleteService(String saloonId, String serviceId) async {
    try {
      await _apiClient.deleteJson(
        '/saloons/$saloonId/services/$serviceId',
        requiresAuth: true,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
