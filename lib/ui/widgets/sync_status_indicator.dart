import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart' show SyncStatus;
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/colors.dart';
import '../../providers/powersync_provider.dart' show syncStatusProvider, lastSyncTimeProvider, ExtendedSyncStatus;

/// Sync status display mode
enum SyncStatusDisplayMode {
  /// Just a dot indicator
  dot,
  /// Dot with short label
  compact,
  /// Full card with details
  full,
}

/// A widget that displays the current PowerSync sync status
class SyncStatusIndicator extends ConsumerStatefulWidget {
  final SyncStatusDisplayMode mode;
  final Color? backgroundColor;

  const SyncStatusIndicator({
    super.key,
    this.mode = SyncStatusDisplayMode.compact,
    this.backgroundColor,
  });

  @override
  ConsumerState<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends ConsumerState<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncStatusAsync = ref.watch(syncStatusProvider);
    final lastSync = ref.watch(lastSyncTimeProvider);

    return syncStatusAsync.when(
      data: (extStatus) => _buildIndicator(extStatus, lastSync),
      loading: () => _buildIndicator(
        const ExtendedSyncStatus(status: SyncStatus(connecting: true)),
        null,
      ),
      error: (_, __) => _buildIndicator(
        const ExtendedSyncStatus(status: SyncStatus()),
        null,
        hasProviderError: true,
      ),
    );
  }

  Widget _buildIndicator(ExtendedSyncStatus extStatus, DateTime? lastSync, {bool hasProviderError = false}) {
    final info = _getSyncInfo(extStatus, hasProviderError);

    // Control pulse animation
    if (info.shouldPulse) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }

    switch (widget.mode) {
      case SyncStatusDisplayMode.dot:
        return _buildDot(info);
      case SyncStatusDisplayMode.compact:
        return _buildCompact(info);
      case SyncStatusDisplayMode.full:
        return _buildFull(info, lastSync);
    }
  }

  Widget _buildDot(_SyncInfo info) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: info.color.withOpacity(
              info.shouldPulse ? _pulseAnimation.value : 1.0,
            ),
            shape: BoxShape.circle,
            boxShadow: info.shouldPulse
                ? [
                    BoxShadow(
                      color: info.color.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }

  Widget _buildCompact(_SyncInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? info.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return info.shouldPulse
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(info.color),
                      ),
                    )
                  : Icon(info.icon, size: 14, color: info.color);
            },
          ),
          const SizedBox(width: 6),
          Text(
            info.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: info.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(_SyncInfo info, DateTime? lastSync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Icon container
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: info.color.withOpacity(
                    info.shouldPulse ? 0.1 + (_pulseAnimation.value * 0.1) : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: info.shouldPulse
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(info.color),
                        ),
                      )
                    : Icon(info.icon, color: info.color, size: 20),
              );
            },
          ),
          const SizedBox(width: 16),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Sincronización',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(info),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  info.description ?? _getLastSyncText(lastSync),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(_SyncInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: info.color,
        ),
      ),
    );
  }

  String _getLastSyncText(DateTime? lastSync) {
    if (lastSync == null) return 'Sin sincronizar aún';

    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inSeconds < 30) return 'Sincronizado hace un momento';
    if (diff.inMinutes < 1) return 'Sincronizado hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'Última sync: hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Última sync: hace ${diff.inHours}h';
    return 'Última sync: hace ${diff.inDays} días';
  }

  _SyncInfo _getSyncInfo(ExtendedSyncStatus extStatus, bool hasProviderError) {
    final status = extStatus.status;

    // Provider-level error
    if (hasProviderError) {
      return _SyncInfo(
        label: 'Error',
        color: AppColors.error,
        icon: LucideIcons.alertCircle,
        shouldPulse: false,
        description: 'Error de conexión',
      );
    }

    // Auth/sync error from PowerSync
    if (extStatus.hasRecentError) {
      if (extStatus.isAuthError) {
        return _SyncInfo(
          label: 'Error auth',
          color: AppColors.error,
          icon: LucideIcons.keyRound,
          shouldPulse: true,
          description: 'Error de autenticación con el servidor',
        );
      }
      return _SyncInfo(
        label: 'Error sync',
        color: AppColors.warning,
        icon: LucideIcons.alertTriangle,
        shouldPulse: true,
        description: 'Error al sincronizar, reintentando...',
      );
    }

    // Check if actively syncing (downloading or uploading)
    if (status.downloading) {
      return _SyncInfo(
        label: 'Descargando...',
        color: AppColors.info,
        icon: LucideIcons.download,
        shouldPulse: true,
        description: 'Descargando datos del servidor',
      );
    }

    if (status.uploading) {
      return _SyncInfo(
        label: 'Subiendo...',
        color: AppColors.info,
        icon: LucideIcons.upload,
        shouldPulse: true,
        description: 'Enviando cambios al servidor',
      );
    }

    if (status.connecting) {
      return _SyncInfo(
        label: 'Conectando...',
        color: AppColors.warning,
        icon: LucideIcons.loader,
        shouldPulse: true,
        description: 'Estableciendo conexión',
      );
    }

    if (status.connected && status.lastSyncedAt != null) {
      return _SyncInfo(
        label: 'Sincronizado',
        color: AppColors.success,
        icon: LucideIcons.checkCircle,
        shouldPulse: false,
        description: null, // Will show last sync time
      );
    }

    if (status.connected) {
      return _SyncInfo(
        label: 'Conectado',
        color: AppColors.info,
        icon: LucideIcons.cloud,
        shouldPulse: true,
        description: 'Esperando sincronización inicial...',
      );
    }

    // Offline / disconnected
    return _SyncInfo(
      label: 'Sin conexión',
      color: AppColors.textMuted,
      icon: LucideIcons.cloudOff,
      shouldPulse: false,
      description: 'Modo offline - datos locales',
    );
  }
}

class _SyncInfo {
  final String label;
  final Color color;
  final IconData icon;
  final bool shouldPulse;
  final String? description;

  const _SyncInfo({
    required this.label,
    required this.color,
    required this.icon,
    required this.shouldPulse,
    this.description,
  });
}
