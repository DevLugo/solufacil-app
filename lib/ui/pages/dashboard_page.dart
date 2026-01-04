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
import '../widgets/sync_status_indicator.dart';

// =============================================================================
// DASHBOARD THEME
// =============================================================================

/// Dashboard theme mode provider
final dashboardThemeModeProvider = StateProvider<bool>((ref) => false); // false = light (orange), true = dark (slate)

/// Dashboard color scheme for theming
class DashboardColors {
  final Color heroBackground;
  final Color heroTextPrimary;
  final Color heroTextSecondary;
  final Color heroAccent;
  final Color heroProgressBar;
  final Color heroProgressFill;
  final Color weekNavBackground;
  final Color weekNavText;
  final Color weekNavButton;
  final Color avatarBackground;
  final Color routeSelectorBackground;
  final Color statusDotOnline;
  final Color scaffoldBackground;
  final Color criticalBannerBackground;
  final Color criticalBannerText;
  final Color criticalAccent;
  final Color statSuccess; // For "Cobrado"
  final Color statWarning; // For "Faltan"

  const DashboardColors({
    required this.heroBackground,
    required this.heroTextPrimary,
    required this.heroTextSecondary,
    required this.heroAccent,
    required this.heroProgressBar,
    required this.heroProgressFill,
    required this.weekNavBackground,
    required this.weekNavText,
    required this.weekNavButton,
    required this.avatarBackground,
    required this.routeSelectorBackground,
    required this.statusDotOnline,
    required this.scaffoldBackground,
    required this.criticalBannerBackground,
    required this.criticalBannerText,
    required this.criticalAccent,
    required this.statSuccess,
    required this.statWarning,
  });

  /// Light theme - SoluFácil Orange (Day mode)
  static const light = DashboardColors(
    heroBackground: Color(0xFFF15A29), // SoluFácil orange
    heroTextPrimary: Colors.white,
    heroTextSecondary: Color(0xFFFFE4D6), // Light peach
    heroAccent: Colors.white,
    heroProgressBar: Color(0x33FFFFFF),
    heroProgressFill: Colors.white,
    weekNavBackground: Color(0x22FFFFFF),
    weekNavText: Colors.white,
    weekNavButton: Color(0xFFFFFFFF),
    avatarBackground: Color(0x22FFFFFF),
    routeSelectorBackground: Color(0x33FFFFFF),
    statusDotOnline: Color(0xFF22C55E),
    scaffoldBackground: Color(0xFFFFF7F5), // Warm white
    criticalBannerBackground: Colors.white,
    criticalBannerText: Color(0xFF1F2937), // Gray 800 - dark text
    criticalAccent: Color(0xFFEA580C), // Orange 600
    statSuccess: Colors.white, // White on orange looks clean
    statWarning: Color(0xFFFEF3C7), // Light amber
  );

