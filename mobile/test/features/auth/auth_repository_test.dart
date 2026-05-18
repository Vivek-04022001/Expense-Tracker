import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/core/constants/api_constants.dart';
import 'package:expense_tracker/core/errors/app_exceptions.dart';
import 'package:expense_tracker/core/network/dio_client.dart';
import 'package:expense_tracker/features/auth/data/repositories/auth_repository.dart';

class MockDioClient extends Mock implements DioClient {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

Response<dynamic> _response(
  Map<String, dynamic> data, {
  int statusCode = 200,
}) => Response(
  data: data,
  statusCode: statusCode,
  requestOptions: RequestOptions(path: ''),
);

void main() {
  late MockDioClient mockDioClient;
  late MockFlutterSecureStorage mockStorage;
  late AuthRepository repo;

  setUp(() {
    mockDioClient = MockDioClient();
    mockStorage = MockFlutterSecureStorage();
    repo = AuthRepository(mockDioClient, storage: mockStorage);
  });

  group('login', () {
    test('returns LoginResponse on 200', () async {
      when(
        () => mockDioClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response({'accessToken': 'at', 'refreshToken': 'rt'}),
      );

      final result = await repo.login(phone: '9999999999', password: 'secret');

      expect(result.accessToken, 'at');
      expect(result.refreshToken, 'rt');
      verify(
        () => mockDioClient.post(
          ApiConstants.loginEndpoint,
          data: {'phone': '9999999999', 'password': 'secret'},
        ),
      ).called(1);
    });

    test('propagates AppException on wrong credentials', () async {
      when(
        () => mockDioClient.post(any(), data: any(named: 'data')),
      ).thenThrow(AppException.unauthorized());

      expect(
        () => repo.login(phone: '9999999999', password: 'wrong'),
        throwsA(
          isA<AppException>().having(
            (e) => e.isUnauthorized,
            'isUnauthorized',
            true,
          ),
        ),
      );
    });
  });

  group('register', () {
    test('returns RegisterResponse on 201', () async {
      when(
        () => mockDioClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response({
          'message': 'User registered successfully',
          'userId': 'uid1',
        }, statusCode: 201),
      );

      final result = await repo.register(
        name: 'Alice',
        phone: '9999999999',
        password: 'secret',
      );

      expect(result.userId, 'uid1');
      expect(result.message, 'User registered successfully');
      verify(
        () => mockDioClient.post(
          ApiConstants.registerEndpoint,
          data: {'name': 'Alice', 'phone': '9999999999', 'password': 'secret'},
        ),
      ).called(1);
    });

    test('propagates AppException.conflict when phone is taken', () async {
      when(
        () => mockDioClient.post(any(), data: any(named: 'data')),
      ).thenThrow(AppException.conflict('User already exists'));

      expect(
        () => repo.register(
          name: 'Alice',
          phone: '9999999999',
          password: 'secret',
        ),
        throwsA(
          isA<AppException>().having((e) => e.isConflict, 'isConflict', true),
        ),
      );
    });
  });

  group('logout', () {
    test('posts refreshToken to server and deletes all keys', () async {
      when(
        () => mockStorage.read(key: ApiConstants.refreshTokenKey),
      ).thenAnswer((_) async => 'rt123');
      when(
        () => mockDioClient.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _response({'message': 'ok'}));
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await repo.logout();

      verify(
        () => mockDioClient.post(
          ApiConstants.logoutEndpoint,
          data: {'refreshToken': 'rt123'},
        ),
      ).called(1);
      verify(
        () => mockStorage.delete(key: ApiConstants.accessTokenKey),
      ).called(1);
      verify(
        () => mockStorage.delete(key: ApiConstants.refreshTokenKey),
      ).called(1);
      verify(() => mockStorage.delete(key: 'auth_user')).called(1);
    });

    test('still clears storage even when server call throws', () async {
      when(
        () => mockStorage.read(key: ApiConstants.refreshTokenKey),
      ).thenAnswer((_) async => 'rt123');
      when(
        () => mockDioClient.post(any(), data: any(named: 'data')),
      ).thenThrow(AppException.network());
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await repo.logout();

      verify(
        () => mockStorage.delete(key: ApiConstants.accessTokenKey),
      ).called(1);
      verify(
        () => mockStorage.delete(key: ApiConstants.refreshTokenKey),
      ).called(1);
      verify(() => mockStorage.delete(key: 'auth_user')).called(1);
    });

    test('skips server call when no refresh token stored', () async {
      when(
        () => mockStorage.read(key: ApiConstants.refreshTokenKey),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await repo.logout();

      verifyNever(() => mockDioClient.post(any(), data: any(named: 'data')));
    });
  });

  group('isLoggedIn', () {
    test('returns true when access token present', () async {
      when(
        () => mockStorage.read(key: ApiConstants.accessTokenKey),
      ).thenAnswer((_) async => 'some.token.value');

      expect(await repo.isLoggedIn(), true);
    });

    test('returns false when access token is null', () async {
      when(
        () => mockStorage.read(key: ApiConstants.accessTokenKey),
      ).thenAnswer((_) async => null);

      expect(await repo.isLoggedIn(), false);
    });

    test('returns false when access token is empty', () async {
      when(
        () => mockStorage.read(key: ApiConstants.accessTokenKey),
      ).thenAnswer((_) async => '');

      expect(await repo.isLoggedIn(), false);
    });
  });

  group('decodeJwtPayload', () {
    // Payload: {"userId":"user1","phone":"9999999999"}
    // Encoded: eyJ1c2VySWQiOiJ1c2VyMSIsInBob25lIjoiOTk5OTk5OTk5OSJ9
    const token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        '.eyJ1c2VySWQiOiJ1c2VyMSIsInBob25lIjoiOTk5OTk5OTk5OSJ9'
        '.signature';

    test('extracts userId and phone from payload', () {
      final payload = repo.decodeJwtPayload(token);
      expect(payload['userId'], 'user1');
      expect(payload['phone'], '9999999999');
    });
  });
}
