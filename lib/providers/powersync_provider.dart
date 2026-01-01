import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import '../core/config/powersync_config.dart';
import 'auth_provider.dart';

/// PowerSync database provider
final powerSyncDatabaseProvider = FutureProvider<PowerSyncDatabase>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final dio = ref.watch(dioProvider);

  return PowerSyncManager.getDatabase(
    storage: storage,
    dio: dio,
  );
});

/// Sync status provider
final syncStatusProvider = StreamProvider<SyncStatus>((ref) async* {
  final dbAsyncValue = ref.watch(powerSyncDatabaseProvider);

  final db = dbAsyncValue.valueOrNull;
  if (db != null) {
    yield* db.statusStream;
  }
});

/// Last sync time provider
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  final syncStatus = ref.watch(syncStatusProvider);

  return syncStatus.whenOrNull(
    data: (status) => status.lastSyncedAt,
  );
});

/// Is syncing provider
final isSyncingProvider = Provider<bool>((ref) {
  final syncStatus = ref.watch(syncStatusProvider);

  return syncStatus.whenOrNull(
        data: (status) => status.downloading || status.uploading,
      ) ??
      false;
});

/// Trigger manual sync
Future<void> triggerSync(WidgetRef ref) async {
  // PowerSync handles sync automatically, but we can trigger a check
  final db = await ref.read(powerSyncDatabaseProvider.future);
  // The database will check for updates when accessed
  await db.execute('SELECT 1');
}
