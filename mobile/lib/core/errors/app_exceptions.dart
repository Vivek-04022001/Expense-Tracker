enum _AppExceptionType { network, unauthorized, server, unknown }

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final _AppExceptionType _type;

  AppException._({
    required this.message,
    this.statusCode,
    required _AppExceptionType type,
  }) : _type = type;

  factory AppException.network() => AppException._(
        message: 'No internet connection',
        type: _AppExceptionType.network,
      );

  factory AppException.unauthorized() => AppException._(
        message: 'Unauthorized',
        statusCode: 401,
        type: _AppExceptionType.unauthorized,
      );

  factory AppException.server() => AppException._(
        message: 'Server error',
        statusCode: 500,
        type: _AppExceptionType.server,
      );

  factory AppException.unknown() => AppException._(
        message: 'An unexpected error occurred',
        type: _AppExceptionType.unknown,
      );

  bool get isNetwork => _type == _AppExceptionType.network;
  bool get isUnauthorized => _type == _AppExceptionType.unauthorized;
  bool get isServer => _type == _AppExceptionType.server;

  @override
  String toString() => 'AppException: $message (statusCode: $statusCode)';
}
