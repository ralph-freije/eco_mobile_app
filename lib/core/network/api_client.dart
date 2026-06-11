import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import '../utils/api_error.dart';

class ApiClient {
  ApiClient._()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.instance.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            debugPrint('[API] ${options.method} ${options.uri}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('[API] ${response.statusCode} ${response.requestOptions.uri}');
            debugPrint('[API] response: ${_redact(response.data)}');
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            debugPrint('[API] Dio error type: ${error.type}');
            debugPrint('[API] status: ${error.response?.statusCode}');
            debugPrint('[API] response: ${_redact(error.response?.data)}');
          }
          if (error.response?.statusCode == 401 &&
              error.requestOptions.path != ApiConstants.login) {
            await TokenStorage.instance.clearToken();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();
  final Dio _dio;
  VoidCallback? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    return response.data;
  }

  Future<dynamic> post(String path, {Object? data}) async {
    final response = await _dio.post<dynamic>(path, data: data);
    return response.data;
  }

  Future<dynamic> put(String path, {Object? data}) async {
    final response = await _dio.put<dynamic>(path, data: data);
    return response.data;
  }

  Future<dynamic> delete(String path, {Object? data}) async {
    final response = await _dio.delete<dynamic>(path, data: data);
    return response.data;
  }

  Future<dynamic> postMultipart(
    String path, {
    required FormData data,
  }) async {
    final response = await _dio.post<dynamic>(
      path,
      data: data,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) => _postAuth(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) => _postAuth(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

  Future<Map<String, dynamic>> loginWithGoogleToken({
    required String idToken,
    String? accessToken,
  }) => _postAuth(
        ApiConstants.googleMobile,
        data: {
          'id_token': idToken,
          if (accessToken != null) 'access_token': accessToken,
        },
      );

  Future<String> forgotPassword(String email) async {
    final body = await post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
    return body is Map && body['message'] != null
        ? body['message'].toString()
        : 'Reset link sent to your email.';
  }

  Future<Map<String, dynamic>> _postAuth(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    final body = await post(path, data: data);
    if (body is! Map || body['data'] is! Map) {
      throw const FormatException('Unexpected response from the server.');
    }
    final payload = Map<String, dynamic>.from(body['data'] as Map);
    final token = payload['token']?.toString();
    if (token == null || token.isEmpty || payload['user'] is! Map) {
      throw const FormatException('Authentication response is incomplete.');
    }
    await TokenStorage.instance.saveToken(token);
    return payload;
  }

  static String errorMessage(Object error) => ApiError.message(error);

  static dynamic _redact(dynamic value) {
    if (value is List) return value.map(_redact).toList();
    if (value is Map) {
      return value.map((key, item) {
        final normalized = key.toString().toLowerCase();
        if (normalized.contains('password') || normalized.contains('token')) {
          return MapEntry(key, '[REDACTED]');
        }
        return MapEntry(key, _redact(item));
      });
    }
    return value;
  }
}
