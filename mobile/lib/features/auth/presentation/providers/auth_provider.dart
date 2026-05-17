import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/auth_model.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  final String? error;
  AuthUnauthenticated({this.error});
}

@riverpod
DioClient dioClient(DioClientRef ref) => DioClient();

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) =>
    AuthRepository();

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    final loggedIn = await repo.isLoggedIn();
    if (!loggedIn) return AuthUnauthenticated();
    final user = await repo.getStoredUser();
    if (user == null) return AuthUnauthenticated();
    return AuthAuthenticated(user);
  }

  Future<void> login(String phone, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.login(phone: phone, password: password);
      await repo.saveTokens(response.accessToken, response.refreshToken);

      // final userId = repo.decodeJwtUserId(response.accessToken);
      final stored = await repo.getStoredUser();
      final user = stored ??
          UserModel(id: 'mock_user_001', name: phone, phone: phone);
      await repo.saveUser(user);
      state = AsyncValue.data(AuthAuthenticated(user));
    } on AppException catch (e) {
      state = AsyncValue.data(AuthUnauthenticated(error: _errorMessage(e)));
    } catch (e) {
      state = AsyncValue.data(AuthUnauthenticated(error: e.toString()));
    }
  }

  Future<void> register(String name, String phone, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final registerResponse = await repo.register(
        name: name,
        phone: phone,
        password: password,
      );
      // Mock: skip auto-login since tokens aren't real JWTs.
      // final loginResponse = await repo.login(phone: phone, password: password);
      await repo.saveTokens('mock_access_token', 'mock_refresh_token');
      final user = UserModel(
        id: registerResponse.userId,
        name: name,
        phone: phone,
      );
      await repo.saveUser(user);
      state = AsyncValue.data(AuthAuthenticated(user));
    } on AppException catch (e) {
      state = AsyncValue.data(AuthUnauthenticated(error: _errorMessage(e)));
    } catch (e) {
      state = AsyncValue.data(AuthUnauthenticated(error: e.toString()));
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = AsyncValue.data(AuthUnauthenticated());
  }

  String _errorMessage(AppException e) {
    if (e.isUnauthorized) return 'Invalid phone number or password';
    if (e.isNetwork) return 'No internet connection';
    if (e.isConflict) return e.message; // e.g. "User already exists"
    return e.message;
  }
}
