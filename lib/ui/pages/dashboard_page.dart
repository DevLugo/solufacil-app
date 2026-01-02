import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collector_dashboard_provider.dart';
import '../../providers/powersync_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _currentIndex = 0;
  final _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(collectorDashboardStatsProvider);
    final weekState = ref.watch(weekStateProvider);
    final routesAsync = ref.watch(routesProvider);
    final selectedRoute = ref.watch(selectedRouteProvider);
    final isSyncing = ref.watch(isSyncingProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await triggerSync(ref);
            ref.invalidate(collectorDashboardStatsProvider);
          },
          color: AppColors.primary,
          child: statsAsync.when(
            data: (stats) => _buildContent(stats, weekState, routesAsync, selectedRoute, isSyncing),
            loading: () => _buildContent(CollectorDashboardStats.empty(), weekState, routesAsync, selectedRoute, true),
            error: (_, __) => _buildContent(CollectorDashboardStats.empty(), weekState, routesAsync, selectedRoute, false),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.createCredit),
        elevation: 8,
        child: const Icon(LucideIcons.plus, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _handleNavigation(index);
        },
      ),
    );
  }

  Widget _buildContent(
    CollectorDashboardStats stats,
    WeekState weekState,
    AsyncValue<List<RouteModel>> routesAsync,
    RouteModel? selectedRoute,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with route selector
          _HeaderSection(
            userName: stats.userName,
            isOnline: stats.isOnline,
            routes: routesAsync.valueOrNull ?? [],
            selectedRoute: selectedRoute,
            onRouteSelected: (route) {
              ref.read(selectedRouteProvider.notifier).state = route;
            },
            onLogout: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 16),

          // Week Navigator
          _WeekNavigator(
            weekState: weekState,
            onPrevious: () => ref.read(weekStateProvider.notifier).goToPreviousWeek(),
            onNext: weekState.isCurrentWeek
                ? null
                : () => ref.read(weekStateProvider.notifier).goToNextWeek(),
            onToday: weekState.isCurrentWeek
                ? null
                : () => ref.read(weekStateProvider.notifier).goToCurrentWeek(),
          ),
          const SizedBox(height: 16),

          // CRITICAL ALERT - Show if there are week 4+ clients
          if (stats.clientsWeek4CV + stats.clientsWeek5PlusCV > 0) ...[
            _CriticalAlertCard(
              week4Count: stats.clientsWeek4CV,
              week5PlusCount: stats.clientsWeek5PlusCV,
              onTap: () => context.push(AppRoutes.criticalClients),
            ),
            const SizedBox(height: 16),
          ],

          // Main Collection Progress
          _CollectionProgressCard(
            collected: stats.collectedPaymentsThisWeek,
            expected: stats.expectedPaymentsThisWeek,
            missing: stats.missingPaymentsThisWeek,
            progress: stats.goalProgress,
            isLoading: isLoading,
          ),
          const SizedBox(height: 16),

          // CV Breakdown Card
          _CVBreakdownCard(
            alCorriente: stats.clientsAlCorriente,
            week1: stats.clientsWeek1CV,
            week2: stats.clientsWeek2CV,
            week3: stats.clientsWeek3CV,
            week4: stats.clientsWeek4CV,
            week5Plus: stats.clientsWeek5PlusCV,
            total: stats.activeLoansCount,
            onCriticalTap: (stats.clientsWeek4CV + stats.clientsWeek5PlusCV) > 0
                ? () => context.push(AppRoutes.criticalClients)
                : null,
          ),
          const SizedBox(height: 16),

          // Amount KPIs
          Row(
            children: [
              Expanded(
                child: _AmountCard(
                  title: 'Cobrado',
                  amount: _currencyFormat.format(stats.collectedAmountThisWeek),
                  icon: LucideIcons.checkCircle2,
                  color: AppColors.success,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AmountCard(
                  title: 'Esperado',
                  amount: _currencyFormat.format(stats.expectedAmountThisWeek),
                  icon: LucideIcons.target,
                  color: AppColors.info,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Portfolio Movement Card (Credits Delta)
          _PortfolioMovementCard(
            newLoans: stats.newLoansThisWeek,
            renewed: stats.renewedLoansThisWeek,
            finished: stats.finishedLoansThisWeek,
            balance: stats.portfolioBalance,
            newLoansAmount: _currencyFormat.format(stats.newLoansAmountThisWeek),
          ),
          const SizedBox(height: 16),

          // Comparison with last week
          _ComparisonCard(
            collectedThisWeek: stats.collectedPaymentsThisWeek,
            collectedLastWeek: stats.collectedPaymentsLastWeek,
            amountThisWeek: stats.collectedAmountThisWeek,
            amountLastWeek: stats.collectedAmountLastWeek,
            difference: stats.comparisonVsLastWeek,
            amountDifference: stats.comparisonAmountVsLastWeek,
            isAhead: stats.isAheadOfLastWeek,
            currencyFormat: _currencyFormat,
            isLoading: isLoading,
          ),
          const SizedBox(height: 16),

          // Portfolio Summary
          _PortfolioCard(
            activeLoans: stats.activeLoansCount,
            pendingDebt: _currencyFormat.format(stats.totalPendingDebt),
            isLoading: isLoading,
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Acciones Rapidas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          _QuickActionsGrid(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        context.push(AppRoutes.selectLocation);
        break;
      case 2:
        break;
      case 3:
        context.push(AppRoutes.clients);
        break;
      case 4:
        context.push(AppRoutes.reports);
        break;
    }
  }
}

/// Critical Alert Card - Shows when there are clients in week 4+
class _CriticalAlertCard extends StatelessWidget {
  final int week4Count;
  final int week5PlusCount;
  final VoidCallback onTap;

  const _CriticalAlertCard({
    required this.week4Count,
    required this.week5PlusCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalCritical = week4Count + week5PlusCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              week5PlusCount > 0 ? const Color(0xFF7C2D12) : AppColors.error,
              AppColors.error,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CLIENTES CRITICOS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalCritical clientes criticos',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (week4Count > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Sem 4: $week4Count',
                            style: const TextStyle(fontSize: 11, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (week5PlusCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Sem 5+: $week5PlusCount',
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.chevronRight,
                size: 24,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CV Breakdown Card - Shows clients by payment status
class _CVBreakdownCard extends StatelessWidget {
  final int alCorriente;
  final int week1;
  final int week2;
  final int week3;
  final int week4;
  final int week5Plus;
  final int total;
  final VoidCallback? onCriticalTap;

  const _CVBreakdownCard({
    required this.alCorriente,
    required this.week1,
    required this.week2,
    required this.week3,
    required this.week4,
    required this.week5Plus,
    required this.total,
    this.onCriticalTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCritical = week4 + week5Plus > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.pieChart, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Estado de Cartera',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
              const Spacer(),
              Text(
                '$total activos',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar showing breakdown
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (alCorriente > 0)
                    Expanded(
                      flex: alCorriente,
                      child: Container(color: AppColors.success),
                    ),
                  if (week1 > 0)
                    Expanded(
                      flex: week1,
                      child: Container(color: const Color(0xFFFBBF24)), // Yellow
                    ),
                  if (week2 > 0)
                    Expanded(
                      flex: week2,
                      child: Container(color: const Color(0xFFF59E0B)), // Amber
                    ),
                  if (week3 > 0)
                    Expanded(
                      flex: week3,
                      child: Container(color: const Color(0xFFEA580C)), // Orange
                    ),
                  if (week4 > 0)
                    Expanded(
                      flex: week4,
                      child: Container(color: AppColors.error), // Red
                    ),
                  if (week5Plus > 0)
                    Expanded(
                      flex: week5Plus,
                      child: Container(color: const Color(0xFF7C2D12)), // Dark red
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend with counts
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CVLegendItem(
                color: AppColors.success,
                label: 'Al corriente',
                count: alCorriente,
              ),
              _CVLegendItem(
                color: const Color(0xFFFBBF24),
                label: 'Sem 1',
                count: week1,
              ),
              _CVLegendItem(
                color: const Color(0xFFF59E0B),
                label: 'Sem 2',
                count: week2,
              ),
              _CVLegendItem(
                color: const Color(0xFFEA580C),
                label: 'Sem 3',
                count: week3,
              ),
              // Week 4 - Critical
              GestureDetector(
                onTap: onCriticalTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: week4 > 0 ? AppColors.error.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(6),
                    border: week4 > 0 ? Border.all(color: AppColors.error.withOpacity(0.3)) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sem 4',
                        style: TextStyle(
                          fontSize: 11,
                          color: week4 > 0 ? AppColors.error : AppColors.textMuted,
                          fontWeight: week4 > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$week4',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: week4 > 0 ? AppColors.error : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Week 5+ - Very Critical
              GestureDetector(
                onTap: onCriticalTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: week5Plus > 0 ? const Color(0xFF7C2D12).withOpacity(0.15) : null,
                    borderRadius: BorderRadius.circular(6),
                    border: week5Plus > 0 ? Border.all(color: const Color(0xFF7C2D12).withOpacity(0.4)) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C2D12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sem 5+',
                        style: TextStyle(
                          fontSize: 11,
                          color: week5Plus > 0 ? const Color(0xFF7C2D12) : AppColors.textMuted,
                          fontWeight: week5Plus > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$week5Plus',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: week5Plus > 0 ? const Color(0xFF7C2D12) : AppColors.textMuted,
                        ),
                      ),
                      if (hasCritical) ...[
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 12,
                          color: week5Plus > 0 ? const Color(0xFF7C2D12) : AppColors.error,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CVLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _CVLegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

/// Portfolio Movement Card - Shows credits delta
class _PortfolioMovementCard extends StatelessWidget {
  final int newLoans;
  final int renewed;
  final int finished;
  final int balance;
  final String newLoansAmount;

  const _PortfolioMovementCard({
    required this.newLoans,
    required this.renewed,
    required this.finished,
    required this.balance,
    required this.newLoansAmount,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.activity, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Movimiento de Cartera',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
              const Spacer(),
              // Balance badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.error).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                      size: 14,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${balance >= 0 ? '+' : ''}$balance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Nuevos
              Expanded(
                child: _MovementItem(
                  icon: LucideIcons.userPlus,
                  label: 'Nuevos',
                  value: '$newLoans',
                  subValue: newLoansAmount,
                  color: AppColors.success,
                ),
              ),
              Container(width: 1, height: 50, color: AppColors.border),
              // Renovados
              Expanded(
                child: _MovementItem(
                  icon: LucideIcons.refreshCw,
                  label: 'Renovados',
                  value: '$renewed',
                  color: AppColors.info,
                ),
              ),
              Container(width: 1, height: 50, color: AppColors.border),
              // Finalizados
              Expanded(
                child: _MovementItem(
                  icon: LucideIcons.userMinus,
                  label: 'Finalizados',
                  value: '$finished',
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MovementItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final Color color;

  const _MovementItem({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
          if (subValue != null)
            Text(
              subValue!,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact header with greeting, route selector pill, and sync status
class _HeaderSection extends StatelessWidget {
  final String userName;
  final bool isOnline;
  final List<RouteModel> routes;
  final RouteModel? selectedRoute;
  final Function(RouteModel?) onRouteSelected;
  final VoidCallback onLogout;

  const _HeaderSection({
    required this.userName,
    required this.isOnline,
    required this.routes,
    required this.selectedRoute,
    required this.onRouteSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Greeting with logout menu
        Expanded(
          child: GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hola, $userName',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _getWeekLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Route selector pill
        _RouteChip(
          routes: routes,
          selectedRoute: selectedRoute,
          onRouteSelected: onRouteSelected,
        ),
        const SizedBox(width: 8),
        // Sync indicator
        _SyncIndicator(isOnline: isOnline),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesion'),
        content: const Text(
          'Deseas cerrar sesion? Esto limpiara los datos locales y forzara una nueva sincronizacion al volver a iniciar sesion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onLogout();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Cerrar Sesion'),
          ),
        ],
      ),
    );
  }

  String _getWeekLabel() {
    final now = DateTime.now();
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

/// Compact route selector chip
class _RouteChip extends StatelessWidget {
  final List<RouteModel> routes;
  final RouteModel? selectedRoute;
  final Function(RouteModel?) onRouteSelected;

  const _RouteChip({
    required this.routes,
    required this.selectedRoute,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RouteModel?>(
      onSelected: onRouteSelected,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem<RouteModel?>(
          value: null,
          child: Row(
            children: [
              Icon(
                LucideIcons.globe,
                size: 16,
                color: selectedRoute == null ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Todas',
                style: TextStyle(
                  fontWeight: selectedRoute == null ? FontWeight.bold : FontWeight.normal,
                  color: selectedRoute == null ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ...routes.map((route) => PopupMenuItem<RouteModel?>(
              value: route,
              child: Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 16,
                    color: selectedRoute?.id == route.id ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    route.name,
                    style: TextStyle(
                      fontWeight: selectedRoute?.id == route.id ? FontWeight.bold : FontWeight.normal,
                      color: selectedRoute?.id == route.id ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            )),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.mapPin,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              selectedRoute?.name ?? 'Todas',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              LucideIcons.chevronDown,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncIndicator extends StatelessWidget {
  final bool isOnline;

  const _SyncIndicator({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isOnline ? AppColors.success : AppColors.warning).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Sync' : 'Sync...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Week navigator with arrows
class _WeekNavigator extends StatelessWidget {
  final WeekState weekState;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToday;

  const _WeekNavigator({
    required this.weekState,
    required this.onPrevious,
    this.onNext,
    this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowCard,
      ),
      child: Row(
        children: [
          // Previous week button
          _NavButton(
            icon: LucideIcons.chevronLeft,
            onTap: onPrevious,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  weekState.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  weekState.rangeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Next week / Today button
          if (!weekState.isCurrentWeek) ...[
            _NavButton(
              icon: LucideIcons.chevronRight,
              onTap: onNext,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onToday,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hoy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ] else
            _NavButton(
              icon: LucideIcons.chevronRight,
              onTap: null,
              disabled: true,
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  const _NavButton({
    required this.icon,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.border.withOpacity(0.3)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: disabled ? AppColors.textMuted : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Main collection progress card
class _CollectionProgressCard extends StatelessWidget {
  final int collected;
  final int expected;
  final int missing;
  final double progress;
  final bool isLoading;

  const _CollectionProgressCard({
    required this.collected,
    required this.expected,
    required this.missing,
    required this.progress,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowCard,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.users, size: 24, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cobros de la Semana',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${progress.toStringAsFixed(0)}% completado',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: AppColors.border.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(
                progress >= 100
                    ? AppColors.success
                    : progress >= 50
                        ? AppColors.primary
                        : AppColors.warning,
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _StatPill(
                value: '$collected',
                label: 'Cobrados',
                color: AppColors.success,
              ),
              const SizedBox(width: 12),
              _StatPill(
                value: '$missing',
                label: 'Faltan',
                color: missing > 0 ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: 12),
              _StatPill(
                value: '$expected',
                label: 'Esperados',
                color: AppColors.info,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Amount card
class _AmountCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const _AmountCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Comparison card with last week
class _ComparisonCard extends StatelessWidget {
  final int collectedThisWeek;
  final int collectedLastWeek;
  final double amountThisWeek;
  final double amountLastWeek;
  final int difference;
  final double amountDifference;
  final bool isAhead;
  final NumberFormat currencyFormat;
  final bool isLoading;

  const _ComparisonCard({
    required this.collectedThisWeek,
    required this.collectedLastWeek,
    required this.amountThisWeek,
    required this.amountLastWeek,
    required this.difference,
    required this.amountDifference,
    required this.isAhead,
    required this.currencyFormat,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAhead ? AppColors.success : AppColors.error;
    final icon = isAhead ? LucideIcons.trendingUp : LucideIcons.trendingDown;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.barChart3, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'vs Semana Pasada',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '${difference >= 0 ? '+' : ''}$difference pagos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Esta semana',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$collectedThisWeek cobros',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(
                      currencyFormat.format(amountThisWeek),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.border,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semana pasada',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$collectedLastWeek cobros',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        currencyFormat.format(amountLastWeek),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Portfolio summary card
class _PortfolioCard extends StatelessWidget {
  final int activeLoans;
  final String pendingDebt;
  final bool isLoading;

  const _PortfolioCard({
    required this.activeLoans,
    required this.pendingDebt,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.briefcase, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Cartera Activa',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PortfolioStat(
                  value: '$activeLoans',
                  label: 'Creditos activos',
                  icon: LucideIcons.users,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PortfolioStat(
                  value: pendingDebt,
                  label: 'Deuda pendiente',
                  icon: LucideIcons.dollarSign,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _PortfolioStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

/// Quick actions grid
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: [
        _QuickActionButton(
          icon: LucideIcons.plus,
          label: 'Nuevo Credito',
          iconBgColor: AppColors.primary.withOpacity(0.1),
          iconColor: AppColors.primary,
          onTap: () => context.push(AppRoutes.createCredit),
        ),
        _QuickActionButton(
          icon: LucideIcons.dollarSign,
          label: 'Cobrar Ruta',
          iconBgColor: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF16A34A),
          onTap: () => context.push(AppRoutes.selectLocation),
        ),
        _QuickActionButton(
          icon: LucideIcons.fileText,
          label: 'Reportes',
          iconBgColor: const Color(0xFFDBEAFE),
          iconColor: const Color(0xFF2563EB),
          onTap: () => context.push(AppRoutes.reports),
        ),
        _QuickActionButton(
          icon: LucideIcons.users,
          label: 'Clientes',
          iconBgColor: const Color(0xFFF3E8FF),
          iconColor: const Color(0xFF9333EA),
          onTap: () => context.push(AppRoutes.clients),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: AppTheme.shadowCard,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom navigation bar
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: AppColors.background,
      elevation: 8,
      height: 60,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: LucideIcons.home,
              label: 'Inicio',
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: LucideIcons.dollarSign,
              label: 'Cobrar',
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            const SizedBox(width: 48),
            _NavItem(
              icon: LucideIcons.users,
              label: 'Clientes',
              isSelected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavItem(
              icon: LucideIcons.barChart3,
              label: 'Reportes',
              isSelected: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
