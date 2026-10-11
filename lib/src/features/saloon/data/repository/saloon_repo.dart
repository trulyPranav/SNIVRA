import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/errors/api_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/saloon_model.dart';
import '../models/salon_photo_model.dart';

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

  Future<Saloon> updateSaloon({
    required String saloonId,
    required String name,
    required double lat,
    required double lng,
    String? locationName,
    String? openingTime,
    String? closingTime,
  }) async {
    try {
      final data = await _apiClient.patchJson(
        '/saloons/$saloonId/update',
        body: {
          'name': name,
          'location': {'lat': lat, 'lng': lng},
          'location_name': locationName,
          'opening_time': openingTime,
          'closing_time': closingTime,
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
  Future<List<SalonPhoto>> fetchPhotos({required String saloonId}) async {
    try {
      final data = await _apiClient.getJson('/saloons/$saloonId/photos');
      final list = data['photos'] as List<dynamic>;
      return list
          .map((e) => SalonPhoto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<SalonPhoto> uploadPhoto({
    required String saloonId,
    required Uint8List imageBytes,
    required String fileName,
    int displayOrder = 0,
  }) async {
    try {
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(imageBytes, filename: fileName),
        'display_order': displayOrder.toString(),
      });
      final data = await _apiClient.postMultipart(
        '/saloons/$saloonId/photos',
        formData: formData,
        requiresAuth: true,
      );
      return SalonPhoto.fromJson(data['photo'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> deletePhoto({
    required String saloonId,
    required String photoId,
  }) async {
    try {
      await _apiClient.deleteJson(
        '/saloons/$saloonId/photos/$photoId',
        requiresAuth: true,
      );
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