  /// Dark theme - Slate (Night mode)
  static const dark = DashboardColors(
    heroBackground: Color(0xFF1E293B), // Slate 800
    heroTextPrimary: Colors.white,
    heroTextSecondary: Color(0xFF94A3B8), // Slate 400
    heroAccent: Colors.white,
    heroProgressBar: Color(0x26FFFFFF),
    heroProgressFill: Colors.white,
    weekNavBackground: Color(0x1AFFFFFF),
    weekNavText: Colors.white,
    weekNavButton: Color(0xFFFFFFFF),
    avatarBackground: Color(0x1AFFFFFF),
    routeSelectorBackground: Color(0x26FFFFFF),
    statusDotOnline: Color(0xFF22C55E),
    scaffoldBackground: Color(0xFFF8FAFC), // Slate 50
    criticalBannerBackground: Color(0xFF334155), // Slate 700 - same family as hero
    criticalBannerText: Colors.white,
    criticalAccent: Color(0xFFF59E0B), // Amber 500
    statSuccess: Color(0xFF22C55E), // Green
    statWarning: Color(0xFFFACC15), // Yellow
  );
}

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
    final dayState = ref.watch(dayStateProvider);
    final routesAsync = ref.watch(routesProvider);
    final selectedRoute = ref.watch(selectedRouteProvider);
    final selectedLead = ref.watch(selectedLeadProvider);  // Localidad
    final isSyncing = ref.watch(isSyncingProvider);
    final isDarkMode = ref.watch(dashboardThemeModeProvider);
    final colors = isDarkMode ? DashboardColors.dark : DashboardColors.light;

    // Work mode requires a LOCALITY (Lead) to be selected, not just a route
    final isWorkMode = selectedLead != null;

    return Scaffold(
      backgroundColor: colors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Work Mode Header Banner - shows when locality is selected
            if (isWorkMode)
              _WorkModeHeader(
                leadName: selectedLead.name,
                locationName: selectedLead.locationName,
                onExit: () {
                  ref.read(selectedLeadProvider.notifier).state = null;
                  ref.read(dayStateProvider.notifier).goToToday();
                  setState(() => _currentIndex = 0);
                },
                onChangeLead: () => context.push(AppRoutes.jornada),
              ),
            // Sync status banner - shows prominently when syncing or error
            _SyncStatusBanner(),
            // Main content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await triggerSync(ref);
                  ref.invalidate(collectorDashboardStatsProvider);
                },
                color: AppColors.primary,
                child: statsAsync.when(
                  data: (stats) => isWorkMode
                      ? _buildWorkModeContent(stats, dayState, false, colors, isDarkMode)
                      : _buildRouteModeContent(stats, weekState, routesAsync, selectedRoute, false, colors, isDarkMode),
                  loading: () => isWorkMode
                      ? _buildWorkModeContent(CollectorDashboardStats.empty(), dayState, true, colors, isDarkMode)
                      : _buildRouteModeContent(CollectorDashboardStats.empty(), weekState, routesAsync, selectedRoute, true, colors, isDarkMode),
                  error: (_, __) => isWorkMode
                      ? _buildWorkModeContent(CollectorDashboardStats.empty(), dayState, false, colors, isDarkMode)
                      : _buildRouteModeContent(CollectorDashboardStats.empty(), weekState, routesAsync, selectedRoute, false, colors, isDarkMode),
                ),
              ),
            ),
          ],
        ),
      ),
      // Only show FAB when locality is selected (for new credit)
      floatingActionButton: isWorkMode
          ? FloatingActionButton(
              onPressed: () => context.push(AppRoutes.createCredit),
              backgroundColor: AppColors.primary,
              elevation: 2,
              child: const Icon(LucideIcons.plus, size: 24, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: isWorkMode
          ? _WorkModeNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
                _handleWorkNavigation(index);
              },
            )
          : _GeneralNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
                _handleGeneralNavigation(index);
              },
            ),
    );
  }

  // Navigation when locality is selected (work mode)
  void _handleWorkNavigation(int index) {
    switch (index) {
      case 0: // Cobranza - go directly to client list (locality already selected)
        context.push(AppRoutes.clientList);
        break;
      case 1: // Créditos
        context.push(AppRoutes.creditsToday);
        break;
      case 2: // FAB (handled separately)
        break;
      case 3: // Gastos
        // TODO: Gastos page
        break;
      case 4: // Resumen
        context.push(AppRoutes.jornada);
        break;
    }
  }

  // Navigation when no locality selected (general mode)
  void _handleGeneralNavigation(int index) {
    switch (index) {
      case 0: // Inicio
        break;
      case 1: // Jornada (all localities summary)
        context.push(AppRoutes.jornada);
        break;
      case 2: // Clientes
        context.push(AppRoutes.clients);
        break;
    }
  }

  // ===========================================================================
  // ROUTE MODE CONTENT (Weekly dashboard - no locality selected)
  // ===========================================================================
  Widget _buildRouteModeContent(
    CollectorDashboardStats stats,
    WeekState weekState,
    AsyncValue<List<RouteModel>> routesAsync,
    RouteModel? selectedRoute,
    bool isLoading,
    DashboardColors colors,
    bool isDarkMode,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section with themed background
          Container(
            color: colors.heroBackground,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _Header(
                    userName: stats.userName,
                    isOnline: stats.isOnline,
                    routes: routesAsync.valueOrNull ?? [],
                    selectedRoute: selectedRoute,
                    onRouteSelected: (route) {
                      ref.read(selectedRouteProvider.notifier).state = route;
                    },
                    onLogout: () => ref.read(authProvider.notifier).logout(),
                    onThemeToggle: () {
                      ref.read(dashboardThemeModeProvider.notifier).state = !isDarkMode;
                    },
                    isDarkMode: isDarkMode,
                    colors: colors,
                  ),
                ),
                const SizedBox(height: 20),
                // Week navigator (ROUTE MODE = WEEKLY)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _WeekNav(
                    weekState: weekState,
                    onPrevious: () => ref.read(weekStateProvider.notifier).goToPreviousWeek(),
                    onNext: weekState.isCurrentWeek ? null : () => ref.read(weekStateProvider.notifier).goToNextWeek(),
                    onToday: weekState.isCurrentWeek ? null : () => ref.read(weekStateProvider.notifier).goToCurrentWeek(),
                    colors: colors,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(height: 24),
                // Hero collection progress
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _HeroProgress(
                    collected: stats.collectedPaymentsThisWeek,
                    expected: stats.expectedPaymentsThisWeek,
                    progress: stats.goalProgress,
                    collectedAmount: _currencyFormat.format(stats.collectedAmountThisWeek),
                    expectedAmount: _currencyFormat.format(stats.expectedAmountThisWeek),
                    isLoading: isLoading,
                    colors: colors,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Content section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Critical alert
                if (stats.clientsWeek4CV + stats.clientsWeek5PlusCV > 0) ...[
                  _CriticalBanner(
                    week4Count: stats.clientsWeek4CV,
                    week5PlusCount: stats.clientsWeek5PlusCV,
                    onTap: () => context.push(AppRoutes.criticalClients),
                    colors: colors,
                  ),
                  const SizedBox(height: 20),
                ],
                // Portfolio health
                _PortfolioHealth(
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
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),
                // Key metrics row
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Cartera',
                        value: '${stats.activeLoansCount}',
                        subtitle: 'creditos activos',
                        icon: LucideIcons.briefcase,
                        isLoading: isLoading,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Por cobrar',
                        value: _currencyFormat.format(stats.totalPendingDebt),
                        subtitle: 'deuda total',
                        icon: LucideIcons.wallet,
                        isLoading: isLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Portfolio movement
                _MovementCard(
                  newLoans: stats.newLoansThisWeek,
                  renewed: stats.renewedLoansThisWeek,
                  finished: stats.finishedLoansThisWeek,
                  balance: stats.portfolioBalance,
                  newLoansAmount: _currencyFormat.format(stats.newLoansAmountThisWeek),
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),
                // Week comparison
                _ComparisonRow(
                  collectedThisWeek: stats.collectedPaymentsThisWeek,
                  collectedLastWeek: stats.collectedPaymentsLastWeek,
                  difference: stats.comparisonVsLastWeek,
                  isAhead: stats.isAheadOfLastWeek,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WORK MODE CONTENT (Daily dashboard - locality selected)
  // ===========================================================================
  Widget _buildWorkModeContent(
    CollectorDashboardStats stats,
    DayState dayState,
    bool isLoading,
    DashboardColors colors,
    bool isDarkMode,
  ) {
    // Work mode uses a green/teal accent to differentiate from route mode
    final workModeColors = DashboardColors(
      heroBackground: const Color(0xFF0F766E), // Teal 700
      heroTextPrimary: Colors.white,
      heroTextSecondary: const Color(0xFF99F6E4), // Teal 200
      heroAccent: Colors.white,
      heroProgressBar: const Color(0x33FFFFFF),
      heroProgressFill: Colors.white,
      weekNavBackground: const Color(0x22FFFFFF),
      weekNavText: Colors.white,
      weekNavButton: Colors.white,
      avatarBackground: const Color(0x22FFFFFF),
      routeSelectorBackground: const Color(0x33FFFFFF),
      statusDotOnline: const Color(0xFF22C55E),
      scaffoldBackground: colors.scaffoldBackground,
      criticalBannerBackground: colors.criticalBannerBackground,
      criticalBannerText: colors.criticalBannerText,
      criticalAccent: colors.criticalAccent,
      statSuccess: Colors.white,
      statWarning: const Color(0xFFFEF3C7),
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section with work mode themed background (teal/green)
          Container(
            color: workModeColors.heroBackground,
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Day navigator (WORK MODE = DAILY)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _DayNav(
                    dayState: dayState,
                    onPrevious: () => ref.read(dayStateProvider.notifier).goToPreviousDay(),
                    onNext: dayState.canGoNext ? () => ref.read(dayStateProvider.notifier).goToNextDay() : null,
                    onToday: dayState.isToday ? null : () => ref.read(dayStateProvider.notifier).goToToday(),
                    colors: workModeColors,
                  ),
                ),
                const SizedBox(height: 24),
                // Daily summary hero - simplified for day view
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        'Resumen del Día',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: workModeColors.heroTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // TODO: Replace with actual daily stats when available
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _DailyStat(
                            label: 'Cobros',
                            value: isLoading ? '--' : '${stats.collectedPaymentsThisWeek}',
                            colors: workModeColors,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: workModeColors.heroTextSecondary.withOpacity(0.3),
                          ),
                          _DailyStat(
                            label: 'Monto',
                            value: isLoading ? '--' : _currencyFormat.format(stats.collectedAmountThisWeek),
                            colors: workModeColors,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: workModeColors.heroTextSecondary.withOpacity(0.3),
                          ),
                          _DailyStat(
                            label: 'Créditos',
                            value: isLoading ? '--' : '${stats.newLoansThisWeek}',
                            colors: workModeColors,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Content section - Daily operations
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick actions for work mode
                Text(
                  'Acciones Rápidas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: LucideIcons.dollarSign,
                        label: 'Cobrar',
                        color: const Color(0xFF0F766E),
                        onTap: () => context.push(AppRoutes.selectLocation),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: LucideIcons.plus,
                        label: 'Nuevo Crédito',
                        color: AppColors.primary,
                        onTap: () => context.push(AppRoutes.createCredit),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: LucideIcons.creditCard,
                        label: 'Créditos Hoy',
                        color: const Color(0xFF7C3AED),
                        onTap: () => context.push(AppRoutes.creditsToday),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: LucideIcons.receipt,
                        label: 'Gastos',
                        color: const Color(0xFFEA580C),
                        onTap: () {
                          // TODO: Navigate to expenses page
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Today's activity summary
                Text(
                  'Actividad del Día',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                // Key metrics for the day
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Pagos Recibidos',
                        value: '${stats.collectedPaymentsThisWeek}',
                        subtitle: 'clientes',
                        icon: LucideIcons.checkCircle,
                        isLoading: isLoading,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Créditos Otorgados',
                        value: '${stats.newLoansThisWeek}',
                        subtitle: 'hoy',
                        icon: LucideIcons.banknote,
                        isLoading: isLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// WORK MODE HEADER - Shows current locality with exit option
// =============================================================================

class _WorkModeHeader extends StatelessWidget {
  final String leadName;
  final String? locationName;
  final VoidCallback onExit;
  final VoidCallback onChangeLead;

  const _WorkModeHeader({
    required this.leadName,
    required this.locationName,
    required this.onExit,
    required this.onChangeLead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E), // Teal 700
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mode indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.briefcase, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                const Text(
                  'TRABAJO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Locality info
          Expanded(
            child: GestureDetector(
              onTap: onChangeLead,
              child: Row(
                children: [
                  const Icon(LucideIcons.mapPin, size: 16, color: Colors.white70),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          locationName ?? 'Sin localidad',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          leadName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronDown, size: 16, color: Colors.white70),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Exit button
          GestureDetector(
            onTap: onExit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.logOut, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  const Text(
                    'Salir',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DAY NAVIGATOR - For work mode daily navigation
// =============================================================================

class _DayNav extends StatelessWidget {
  final DayState dayState;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToday;
  final DashboardColors colors;

  const _DayNav({
    required this.dayState,
    required this.onPrevious,
    this.onNext,
    this.onToday,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: colors.weekNavBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _NavBtn(icon: LucideIcons.chevronLeft, onTap: onPrevious, colors: colors),
          Expanded(
            child: Column(
              children: [
                Text(
                  dayState.label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.heroTextPrimary),
                ),
                Text(
                  dayState.dateLabel,
                  style: TextStyle(fontSize: 11, color: colors.heroTextSecondary),
                ),
              ],
            ),
          ),
          if (!dayState.isToday) ...[
            _NavBtn(icon: LucideIcons.chevronRight, onTap: onNext, colors: colors),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onToday,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.weekNavButton,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hoy',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.heroBackground),
                ),
              ),
            ),
          ] else
            _NavBtn(icon: LucideIcons.chevronRight, onTap: null, colors: colors),
        ],
      ),
    );
  }
}

// =============================================================================
// DAILY STAT - For work mode hero section
// =============================================================================

class _DailyStat extends StatelessWidget {
  final String label;
  final String value;
  final DashboardColors colors;

  const _DailyStat({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: colors.heroTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.heroTextSecondary,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// QUICK ACTION CARD - For work mode actions
// =============================================================================

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// HEADER
// =============================================================================

class _Header extends StatelessWidget {
  final String userName;
  final bool isOnline;
  final List<RouteModel> routes;
  final RouteModel? selectedRoute;
  final Function(RouteModel?) onRouteSelected;
  final VoidCallback onLogout;
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  final DashboardColors colors;

  const _Header({
    required this.userName,
    required this.isOnline,
    required this.routes,
    required this.selectedRoute,
    required this.onRouteSelected,
    required this.onLogout,
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showLogoutSheet(context),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.avatarBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(userName),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.heroTextPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $userName',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.heroTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getDateLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.heroTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Theme toggle
        GestureDetector(
          onTap: onThemeToggle,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.routeSelectorBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDarkMode ? LucideIcons.sun : LucideIcons.moon,
              size: 18,
              color: colors.heroTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Route selector
        _RouteSelector(
          routes: routes,
          selectedRoute: selectedRoute,
          onRouteSelected: onRouteSelected,
          colors: colors,
        ),
        const SizedBox(width: 8),
        // Sync status
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.routeSelectorBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOnline ? colors.statusDotOnline : const Color(0xFFFACC15),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _getDateLabel() {
    final now = DateTime.now();
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _showLogoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.logOut, color: Color(0xFFDC2626), size: 20),
                ),
                title: const Text('Cerrar sesion', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Se eliminaran los datos locales', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  onLogout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteSelector extends StatelessWidget {
  final List<RouteModel> routes;
  final RouteModel? selectedRoute;
  final Function(RouteModel?) onRouteSelected;
  final DashboardColors colors;

  static const String _allRoutesId = '__ALL__';

  const _RouteSelector({
    required this.routes,
    required this.selectedRoute,
    required this.onRouteSelected,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (id) {
        if (id == _allRoutesId) {
          onRouteSelected(null);
        } else {
          final route = routes.firstWhere((r) => r.id == id);
          onRouteSelected(route);
        }
      },
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: _allRoutesId,
          child: Row(
            children: [
              Icon(LucideIcons.globe, size: 16, color: selectedRoute == null ? AppColors.primary : Colors.grey),
              const SizedBox(width: 10),
              Text(
                'Todas las rutas',
                style: TextStyle(
                  fontWeight: selectedRoute == null ? FontWeight.w600 : FontWeight.normal,
                  color: selectedRoute == null ? AppColors.primary : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        ...routes.map((route) => PopupMenuItem<String>(
              value: route.id,
              child: Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 16, color: selectedRoute?.id == route.id ? AppColors.primary : Colors.grey),
                  const SizedBox(width: 10),
                  Text(
                    route.name,
                    style: TextStyle(
                      fontWeight: selectedRoute?.id == route.id ? FontWeight.w600 : FontWeight.normal,
                      color: selectedRoute?.id == route.id ? AppColors.primary : Colors.black87,
                    ),
                  ),
                ],
              ),
            )),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.routeSelectorBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.mapPin, size: 14, color: colors.heroTextPrimary),
            const SizedBox(width: 6),
            Text(
              selectedRoute?.name ?? 'Todas',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.heroTextPrimary),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 14, color: colors.heroTextSecondary),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// WEEK NAVIGATOR
// =============================================================================

class _WeekNav extends StatelessWidget {
  final WeekState weekState;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToday;
  final DashboardColors colors;
  final bool isDarkMode;

  const _WeekNav({
    required this.weekState,
    required this.onPrevious,
    this.onNext,
    this.onToday,
    required this.colors,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: colors.weekNavBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _NavBtn(icon: LucideIcons.chevronLeft, onTap: onPrevious, colors: colors),
          Expanded(
            child: Column(
              children: [
                Text(
                  weekState.label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.heroTextPrimary),
                ),
                Text(
                  weekState.rangeLabel,
                  style: TextStyle(fontSize: 11, color: colors.heroTextSecondary),
                ),
              ],
            ),
          ),
          if (!weekState.isCurrentWeek) ...[
            _NavBtn(icon: LucideIcons.chevronRight, onTap: onNext, colors: colors),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onToday,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.weekNavButton,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hoy',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.heroBackground),
                ),
              ),
            ),
          ] else
            _NavBtn(icon: LucideIcons.chevronRight, onTap: null, disabled: true, colors: colors),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;
  final DashboardColors colors;

  const _NavBtn({required this.icon, this.onTap, this.disabled = false, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 20,
          color: disabled ? colors.heroTextSecondary.withOpacity(0.3) : colors.heroTextSecondary,
        ),
      ),
    );
  }
}

// =============================================================================
// HERO PROGRESS
// =============================================================================

class _HeroProgress extends StatelessWidget {
  final int collected;
  final int expected;
  final double progress;
  final String collectedAmount;
  final String expectedAmount;
  final bool isLoading;
  final DashboardColors colors;

  const _HeroProgress({
    required this.collected,
    required this.expected,
    required this.progress,
    required this.collectedAmount,
    required this.expectedAmount,
    this.isLoading = false,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final missing = expected - collected;
    final progressClamped = progress.clamp(0.0, 100.0);

    return Column(
      children: [
        // Main number
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              _Skeleton(width: 100, height: 56, color: colors.heroProgressBar)
            else
              Text(
                '$collected',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: colors.heroTextPrimary,
                  height: 1,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: isLoading
                  ? _Skeleton(width: 50, height: 24, color: colors.heroProgressBar)
                  : Text(
                      '/ $expected',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: colors.heroTextSecondary,
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'cobros esta semana',
          style: TextStyle(fontSize: 14, color: colors.heroTextSecondary),
        ),
        const SizedBox(height: 20),
        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: colors.heroProgressBar,
            borderRadius: BorderRadius.circular(4),
          ),
          child: isLoading
              ? null
              : ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressClamped / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: progressClamped >= 100 ? const Color(0xFF22C55E) : colors.heroProgressFill,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        // Stats row
        Row(
          children: [
            Expanded(
              child: _HeroStat(
                label: 'Cobrado',
                value: collectedAmount,
                color: colors.statSuccess,
                isLoading: isLoading,
                colors: colors,
              ),
            ),
            Container(width: 1, height: 36, color: colors.heroProgressBar),
            Expanded(
              child: _HeroStat(
                label: 'Faltan',
                value: '$missing cobros',
                color: missing > 0 ? colors.statWarning : colors.statSuccess,
                isLoading: isLoading,
                colors: colors,
              ),
            ),
            Container(width: 1, height: 36, color: colors.heroProgressBar),
            Expanded(
              child: _HeroStat(
                label: 'Meta',
                value: expectedAmount,
                color: colors.heroTextSecondary,
                isLoading: isLoading,
                colors: colors,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isLoading;
  final DashboardColors colors;

  const _HeroStat({required this.label, required this.value, required this.color, this.isLoading = false, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: colors.heroTextSecondary)),
        const SizedBox(height: 4),
        isLoading
            ? _Skeleton(width: 60, height: 14, color: colors.heroProgressBar)
            : Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
                textAlign: TextAlign.center,
              ),
      ],
    );
  }
}

// =============================================================================
// CRITICAL BANNER
// =============================================================================

class _CriticalBanner extends StatelessWidget {
  final int week4Count;
  final int week5PlusCount;
  final VoidCallback onTap;
  final DashboardColors colors;

  const _CriticalBanner({
    required this.week4Count,
    required this.week5PlusCount,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final total = week4Count + week5PlusCount;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.criticalBannerBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Left indicator bar
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.criticalAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Atención requerida',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colors.criticalBannerText.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.criticalAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$total',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colors.criticalAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Clientes en riesgo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.criticalBannerText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _CriticalPill(label: '4 sem', count: week4Count, color: colors.criticalAccent, textColor: colors.criticalBannerText),
                          const SizedBox(width: 8),
                          _CriticalPill(label: '5+ sem', count: week5PlusCount, color: const Color(0xFFEF4444), textColor: colors.criticalBannerText),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.criticalBannerText.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.arrowRight, size: 16, color: colors.criticalBannerText.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          // Bottom accent line
          Container(
            height: 3,
            margin: const EdgeInsets.only(top: 6, left: 16, right: 16),
            decoration: BoxDecoration(
              color: colors.criticalAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _CriticalPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color textColor;

  const _CriticalPill({
    required this.label,
    required this.count,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.7),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PORTFOLIO HEALTH
// =============================================================================

class _PortfolioHealth extends StatelessWidget {
  final int alCorriente;
  final int week1;
  final int week2;
  final int week3;
  final int week4;
  final int week5Plus;
  final int total;
  final VoidCallback? onCriticalTap;
  final bool isLoading;

  const _PortfolioHealth({
    required this.alCorriente,
    required this.week1,
    required this.week2,
    required this.week3,
    required this.week4,
    required this.week5Plus,
    required this.total,
    this.onCriticalTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Estado de cartera',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              const Spacer(),
              isLoading
                  ? _Skeleton(width: 60, height: 12)
                  : Text('$total activos', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: isLoading
                  ? _Skeleton(width: double.infinity, height: 10)
                  : Row(
                      children: [
                        if (alCorriente > 0) Expanded(flex: alCorriente, child: Container(color: const Color(0xFF22C55E))),
                        if (week1 > 0) Expanded(flex: week1, child: Container(color: const Color(0xFFFACC15))),
                        if (week2 > 0) Expanded(flex: week2, child: Container(color: const Color(0xFFF59E0B))),
                        if (week3 > 0) Expanded(flex: week3, child: Container(color: const Color(0xFFEA580C))),
                        if (week4 > 0) Expanded(flex: week4, child: Container(color: const Color(0xFFDC2626))),
                        if (week5Plus > 0) Expanded(flex: week5Plus, child: Container(color: const Color(0xFF991B1B))),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          // Legend
          isLoading
              ? Row(
                  children: [
                    _Skeleton(width: 50, height: 12),
                    const SizedBox(width: 16),
                    _Skeleton(width: 50, height: 12),
                    const SizedBox(width: 16),
                    _Skeleton(width: 50, height: 12),
                  ],
                )
              : Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _LegendItem(color: const Color(0xFF22C55E), label: 'Al dia', count: alCorriente),
                    _LegendItem(color: const Color(0xFFFACC15), label: '1 sem', count: week1),
                    _LegendItem(color: const Color(0xFFF59E0B), label: '2 sem', count: week2),
                    _LegendItem(color: const Color(0xFFEA580C), label: '3 sem', count: week3),
                    GestureDetector(
                      onTap: onCriticalTap,
                      child: _LegendItem(color: const Color(0xFFDC2626), label: '4 sem', count: week4, highlight: week4 > 0),
                    ),
                    GestureDetector(
                      onTap: onCriticalTap,
                      child: _LegendItem(color: const Color(0xFF991B1B), label: '5+ sem', count: week5Plus, highlight: week5Plus > 0),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final bool highlight;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 11,
            color: highlight ? color : const Color(0xFF64748B),
            fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: highlight ? color : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// METRIC CARD
// =============================================================================

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool isLoading;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 8),
          isLoading
              ? _Skeleton(width: 80, height: 20)
              : Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
          const SizedBox(height: 2),
          isLoading
              ? _Skeleton(width: 60, height: 11)
              : Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

// =============================================================================
// MOVEMENT CARD
// =============================================================================

class _MovementCard extends StatelessWidget {
  final int newLoans;
  final int renewed;
  final int finished;
  final int balance;
  final String newLoansAmount;
  final bool isLoading;

  const _MovementCard({
    required this.newLoans,
    required this.renewed,
    required this.finished,
    required this.balance,
    required this.newLoansAmount,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Movimiento semanal',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              const Spacer(),
              isLoading
                  ? _Skeleton(width: 50, height: 24, borderRadius: 20)
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                            size: 14,
                            color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${balance >= 0 ? '+' : ''}$balance',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
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
              Expanded(child: _MovementStat(icon: LucideIcons.userPlus, label: 'Nuevos', value: '$newLoans', subValue: newLoansAmount, color: const Color(0xFF22C55E), isLoading: isLoading)),
              Container(width: 1, height: 44, color: const Color(0xFFE2E8F0)),
              Expanded(child: _MovementStat(icon: LucideIcons.refreshCw, label: 'Renovados', value: '$renewed', color: const Color(0xFF3B82F6), isLoading: isLoading)),
              Container(width: 1, height: 44, color: const Color(0xFFE2E8F0)),
              Expanded(child: _MovementStat(icon: LucideIcons.userMinus, label: 'Finalizados', value: '$finished', color: const Color(0xFF64748B), isLoading: isLoading)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MovementStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final Color color;
  final bool isLoading;

  const _MovementStat({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: isLoading ? const Color(0xFFE2E8F0) : color),
        const SizedBox(height: 6),
        isLoading
            ? _Skeleton(width: 24, height: 18)
            : Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        if (subValue != null && !isLoading)
          Text(subValue!, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// =============================================================================
// COMPARISON ROW
// =============================================================================

class _ComparisonRow extends StatelessWidget {
  final int collectedThisWeek;
  final int collectedLastWeek;
  final int difference;
  final bool isAhead;
  final bool isLoading;

  const _ComparisonRow({
    required this.collectedThisWeek,
    required this.collectedLastWeek,
    required this.difference,
    required this.isAhead,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.barChart3, size: 18, color: Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'vs semana pasada',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                isLoading
                    ? Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: _Skeleton(width: 120, height: 11),
                      )
                    : Text(
                        'Esta: $collectedThisWeek  •  Anterior: $collectedLastWeek',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
              ],
            ),
          ),
          isLoading
              ? _Skeleton(width: 40, height: 28, borderRadius: 8)
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAhead ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${difference >= 0 ? '+' : ''}$difference',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isAhead ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// =============================================================================
// WORK MODE NAV BAR (when locality is selected)
// =============================================================================

class _WorkModeNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _WorkModeNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: LucideIcons.dollarSign, label: 'Cobranza', isSelected: currentIndex == 0, onTap: () => onTap(0)),
              _NavItem(icon: LucideIcons.creditCard, label: 'Créditos', isSelected: currentIndex == 1, onTap: () => onTap(1)),
              const SizedBox(width: 56), // Space for FAB
              _NavItem(icon: LucideIcons.receipt, label: 'Gastos', isSelected: currentIndex == 3, onTap: () => onTap(3)),
              _NavItem(icon: LucideIcons.clipboardList, label: 'Resumen', isSelected: currentIndex == 4, onTap: () => onTap(4)),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// GENERAL NAV BAR (when no locality selected)
// =============================================================================

class _GeneralNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _GeneralNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(icon: LucideIcons.home, label: 'Inicio', isSelected: currentIndex == 0, onTap: () => onTap(0)),
              _NavItem(icon: LucideIcons.clipboardList, label: 'Jornada', isSelected: currentIndex == 1, onTap: () => onTap(1)),
              _NavItem(icon: LucideIcons.users, label: 'Clientes', isSelected: currentIndex == 2, onTap: () => onTap(2)),
            ],
          ),
        ),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SKELETON LOADER
// =============================================================================

class _Skeleton extends StatefulWidget {
  final double width;
  final double height;
  final Color? color;
  final double borderRadius;

  const _Skeleton({
    required this.width,
    required this.height,
    this.color,
    this.borderRadius = 6,
  });

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

// =============================================================================
// SYNC STATUS BANNER - Prominent sync status at top of dashboard
// =============================================================================

class _SyncStatusBanner extends ConsumerWidget {
  const _SyncStatusBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusProvider);
    final lastSync = ref.watch(lastSyncTimeProvider);

    return syncStatusAsync.when(
      data: (extStatus) => _buildBanner(extStatus, lastSync),
      loading: () => _buildLoadingBanner(),
      error: (error, _) => _buildErrorBanner('Error de conexión: $error'),
    );
  }

  Widget _buildBanner(ExtendedSyncStatus extStatus, DateTime? lastSync) {
    final status = extStatus.status;

    // PRIORITY 1: Check if actively syncing (show sync status even if there was a recent error)
    if (status.downloading) {
      return _SyncingBanner(
        icon: LucideIcons.download,
        message: 'Descargando datos del servidor...',
      );
    }

    if (status.uploading) {
      return _SyncingBanner(
        icon: LucideIcons.upload,
        message: 'Enviando cambios al servidor...',
      );
    }

    if (status.connecting) {
      return _SyncingBanner(
        icon: LucideIcons.wifi,
        message: 'Conectando al servidor...',
      );
    }

    // Connected but waiting for initial sync
    if (status.connected && status.lastSyncedAt == null) {
      return _SyncingBanner(
        icon: LucideIcons.cloud,
        message: 'Sincronización inicial en progreso...',
      );
    }

    // PRIORITY 2: Check for errors (only if not actively syncing)
    if (extStatus.hasRecentError) {
      if (extStatus.isAuthError) {
        return _ErrorBanner(
          icon: LucideIcons.keyRound,
          title: 'Error de autenticación',
          message: 'No se puede sincronizar. Verifica tu conexión.',
          color: AppColors.error,
        );
      }
      return _ErrorBanner(
        icon: LucideIcons.alertTriangle,
        title: 'Error de sincronización',
        message: 'Reintentando conexión...',
        color: AppColors.warning,
      );
    }

    // Successfully synced - show brief success message then hide
    if (status.connected && status.lastSyncedAt != null) {
      // Only show success banner if synced recently (last 5 seconds)
      final syncedRecently = lastSync != null &&
          DateTime.now().difference(lastSync).inSeconds < 5;

      if (syncedRecently) {
        return _SuccessBanner(lastSync: lastSync!);
      }
      // Otherwise, show nothing - dashboard is ready
      return const SizedBox.shrink();
    }

    // Offline
    if (!status.connected) {
      return _OfflineBanner();
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingBanner() {
    return _SyncingBanner(
      icon: LucideIcons.loader,
      message: 'Iniciando sincronización...',
    );
  }

  Widget _buildErrorBanner(String message) {
    return _ErrorBanner(
      icon: LucideIcons.alertCircle,
      title: 'Error',
      message: message,
      color: AppColors.error,
    );
  }
}

class _SyncingBanner extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SyncingBanner({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.info.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _ErrorBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Pulsing dot to indicate trying to reconnect
          _PulsingDot(color: color),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final DateTime lastSync;

  const _SuccessBanner({required this.lastSync});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.success.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Text(
            'Sincronizado',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.textMuted.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.cloudOff, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            'Sin conexión - Modo offline',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}


