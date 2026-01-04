import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/collector_dashboard_provider.dart';
import '../../../providers/collection_provider.dart';
import '../../../providers/powersync_provider.dart';

class SelectLocationPage extends ConsumerWidget {
  const SelectLocationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(currentRouteLeadsProvider);
    final selectedRoute = ref.watch(selectedRouteProvider);
    final dayState = ref.watch(dayStateProvider);
    final isSyncing = ref.watch(isSyncingProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(selectedRoute?.name ?? 'Cobrar Ruta'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isSyncing ? LucideIcons.loader2 : LucideIcons.refreshCw,
            ),
            onPressed: isSyncing
                ? null
                : () => ref.invalidate(currentRouteLeadsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with date
          _DateHeader(dayState: dayState, isSyncing: isSyncing),

          // Location list
          Expanded(
            child: leadsAsync.when(
              data: (leads) {
                if (leads.isEmpty) {
                  return const _EmptyState();
                }
                return _LeadsList(leads: leads);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => _ErrorState(
                onRetry: () => ref.invalidate(currentRouteLeadsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DayState dayState;
  final bool isSyncing;

  const _DateHeader({required this.dayState, required this.isSyncing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayState.fullLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona una localidad',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSyncing
                  ? AppColors.warning.withOpacity(0.1)
                  : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Row(
              children: [
                Icon(
                  isSyncing ? LucideIcons.loader2 : LucideIcons.checkCircle2,
                  size: 14,
                  color: isSyncing ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  isSyncing ? 'Sincronizando...' : 'Sincronizado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSyncing ? AppColors.warning : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadsList extends ConsumerWidget {
  final List<LeadModel> leads;

  const _LeadsList({required this.leads});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leads.length,
      itemBuilder: (context, index) {
        final lead = leads[index];
        return _LocationCard(
          lead: lead,
          onTap: () {
            // Set selected lead and initialize day payment state
            ref.read(selectedLeadProvider.notifier).state = lead;
            ref.read(dayPaymentStateProvider.notifier).initialize(
                  leadId: lead.id,
                  localityId: lead.locationId ?? lead.id,
                  date: DateTime.now(),
                );
            context.push(AppRoutes.clientList);
          },
        );
      },
    );
  }
}

class _LocationCard extends ConsumerWidget {
  final LeadModel lead;
  final VoidCallback onTap;

  const _LocationCard({required this.lead, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get summary for this lead
    final summary = ref.watch(localityDaySummaryProvider(lead.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Icon(LucideIcons.mapPin, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.locationName ?? lead.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${summary.totalLoans} clientes · ${summary.pendingCount} pendientes',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.currency(summary.pendingAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(
                        LucideIcons.chevronRight,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                child: LinearProgressIndicator(
                  value: summary.progressPercent / 100,
                  backgroundColor: AppColors.border.withOpacity(0.5),
                  valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.mapPin, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'No hay localidades',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se encontraron localidades para esta ruta',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error al cargar localidades',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
