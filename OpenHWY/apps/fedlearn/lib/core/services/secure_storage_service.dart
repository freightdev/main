import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/zitadel_config.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Token Management
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: ZitadelConfig.accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: ZitadelConfig.accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: ZitadelConfig.refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: ZitadelConfig.refreshTokenKey);
  }

  Future<void> saveIdToken(String token) async {
    await _storage.write(key: ZitadelConfig.idTokenKey, value: token);
  }

  Future<String?> getIdToken() async {
    return await _storage.read(key: ZitadelConfig.idTokenKey);
  }

  // User Info Management
  Future<void> saveUserInfo(String userInfoJson) async {
    await _storage.write(key: ZitadelConfig.userInfoKey, value: userInfoJson);
  }

  Future<String?> getUserInfo() async {
    return await _storage.read(key: ZitadelConfig.userInfoKey);
  }

  // Clear all auth data
  Future<void> clearAllTokens() async {
    await _storage.delete(key: ZitadelConfig.accessTokenKey);
    await _storage.delete(key: ZitadelConfig.refreshTokenKey);
    await _storage.delete(key: ZitadelConfig.idTokenKey);
    await _storage.delete(key: ZitadelConfig.userInfoKey);
  }

  // Check if user is authenticated (has access token)
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all secure storage (use with caution)
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
