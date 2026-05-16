import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final DioClient _dioClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _userKey = 'auth_user';

  AuthRepository(this._dioClient);

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.loginEndpoint,
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.registerEndpoint,
      data: {'name': name, 'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final refreshToken =
        await _storage.read(key: ApiConstants.refreshTokenKey);
    try {
      await _dioClient.post(
        ApiConstants.logoutEndpoint,
        data: {'refreshToken': refreshToken},
      );
    } catch (_) {}
    await _storage.delete(key: ApiConstants.accessTokenKey);
    await _storage.delete(key: ApiConstants.refreshTokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: ApiConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: ApiConstants.accessTokenKey, value: accessToken);
    await _storage.write(
        key: ApiConstants.refreshTokenKey, value: refreshToken);
  }

  Future<void> saveUser(UserModel user) => _storage.write(
        key: _userKey,
        value: jsonEncode(
            {'id': user.id, 'name': user.name, 'email': user.email}),
      );

  Future<UserModel?> getStoredUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
