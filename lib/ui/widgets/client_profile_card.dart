import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/client_history.dart';

class ClientProfileCard extends StatelessWidget {
  final ClientSearchResult client;
  final ClientHistory? history;
  final bool isLoading;
  final VoidCallback onClear;
  final bool showHeader;

  const ClientProfileCard({
    super.key,
    required this.client,
    this.history,
    this.isLoading = false,
    required this.onClear,
    this.showHeader = true,
  });

  /// Get the most recent loan (active first, then any)
  dynamic get _mostRecentLoan {
    if (history == null || history!.loansAsClient.isEmpty) return null;
    // Try most recent active loan first
    final activeLoan = history!.loansAsClient
        .where((l) => l.status.name == 'active')
        .fold<dynamic>(null, (prev, l) =>
            prev == null || l.signDate.isAfter(prev.signDate) ? l : prev);
    if (activeLoan != null) return activeLoan;
    // Otherwise use most recent loan
    return history!.mostRecentLoanAsClient;
  }

  /// Check if we have any location info to display
  bool get _hasLocationInfo =>
      _routeName != null || _leadName != null || _leadLocality != null;

  /// Get route name from loan's snapshotRouteName
  String? get _routeName => _mostRecentLoan?.snapshotRouteName;

  /// Get lead name from the most recent loan
  String? get _leadName => _mostRecentLoan?.leadName;

  /// Get lead locality from the most recent loan
  String? get _leadLocality => _mostRecentLoan?.leadLocality;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          // Header with gradient background (conditional)
          if (showHeader)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.accent.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusXl - 1),
                ),
              ),
              child: Row(
                children: [
                  // Premium Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.glowPrimary,
                    ),
                    child: Center(
                      child: Text(
                        client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name and code
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (client.displayCode != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              client.displayCode!,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Close button
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onClear,
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Route and Lead info (from most recent loan)
          if (_hasLocationInfo)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_routeName != null && _routeName!.isNotEmpty)
                      _LocationChip(
                        icon: LucideIcons.navigation,
                        label: _routeName!,
                        color: AppColors.primary,
                      ),
                    if (_leadLocality != null)
                      _LocationChip(
                        icon: LucideIcons.mapPin,
                        label: _leadLocality!,
                        color: AppColors.success,
                      ),
                    if (_leadName != null)
                      _LocationChip(
                        icon: LucideIcons.user,
                        label: _leadName!,
                        color: AppColors.info,
                      ),
                  ],
                ),
              ),
            ),

          // Contact info
          if (client.phone != null || client.address != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (client.phone != null)
                      _InfoRow(
                        icon: Icons.phone_rounded,
                        text: Formatters.phone(client.phone),
                        color: AppColors.success,
                      ),
                    if (client.phone != null && client.address != null)
                      const SizedBox(height: 12),
                    if (client.address != null)
                      _InfoRow(
                        icon: Icons.location_on_rounded,
                        text: client.address!,
                        color: AppColors.info,
                      ),
                  ],
                ),
              ),
            ),

          // Stats section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: isLoading
                ? _buildLoadingSkeleton(context)
                : history != null
                    ? _buildSummaryStats(context, history!.summary)
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.background,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context, ClientSummary summary) {
    return Column(
      children: [
        // Loan counts - Main stats
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.account_circle_rounded,
                label: 'Como Cliente',
                value: '${summary.totalLoansAsClient}',
                subtitle: summary.activeLoansAsClient > 0
                    ? '${summary.activeLoansAsClient} activo${summary.activeLoansAsClient > 1 ? 's' : ''}'
                    : 'Sin activos',
                color: AppColors.primary,
                isActive: summary.activeLoansAsClient > 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.verified_user_rounded,
                label: 'Como Aval',
                value: '${summary.totalLoansAsCollateral}',
                subtitle: summary.activeLoansAsCollateral > 0
                    ? '${summary.activeLoansAsCollateral} activo${summary.activeLoansAsCollateral > 1 ? 's' : ''}'
                    : 'Sin activos',
                color: AppColors.accent,
                isActive: summary.activeLoansAsCollateral > 0,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Secondary stats
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today_rounded,
                label: 'Cliente desde',
                value: summary.firstLoanDate != null
                    ? Formatters.dateShort(summary.firstLoanDate)
                    : '-',
                color: AppColors.info,
                compact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: summary.avgMissedPaymentsPerLoan == 0
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                label: 'Faltas prom.',
                value: summary.avgMissedPaymentsPerLoan.toStringAsFixed(0),
                color: summary.avgMissedPaymentsPerLoan == 0
                    ? AppColors.success
                    : summary.avgMissedPaymentsPerLoan <= 2
                        ? AppColors.warning
                        : AppColors.error,
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondary,
                ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;
  final bool isActive;
  final bool compact;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
    this.isActive = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: color.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isActive
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _LocationChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: chipColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
