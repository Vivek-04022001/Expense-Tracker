import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
// import '../../../../core/network/dio_client.dart';
import '../models/auth_model.dart';

class AuthRepository {
  // final DioClient _dioClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _userKey = 'auth_user';

  AuthRepository();

  Future<LoginResponse> login({
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // final response = await _dioClient.post(
    //   ApiConstants.loginEndpoint,
    //   data: {'phone': phone, 'password': password},
    // );
    // return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    return const LoginResponse(
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
    );
  }

  Future<RegisterResponse> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // final response = await _dioClient.post(
    //   ApiConstants.registerEndpoint,
    //   data: {'name': name, 'phone': phone, 'password': password},
    // );
    // return RegisterResponse.fromJson(response.data as Map<String, dynamic>);
    return const RegisterResponse(
      message: 'User registered successfully',
      userId: 'mock_user_001',
    );
  }

  Future<void> logout() async {
    // final refreshToken = await _storage.read(key: ApiConstants.refreshTokenKey);
    // try {
    //   await _dioClient.post(
    //     ApiConstants.logoutEndpoint,
    //     data: {'refreshToken': refreshToken},
    //   );
    // } catch (_) {}
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

  // String decodeJwtUserId(String token) {
  //   final payload = token.split('.')[1];
  //   final normalized = base64Url.normalize(payload);
  //   final decoded =
  //       jsonDecode(utf8.decode(base64Url.decode(normalized)))
  //           as Map<String, dynamic>;
  //   return decoded['userId'] as String;
  // }
}
