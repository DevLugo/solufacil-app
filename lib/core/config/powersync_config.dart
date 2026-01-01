import 'package:powersync/powersync.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../data/schema.dart';
import 'app_config.dart';

/// PowerSync database connector
class PowerSyncConnector extends PowerSyncBackendConnector {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  PowerSyncConnector({
    required FlutterSecureStorage storage,
    required Dio dio,
  })  : _storage = storage,
        _dio = dio;

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    // Get the JWT token from secure storage
    final token = await _storage.read(key: 'accessToken');

    if (token == null) {
      return null;
    }

    try {
      // Fetch PowerSync credentials from our API
      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}/api/powersync/credentials',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Always use AppConfig.powerSyncUrl since API returns localhost
        // which doesn't work on Android emulator
        return PowerSyncCredentials(
          endpoint: AppConfig.powerSyncUrl,
          token: data['token'] ?? token,
        );
      }
    } catch (e) {
      // If credential fetch fails, use direct token
      print('[PowerSync] Credential fetch failed, using direct token: $e');
    }

    // Fallback: Return credentials directly
    return PowerSyncCredentials(
      endpoint: AppConfig.powerSyncUrl,
      token: token,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    // For now, this is a read-only sync
    // We don't upload data from the mobile app
    // All writes happen through the GraphQL API

    // Get the CRUD transaction from the local database
    final transaction = await database.getCrudBatch();

    if (transaction == null || transaction.crud.isEmpty) {
      return;
    }

    // For a write-enabled app, you would:
    // 1. Send the CRUD operations to your backend API
    // 2. The backend would apply them to PostgreSQL
    // 3. PowerSync would then sync them back

    // Since this is read-only, we'll just complete the transaction
    await transaction.complete();
  }
}

/// PowerSync database instance manager
class PowerSyncManager {
  static PowerSyncDatabase? _database;

  /// Get or create the PowerSync database instance
  static Future<PowerSyncDatabase> getDatabase({
    required FlutterSecureStorage storage,
    required Dio dio,
  }) async {
    if (_database != null) {
      return _database!;
    }

    // Get the app documents directory for the database file
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/solufacil.db';

    // Create the database with our schema
    _database = PowerSyncDatabase(
      schema: schema,
      path: path,
    );

    // Create the backend connector
    final connector = PowerSyncConnector(
      storage: storage,
      dio: dio,
    );

    // Start syncing in the background
    // This will continuously sync data from the PowerSync service
    _database!.connect(connector: connector);

    return _database!;
  }

  /// Get the current database instance (throws if not initialized)
  static PowerSyncDatabase get database {
    if (_database == null) {
      throw StateError('PowerSync database not initialized. Call getDatabase() first.');
    }
    return _database!;
  }

  /// Check if database is initialized
  static bool get isInitialized => _database != null;

  /// Close the database connection
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Disconnect and reconnect (useful after login)
  static Future<void> reconnect({
    required FlutterSecureStorage storage,
    required Dio dio,
  }) async {
    if (_database != null) {
      // Disconnect but keep local data (use disconnect() not disconnectAndClear())
      // This preserves the cache so subsequent logins don't re-download everything
      await _database!.disconnect();

      // Create new connector with fresh credentials
      final connector = PowerSyncConnector(
        storage: storage,
        dio: dio,
      );

      // Reconnect - will only sync delta changes
      _database!.connect(connector: connector);
    }
  }
}
