import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/app_config.dart';

/// Authentication response
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserInfo user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// User information
class UserInfo {
  final String id;
  final String email;
  final String role;
  final String? employeeId;
  final String? fullName;

  UserInfo({
    required this.id,
    required this.email,
    required this.role,
    this.employeeId,
    this.fullName,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] as Map<String, dynamic>?;
    final personalData =
        employee?['personalData'] as Map<String, dynamic>?;

    // Priority: employee.personalData.fullName > user.name
    final fullName = personalData?['fullName'] as String? ??
                     json['name'] as String?;

    return UserInfo(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      employeeId: employee?['id'] as String?,
      fullName: fullName,
    );
  }
}

/// Authentication repository
class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';
  static const _userIdKey = 'userId';
  static const _userEmailKey = 'userEmail';
  static const _userRoleKey = 'userRole';
  static const _userNameKey = 'userName';

  AuthRepository({
    required Dio dio,
    required FlutterSecureStorage storage,
  })  : _dio = dio,
        _storage = storage;

  /// Login with email and password
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        AppConfig.graphqlUrl,
        data: {
          'query': '''
            mutation Login(\$email: String!, \$password: String!) {
              login(email: \$email, password: \$password) {
                accessToken
                refreshToken
                user {
                  id
                  name
                  email
                  role
                  employee {
                    id
                    personalData {
                      id
                      fullName
                    }
                  }
                }
              }
            }
          ''',
          'variables': {
            'email': email,
            'password': password,
          },
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['errors'] != null) {
        final errors = data['errors'] as List;
        throw AuthException(
          errors.first['message'] as String? ?? 'Error de autenticación',
        );
      }

      final loginData = data['data']['login'] as Map<String, dynamic>;
      final authResponse = AuthResponse.fromJson(loginData);

      // Save tokens and user info
      await _saveAuthData(authResponse);

      return authResponse;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw AuthException('Error de conexión. Verifica tu internet.');
      }
      throw AuthException('Error de red: ${e.message}');
    }
  }

  /// Save auth data to secure storage
  Future<void> _saveAuthData(AuthResponse response) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: response.accessToken),
      _storage.write(key: _refreshTokenKey, value: response.refreshToken),
      _storage.write(key: _userIdKey, value: response.user.id),
      _storage.write(key: _userEmailKey, value: response.user.email),
      _storage.write(key: _userRoleKey, value: response.user.role),
      if (response.user.fullName != null)
        _storage.write(key: _userNameKey, value: response.user.fullName),
    ]);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  /// Get current refresh token
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  /// Get stored user info
  Future<UserInfo?> getStoredUser() async {
    final id = await _storage.read(key: _userIdKey);
    if (id == null) return null;

    final email = await _storage.read(key: _userEmailKey);
    final role = await _storage.read(key: _userRoleKey);
    final name = await _storage.read(key: _userNameKey);

    return UserInfo(
      id: id,
      email: email ?? '',
      role: role ?? '',
      fullName: name,
    );
  }

  /// Refresh access token
  Future<AuthResponse?> refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await _dio.post(
        AppConfig.graphqlUrl,
        data: {
          'query': '''
            mutation RefreshToken(\$refreshToken: String!) {
              refreshToken(refreshToken: \$refreshToken) {
                accessToken
                refreshToken
                user {
                  id
                  name
                  email
                  role
                  employee {
                    id
                    personalData {
                      id
                      fullName
                    }
                  }
                }
              }
            }
          ''',
          'variables': {
            'refreshToken': refreshToken,
          },
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['errors'] != null) {
        await logout();
        return null;
      }

      final refreshData = data['data']['refreshToken'] as Map<String, dynamic>;
      final authResponse = AuthResponse.fromJson(refreshData);

      await _saveAuthData(authResponse);

      return authResponse;
    } catch (e) {
      await logout();
      return null;
    }
  }

  /// Logout and clear stored data
  Future<void> logout() async {
    await _storage.deleteAll();
  }
}

/// Authentication exception
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}
