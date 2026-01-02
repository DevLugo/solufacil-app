import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../core/router/app_router.dart';
import '../../providers/collector_dashboard_provider.dart';
import '../../providers/locality_summary_provider.dart';

/// Page for selecting a Locality (Lead) to start working
/// User must select a locality before they can operate (collect payments, create credits, etc.)
///
/// Hierarchy:
/// - Ruta (Route) - highest level, already selected by user
/// - Localidad (Lead with Location) - must be selected here to enable work mode
class JornadaPage extends ConsumerWidget {
  const JornadaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRoute = ref.watch(selectedRouteProvider);
    final leadsAsync = ref.watch(currentRouteLeadsProvider);
    final summaryAsync = ref.watch(allLocalitiesSummaryProvider);
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final today = DateFormat('EEEE d MMMM', 'es').format(DateTime.now());

    // If no route is selected, show message to select route first
    if (selectedRoute == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
          title: const Text(
            'Jornada',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.mapPin, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text(
                  'Selecciona una ruta primero',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ve al dashboard y selecciona tu ruta asignada',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.dashboard),
                  child: const Text('Ir al Dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: const Text(
          'Seleccionar Localidad',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: AppColors.textMuted),
            onPressed: () {
              ref.invalidate(currentRouteLeadsProvider);
              ref.invalidate(allLocalitiesSummaryProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentRouteLeadsProvider);
          ref.invalidate(allLocalitiesSummaryProvider);
        },
        child: _LocalitySelectorView(
          selectedRoute: selectedRoute,
          leadsAsync: leadsAsync,
          summaryAsync: summaryAsync,
          currencyFormat: currencyFormat,
          today: today,
        ),
      ),
    );
  }
}

/// View for selecting a locality (Lead) within the current route
class _LocalitySelectorView extends ConsumerWidget {
  final RouteModel selectedRoute;
  final AsyncValue<List<LeadModel>> leadsAsync;
  final AsyncValue<AllLocalitiesSummary> summaryAsync;
  final NumberFormat currencyFormat;
  final String today;

  const _LocalitySelectorView({
    required this.selectedRoute,
    required this.leadsAsync,
    required this.summaryAsync,
    required this.currencyFormat,
    required this.today,
  });

  void _selectLocality(BuildContext context, WidgetRef ref, LeadModel lead) {
    // Select this locality (Lead)
    ref.read(selectedLeadProvider.notifier).state = lead;
    // Navigate to dashboard - it will now show work mode
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with route name and instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.mapPin, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ruta: ${selectedRoute.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Selecciona una localidad para comenzar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Executive Summary Stats (from all localities)
          summaryAsync.when(
            data: (summary) => _ExecutiveSummaryCards(
              summary: summary.executive,
              currencyFormat: currencyFormat,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // Locality selector header
          Row(
            children: [
              const Icon(LucideIcons.users, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Localidades disponibles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // List of leads (localities)
          leadsAsync.when(
            data: (leads) {
              if (leads.isEmpty) {
                return _EmptyLeadsCard();
              }

              // Get summary data for activity info
              final summaryData = summaryAsync.valueOrNull;
              final localitySummaryMap = summaryData != null
                  ? {for (var loc in summaryData.localities) loc.routeId: loc}
                  : <String, LocalitySummary>{};

              return Column(
                children: leads.map((lead) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SelectableLocalityCard(
                    lead: lead,
                    currencyFormat: currencyFormat,
                    onTap: () => _selectLocality(context, ref, lead),
                  ),
                )).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => Center(
              child: Column(
                children: [
                  Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  const Text('Error al cargar localidades'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

/// Executive summary stats cards
class _ExecutiveSummaryCards extends StatelessWidget {
  final ExecutiveSummary summary;
  final NumberFormat currencyFormat;

  const _ExecutiveSummaryCards({
    required this.summary,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // First row: Payments and Loans
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: LucideIcons.wallet,
                iconColor: AppColors.success,
                label: 'Cobrado hoy',
                value: currencyFormat.format(summary.totalPaymentsReceived),
                subtitle: '${summary.paymentCount} pagos',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: LucideIcons.banknote,
                iconColor: AppColors.error,
                label: 'Colocado hoy',
                value: currencyFormat.format(summary.totalLoansGranted),
                subtitle: '${summary.loansGrantedCount} créditos',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Single stat card
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable locality card (Lead)
class _SelectableLocalityCard extends StatelessWidget {
  final LeadModel lead;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const _SelectableLocalityCard({
    required this.lead,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = lead.locationName != null && lead.locationName!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasLocation ? LucideIcons.mapPin : LucideIcons.user,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasLocation) ...[
                    Text(
                      lead.locationName!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lead.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ] else
                    Text(
                      lead.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.arrowRight,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state when no leads available
class _EmptyLeadsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.userX, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'Sin localidades',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No hay localidades asignadas a esta ruta',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
