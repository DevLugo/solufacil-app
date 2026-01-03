import 'dart:async';
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

/// Extended sync status that includes error information
class ExtendedSyncStatus {
  final SyncStatus status;
  final String? lastError;
  final DateTime? lastErrorTime;

  const ExtendedSyncStatus({
    required this.status,
    this.lastError,
    this.lastErrorTime,
  });

  bool get hasRecentError {
    if (lastErrorTime == null) return false;
    return DateTime.now().difference(lastErrorTime!).inSeconds < 30;
  }

  bool get isAuthError => lastError?.contains('401') == true ||
      lastError?.contains('signature') == true ||
      lastError?.contains('Authorization') == true;
}

/// Sync status provider with error tracking
final syncStatusProvider = StreamProvider<ExtendedSyncStatus>((ref) async* {
  final dbAsyncValue = ref.watch(powerSyncDatabaseProvider);

  final db = dbAsyncValue.valueOrNull;
  if (db == null) {
    yield const ExtendedSyncStatus(status: SyncStatus());
    return;
  }

  String? lastError;
  DateTime? lastErrorTime;

  await for (final status in db.statusStream) {
    // Check for errors in the status
    if (status.anyError != null) {
      lastError = status.anyError.toString();
      lastErrorTime = DateTime.now();
    } else if (status.connected && status.lastSyncedAt != null) {
      // Clear error if we successfully synced
      lastError = null;
      lastErrorTime = null;
    }

    yield ExtendedSyncStatus(
      status: status,
      lastError: lastError,
      lastErrorTime: lastErrorTime,
    );
  }
});

/// Last sync time provider
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  final syncStatus = ref.watch(syncStatusProvider);

  return syncStatus.whenOrNull(
    data: (extStatus) => extStatus.status.lastSyncedAt,
  );
});

/// Is syncing provider
final isSyncingProvider = Provider<bool>((ref) {
  final syncStatus = ref.watch(syncStatusProvider);

  return syncStatus.whenOrNull(
        data: (extStatus) => extStatus.status.downloading || extStatus.status.uploading,
      ) ??
      false;
});

/// Has sync error provider
final hasSyncErrorProvider = Provider<bool>((ref) {
  final syncStatus = ref.watch(syncStatusProvider);

  return syncStatus.whenOrNull(
        data: (extStatus) => extStatus.hasRecentError,
      ) ??
      false;
});

/// Sync error message provider
final syncErrorProvider = Provider<String?>((ref) {
  final syncStatus = ref.watch(syncStatusProvider);

  return syncStatus.whenOrNull(
    data: (extStatus) => extStatus.hasRecentError ? extStatus.lastError : null,
  );
});

/// Trigger manual sync
Future<void> triggerSync(WidgetRef ref) async {
  // PowerSync handles sync automatically, but we can trigger a check
  final db = await ref.read(powerSyncDatabaseProvider.future);
  // The database will check for updates when accessed
  await db.execute('SELECT 1');
}
