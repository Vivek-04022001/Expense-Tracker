import 'dart:io';

class ApiConstants {
  static final String baseUrl =
      Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';

  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String refreshEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
}
