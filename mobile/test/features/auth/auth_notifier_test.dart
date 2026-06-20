import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paisa/core/db/app_database.dart';
import 'package:paisa/core/errors/app_exceptions.dart';
import 'package:paisa/features/auth/data/models/auth_model.dart';
import 'package:paisa/features/auth/data/repositories/auth_repository.dart';
import 'package:paisa/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeUserModel extends Fake implements UserModel {}

// Payload: {"userId":"uid1","phone":"9999999999"}
// base64url of the above JSON
const _fakeAccessToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJ1c2VySWQiOiJ1aWQxIiwicGhvbmUiOiI5OTk5OTk5OTk5In0'
    '.signature';
const _fakeRefreshToken = 'fake.refresh.token';

ProviderContainer _makeContainer(MockAuthRepository mockRepo) {
  // logout() wipes the local DB, so back it with an in-memory database.
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo),
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
}

void main() {
  late MockAuthRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(FakeUserModel());
  });

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('AuthNotifier.build', () {
    test('emits AuthAuthenticated when logged in with stored user', () async {
      final user = UserModel(id: 'uid1', name: 'Alice', phone: '9999999999');
      when(() => mockRepo.isLoggedIn()).thenAnswer((_) async => true);
      when(() => mockRepo.getStoredUser()).thenAnswer((_) async => user);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final state = await container.read(authNotifierProvider.future);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).user.name, 'Alice');
    });

    test('emits AuthUnauthenticated when no token stored', () async {
      when(() => mockRepo.isLoggedIn()).thenAnswer((_) async => false);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final state = await container.read(authNotifierProvider.future);
      expect(state, isA<AuthUnauthenticated>());
    });

    test('emits AuthUnauthenticated when token exists but no stored user', () async {
      when(() => mockRepo.isLoggedIn()).thenAnswer((_) async => true);
      when(() => mockRepo.getStoredUser()).thenAnswer((_) async => null);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final state = await container.read(authNotifierProvider.future);
      expect(state, isA<AuthUnauthenticated>());
    });
  });

  group('AuthNotifier.login', () {
    setUp(() {
      when(() => mockRepo.isLoggedIn()).thenAnswer((_) async => false);
    });

    test('emits AuthAuthenticated on successful login', () async {
      when(() => mockRepo.login(phone: any(named: 'phone'), password: any(named: 'password')))
          .thenAnswer((_) async => const LoginResponse(
                accessToken: _fakeAccessToken,
                refreshToken: _fakeRefreshToken,
              ));
      when(() => mockRepo.saveTokens(any(), any())).thenAnswer((_) async {});
      when(() => mockRepo.getStoredUser()).thenAnswer((_) async => null);
      when(() => mockRepo.saveUser(any())).thenAnswer((_) async {});
      when(
        () => mockRepo.decodeJwtPayload(_fakeAccessToken),
      ).thenReturn({'userId': 'uid1', 'phone': '9999999999'});

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier).login('9999999999', 'secret');

      final state = container.read(authNotifierProvider).value;
      expect(state, isA<AuthAuthenticated>());
      final authed = state as AuthAuthenticated;
      expect(authed.user.id, 'uid1');
      expect(authed.user.phone, '9999999999');

      verify(() => mockRepo.saveTokens(_fakeAccessToken, _fakeRefreshToken)).called(1);
      verify(() => mockRepo.saveUser(any())).called(1);
    });

    test('emits AuthUnauthenticated with error on wrong credentials', () async {
      when(() => mockRepo.login(phone: any(named: 'phone'), password: any(named: 'password')))
          .thenThrow(AppException.unauthorized());

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier).login('9999999999', 'wrong');

      final state = container.read(authNotifierProvider).value;
      expect(state, isA<AuthUnauthenticated>());
      expect((state as AuthUnauthenticated).error, 'Invalid phone number or password');
    });

    test('emits AuthUnauthenticated with error on network failure', () async {
      when(() => mockRepo.login(phone: any(named: 'phone'), password: any(named: 'password')))
          .thenThrow(AppException.network());

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier).login('9999999999', 'secret');

      final state = container.read(authNotifierProvider).value;
      expect((state as AuthUnauthenticated).error, 'No internet connection');
    });
  });

  group('AuthNotifier.register', () {
    setUp(() {
      when(() => mockRepo.isLoggedIn()).thenAnswer((_) async => false);
    });

    test('auto-logins after register and emits AuthAuthenticated', () async {
      when(
        () => mockRepo.register(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const RegisterResponse(
            message: 'User registered successfully',
            userId: 'uid1',
          ));
      when(() => mockRepo.login(phone: any(named: 'phone'), password: any(named: 'password')))
          .thenAnswer((_) async => const LoginResponse(
                accessToken: _fakeAccessToken,
                refreshToken: _fakeRefreshToken,
              ));
      when(() => mockRepo.saveTokens(any(), any())).thenAnswer((_) async {});
      when(() => mockRepo.saveUser(any())).thenAnswer((_) async {});
      when(
        () => mockRepo.decodeJwtPayload(_fakeAccessToken),
      ).thenReturn({'userId': 'uid1', 'phone': '9999999999'});

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier)
          .register('Alice', '9999999999', 'secret');

      final state = container.read(authNotifierProvider).value;
      expect(state, isA<AuthAuthenticated>());
      final authed = state as AuthAuthenticated;
      expect(authed.user.id, 'uid1');
      expect(authed.user.name, 'Alice');

      verify(() => mockRepo.register(name: 'Alice', phone: '9999999999', password: 'secret'))
          .called(1);
      verify(() => mockRepo.login(phone: '9999999999', password: 'secret')).called(1);
    });

    test('emits AuthUnauthenticated with conflict message when phone taken', () async {
      when(
        () => mockRepo.register(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
        ),
      ).thenThrow(AppException.conflict('User already exists'));

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier)
          .register('Alice', '9999999999', 'secret');

      final state = container.read(authNotifierProvider).value;
      expect(state, isA<AuthUnauthenticated>());
      expect((state as AuthUnauthenticated).error, 'User already exists');
    });
  });

  group('AuthNotifier.logout', () {
    test('calls repo.logout and emits AuthUnauthenticated', () async {
      final user = UserModel(id: 'uid1', name: 'Alice', phone: '9999999999');
      when(() => mockRepo.isLoggedIn()).thenAnswer((_) async => true);
      when(() => mockRepo.getStoredUser()).thenAnswer((_) async => user);
      when(() => mockRepo.logout()).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier).logout();

      verify(() => mockRepo.logout()).called(1);
      final state = container.read(authNotifierProvider).value;
      expect(state, isA<AuthUnauthenticated>());
    });
  });
}
