import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../errors/app_exceptions.dart';

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  DioClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: ApiConstants.accessTokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken =
            await _storage.read(key: ApiConstants.refreshTokenKey);
        if (refreshToken == null || refreshToken.isEmpty) {
          throw Exception('No refresh token stored');
        }

        // Use a separate Dio instance to avoid re-entering this interceptor.
        final refreshDio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {'Content-Type': 'application/json'},
        ));
        final response = await refreshDio.post(
          ApiConstants.refreshEndpoint,
          data: {'refreshToken': refreshToken},
        );

        final newToken = response.data['accessToken'] as String;
        await _storage.write(key: ApiConstants.accessTokenKey, value: newToken);

        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        handler.resolve(retryResponse);
      } catch (_) {
        await _storage.delete(key: ApiConstants.accessTokenKey);
        await _storage.delete(key: ApiConstants.refreshTokenKey);
        handler.reject(DioException(
          requestOptions: err.requestOptions,
          error: AppException.unauthorized(),
          type: DioExceptionType.badResponse,
        ));
      } finally {
        _isRefreshing = false;
      }
      return;
    }

    handler.reject(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: _mapError(err),
    ));
  }

  AppException _mapError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.receiveTimeout:
        return AppException.network();
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        if (status == 401) return AppException.unauthorized();
        if (status != null && status >= 500) return AppException.server();
        return AppException.unknown();
      default:
        return AppException.unknown();
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw _mapError(e);
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw _mapError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw _mapError(e);
    }
  }

  Future<Response> delete(String path, {dynamic data}) async {
    try {
      return await _dio.delete(path, data: data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw _mapError(e);
    }
  }
}
