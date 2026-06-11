import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();

  static final TokenStorage instance = TokenStorage._();
  static const _tokenKey = 'ecotrack_auth_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<bool> get hasToken async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
