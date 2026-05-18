import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final DioClient _dioClient;
  final FlutterSecureStorage _storage;

  static const _userKey = 'auth_user';

  AuthRepository(this._dioClient, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<LoginResponse> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.loginEndpoint,
      data: {'phone': phone, 'password': password},
    );
    return LoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RegisterResponse> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.registerEndpoint,
      data: {'name': name, 'phone': phone, 'password': password},
    );
    return RegisterResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: ApiConstants.refreshTokenKey);
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dioClient.post(
          ApiConstants.logoutEndpoint,
          data: {'refreshToken': refreshToken},
        );
      }
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
      key: ApiConstants.refreshTokenKey,
      value: refreshToken,
    );
  }

  Future<void> saveUser(UserModel user) => _storage.write(
    key: _userKey,
    value: jsonEncode({'id': user.id, 'name': user.name, 'phone': user.phone}),
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

  Map<String, dynamic> decodeJwtPayload(String token) {
    final payload = token.split('.')[1];
    final normalized = base64Url.normalize(payload);
    return jsonDecode(utf8.decode(base64Url.decode(normalized)))
        as Map<String, dynamic>;
  }
}
