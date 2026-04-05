import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../errors/api_error.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? _defaultBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                headers: const {'Content-Type': 'application/json'},
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          handler.reject(error);
        },
      ),
    );
  }

  final Dio _dio;
  String? _accessToken;

  static String get _defaultBaseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

  set accessToken(String? token) {
    _accessToken = token;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: _buildOptions(requiresAuth: requiresAuth),
      );
      return _decodeMap(response.data);
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: body,
        options: _buildOptions(requiresAuth: requiresAuth),
      );
      return _decodeMap(response.data);
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Object? body,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        path,
        data: body,
        options: _buildOptions(requiresAuth: requiresAuth),
      );
      return _decodeMap(response.data);
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Object? body,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        data: body,
        options: _buildOptions(requiresAuth: requiresAuth),
      );
      return _decodeMap(response.data);
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  Options _buildOptions({required bool requiresAuth}) {
    final headers = <String, dynamic>{};
    if (requiresAuth && _accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return Options(headers: headers);
  }

  Map<String, dynamic> _decodeMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return <String, dynamic>{'data': data};
  }

  ApiException _mapException(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ApiException(message: 'Unable to reach the server.', statusCode: error.response?.statusCode, payload: error.response?.data);
    }

    final responseData = error.response?.data;
    final payload = responseData is Map<String, dynamic>
        ? responseData
        : responseData is String
            ? <String, dynamic>{'error': responseData}
            : null;
    final message = _extractErrorMessage(payload) ?? error.message ?? 'Request failed.';

    return ApiException(
      message: message,
      statusCode: error.response?.statusCode,
      payload: payload,
    );
  }

  String? _extractErrorMessage(Map<String, dynamic>? payload) {
    if (payload == null) {
      return null;
    }
    final errorValue = payload['error'];
    if (errorValue is String && errorValue.isNotEmpty) {
      return errorValue;
    }
    final messageValue = payload['message'];
    if (messageValue is String && messageValue.isNotEmpty) {
      return messageValue;
    }
    return null;
  }
}

extension ApiExceptionMapper on ApiException {
  ApiError toApiError() {
    final status = statusCode;
    if (status == 400) {
      return ApiError.validation(message);
    }
    if (status == 401) {
      return ApiError.unauthorized(message);
    }
    if (status == 403) {
      return ApiError.forbidden(message);
    }
    if (status == 404) {
      return ApiError.notFound(message);
    }
    if (status != null && status >= 500) {
      return ApiError.server(message);
    }
    return ApiError.network(message);
  }
}