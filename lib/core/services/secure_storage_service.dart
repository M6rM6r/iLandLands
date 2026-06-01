import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Keys for secure storage
  static const String _apiKey = 'api_key';
  static const String _userToken = 'user_token';
  static const String _refreshToken = 'refresh_token';
  static const String _userId = 'user_id';

  // API Key management
  static Future<void> setApiKey(String apiKey) async {
    await _storage.write(key: _apiKey, value: apiKey);
  }

  static Future<String?> getApiKey() async {
    return _storage.read(key: _apiKey);
  }

  // User authentication tokens
  static Future<void> setUserToken(String token) async {
    await _storage.write(key: _userToken, value: token);
  }

  static Future<String?> getUserToken() async {
    return _storage.read(key: _userToken);
  }

  static Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _refreshToken, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshToken);
  }

  // User ID
  static Future<void> setUserId(String userId) async {
    await _storage.write(key: _userId, value: userId);
  }

  static Future<String?> getUserId() async {
    return _storage.read(key: _userId);
  }

  // Clear all sensitive data
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Clear authentication data
  static Future<void> clearAuthData() async {
    await _storage.delete(key: _userToken);
    await _storage.delete(key: _refreshToken);
    await _storage.delete(key: _userId);
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getUserToken();
    return token != null && token.isNotEmpty;
  }
}