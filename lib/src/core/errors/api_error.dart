import 'package:equatable/equatable.dart';

enum ApiErrorType {
  network,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  cancelled,
  unknown,
}

class ApiError extends Equatable {
  const ApiError({
    required this.message,
    required this.type,
    this.statusCode,
    this.details,
  });

  final String message;
  final ApiErrorType type;
  final int? statusCode;
  final Object? details;

  factory ApiError.network([String message = 'Unable to reach the server.']) {
    return ApiError(message: message, type: ApiErrorType.network);
  }

  factory ApiError.unauthorized([String message = 'Session expired. Please login again.']) {
    return ApiError(message: message, type: ApiErrorType.unauthorized, statusCode: 401);
  }

  factory ApiError.forbidden([String message = 'You do not have permission to perform this action.']) {
    return ApiError(message: message, type: ApiErrorType.forbidden, statusCode: 403);
  }

  factory ApiError.notFound([String message = 'The requested resource was not found.']) {
    return ApiError(message: message, type: ApiErrorType.notFound, statusCode: 404);
  }

  factory ApiError.validation([String message = 'Please check your input and try again.']) {
    return ApiError(message: message, type: ApiErrorType.validation, statusCode: 400);
  }

  factory ApiError.server([String message = 'Something went wrong on our side.']) {
    return ApiError(message: message, type: ApiErrorType.server, statusCode: 500);
  }

  factory ApiError.unknown([String message = 'Unexpected error occurred.']) {
    return ApiError(message: message, type: ApiErrorType.unknown);
  }

  @override
  List<Object?> get props => [message, type, statusCode, details];
}