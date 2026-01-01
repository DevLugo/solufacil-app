import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/repositories/auth_repository.dart';
import '../core/config/app_config.dart';
import '../core/config/powersync_config.dart';

/// Dio instance provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: AppConfig.connectionTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  return dio;
});

/// Secure storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

/// Auth state
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserInfo? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserInfo? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final FlutterSecureStorage _storage;
  final Dio _dio;

  AuthNotifier(this._repository, this._storage, this._dio) : super(const AuthState()) {
    _checkAuthStatus();
  }

  /// Check if user is already logged in
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final isLoggedIn = await _repository.isLoggedIn();
      if (isLoggedIn) {
        final user = await _repository.getStoredUser();
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final response = await _repository.login(email, password);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
      );

      // Reconnect PowerSync with new credentials
      await PowerSyncManager.reconnect(storage: _storage, dio: _dio);

      return true;
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        error: 'Error inesperado. Intenta de nuevo.',
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(secureStorageProvider),
    ref.watch(dioProvider),
  );
});
