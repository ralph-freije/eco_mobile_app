import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiError {
  ApiError._();

  static String message(Object error) {
    if (error is FormatException) return error.message;
    if (error is! DioException) {
      return 'Something went wrong. Please try again.';
    }

    if (_isConnectionFailure(error.type)) {
      return 'Cannot reach EcoTrack. Check that the backend is running and the API address is correct.';
    }

    final body = error.response?.data;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final errors = map['errors'];
      final errorsMessage = _firstError(errors);
      if (errorsMessage != null) return errorsMessage;

      final message = map['message'];
      final messageError = _firstError(message);
      if (messageError != null) return messageError;

      final dataError = _firstError(map['data']);
      if (dataError != null) return dataError;
    }

    final statusCode = error.response?.statusCode;
    if (statusCode != null && kDebugMode) {
      return 'The server could not complete the request (HTTP $statusCode).';
    }
    return 'Something went wrong. Please try again.';
  }

  static bool _isConnectionFailure(DioExceptionType type) =>
      type == DioExceptionType.connectionError ||
      type == DioExceptionType.connectionTimeout ||
      type == DioExceptionType.receiveTimeout ||
      type == DioExceptionType.sendTimeout;

  static String? _firstError(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is List) {
      for (final item in value) {
        final result = _firstError(item);
        if (result != null) return result;
      }
    }
    if (value is Map) {
      for (final item in value.values) {
        final result = _firstError(item);
        if (result != null) return result;
      }
    }
    return null;
  }
}
