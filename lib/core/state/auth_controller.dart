import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../models/auth_user.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

class AuthController extends ChangeNotifier {
  AuthController() {
    ApiClient.instance.onUnauthorized = handleUnauthorized;
  }

  AuthUser? _user;
  bool _hasToken = false;
  bool _initialized = false;

  AuthUser? get user => _user;
  bool get isAuthenticated => _hasToken;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    final token = await TokenStorage.instance.readToken();
    if (token != null && token.isNotEmpty) {
      _hasToken = true;
      try {
        final body = await ApiClient.instance.get(ApiConstants.me);
        if (body is Map && body['data'] is Map) {
          _user = AuthUser.fromJson(
            Map<String, dynamic>.from(body['data'] as Map),
          );
        } else {
          await TokenStorage.instance.clearToken();
          _hasToken = false;
        }
      } catch (_) {
        // A 401 is cleared by ApiClient. Preserve the token for temporary
        // connection failures so local development can recover on refresh.
        _hasToken = await TokenStorage.instance.hasToken;
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    final payload = await ApiClient.instance.login(
      email: email,
      password: password,
    );
    _setUser(payload['user']);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final payload = await ApiClient.instance.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    _setUser(payload['user']);
  }

  Future<void> refreshProfile() async {
    final body = await ApiClient.instance.get(ApiConstants.me);
    if (body is Map && body['data'] is Map) _setUser(body['data']);
  }

  Future<void> logout() async {
    try {
      await ApiClient.instance.post(ApiConstants.logout);
    } catch (_) {
      // Local logout must still succeed if the backend is unavailable.
    }
    await TokenStorage.instance.clearToken();
    _user = null;
    _hasToken = false;
    notifyListeners();
  }

  void handleUnauthorized() {
    if (!_hasToken && _user == null) return;
    _user = null;
    _hasToken = false;
    notifyListeners();
  }

  void _setUser(Object? rawUser) {
    if (rawUser is! Map) {
      throw const FormatException('User details were not returned.');
    }
    _user = AuthUser.fromJson(Map<String, dynamic>.from(rawUser));
    _hasToken = true;
    notifyListeners();
  }
}
