import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'powersync_provider.dart';
import 'auth_provider.dart';

/// Dashboard statistics model
class DashboardStats {
  final double totalPortfolio;
  final double collectedAmount;
  final double pendingAmount;
  final double collectionProgress;
  final int weeklyLoansCount;
  final double weeklyLoansAmount;
  final int weeklyPaymentsCount;
  final double weeklyPaymentsAmount;
  final int pendingCollectionsToday;
  final int newClientsThisWeek;
  final double portfolioGrowth;
  final String userName;
  final String currentWeek;
  final bool isOnline;

  const DashboardStats({
    required this.totalPortfolio,
    required this.collectedAmount,
    required this.pendingAmount,
    required this.collectionProgress,
    required this.weeklyLoansCount,
    required this.weeklyLoansAmount,
    required this.weeklyPaymentsCount,
    required this.weeklyPaymentsAmount,
    required this.pendingCollectionsToday,
    required this.newClientsThisWeek,
    required this.portfolioGrowth,
    required this.userName,
    required this.currentWeek,
    required this.isOnline,
  });

  factory DashboardStats.empty() => const DashboardStats(
        totalPortfolio: 0,
        collectedAmount: 0,
        pendingAmount: 0,
        collectionProgress: 0,
        weeklyLoansCount: 0,
        weeklyLoansAmount: 0,
        weeklyPaymentsCount: 0,
        weeklyPaymentsAmount: 0,
        pendingCollectionsToday: 0,
        newClientsThisWeek: 0,
        portfolioGrowth: 0,
        userName: 'Usuario',
        currentWeek: '',
        isOnline: false,
      );
}

/// Dashboard stats provider with PowerSync queries
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final dbAsyncValue = ref.watch(powerSyncDatabaseProvider);
  final authState = ref.watch(authProvider);
  final isSyncing = ref.watch(isSyncingProvider);

  final db = dbAsyncValue.valueOrNull;
  if (db == null) {
    return DashboardStats.empty();
  }

  // Get current week info
  final now = DateTime.now();
  final weekNumber = _getWeekNumber(now);
  final currentWeek = 'Semana $weekNumber de ${now.year}';

  // Get start of current week (Monday)
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfWeekStr = startOfWeek.toIso8601String().split('T')[0];

  // Get user name
  final userName = authState.user?.fullName?.split(' ').first ?? 'Usuario';

  try {
    // Query 1: Total portfolio (sum of pendingAmountStored for ACTIVE loans)
    final portfolioResult = await db.execute('''
      SELECT
        COALESCE(SUM(pendingAmountStored), 0) as totalPending,
        COALESCE(SUM(totalPaid), 0) as totalCollected,
        COALESCE(SUM(totalDebtAcquired), 0) as totalDebt
      FROM Loan
      WHERE status = 'ACTIVE'
    ''');

    double totalPortfolio = 0;
    double collectedAmount = 0;
    double pendingAmount = 0;

    if (portfolioResult.isNotEmpty) {
      final row = portfolioResult.first;
      pendingAmount = (row['totalPending'] as num?)?.toDouble() ?? 0;
      collectedAmount = (row['totalCollected'] as num?)?.toDouble() ?? 0;
      final totalDebt = (row['totalDebt'] as num?)?.toDouble() ?? 0;
      totalPortfolio = totalDebt;
    }

    // Calculate collection progress
    double collectionProgress = 0;
    if (totalPortfolio > 0) {
      collectionProgress = collectedAmount / totalPortfolio;
    }

    // Query 2: Weekly loans (created this week)
    final weeklyLoansResult = await db.execute('''
      SELECT
        COUNT(*) as count,
        COALESCE(SUM(requestedAmount), 0) as amount
      FROM Loan
      WHERE signDate >= ?
    ''', [startOfWeekStr]);

    int weeklyLoansCount = 0;
    double weeklyLoansAmount = 0;

    if (weeklyLoansResult.isNotEmpty) {
      final row = weeklyLoansResult.first;
      weeklyLoansCount = (row['count'] as num?)?.toInt() ?? 0;
      weeklyLoansAmount = (row['amount'] as num?)?.toDouble() ?? 0;
    }

    // Query 3: Weekly payments
    final weeklyPaymentsResult = await db.execute('''
      SELECT
        COUNT(*) as count,
        COALESCE(SUM(amount), 0) as amount
      FROM LoanPayment
      WHERE receivedAt >= ?
    ''', [startOfWeekStr]);

    int weeklyPaymentsCount = 0;
    double weeklyPaymentsAmount = 0;

    if (weeklyPaymentsResult.isNotEmpty) {
      final row = weeklyPaymentsResult.first;
      weeklyPaymentsCount = (row['count'] as num?)?.toInt() ?? 0;
      weeklyPaymentsAmount = (row['amount'] as num?)?.toDouble() ?? 0;
    }

    // Query 4: Count active loans (pending collections)
    final activeLoansResult = await db.execute('''
      SELECT COUNT(*) as count
      FROM Loan
      WHERE status = 'ACTIVE' AND pendingAmountStored > 0
    ''');

    int pendingCollectionsToday = 0;
    if (activeLoansResult.isNotEmpty) {
      pendingCollectionsToday =
          (activeLoansResult.first['count'] as num?)?.toInt() ?? 0;
    }

    // Query 5: New clients this week
    final newClientsResult = await db.execute('''
      SELECT COUNT(*) as count
      FROM PersonalData
      WHERE createdAt >= ?
    ''', [startOfWeekStr]);

    int newClientsThisWeek = 0;
    if (newClientsResult.isNotEmpty) {
      newClientsThisWeek =
          (newClientsResult.first['count'] as num?)?.toInt() ?? 0;
    }

    // Query 6: Portfolio growth (compare to last week)
    final lastWeekStart =
        startOfWeek.subtract(const Duration(days: 7)).toIso8601String().split('T')[0];
    final lastWeekResult = await db.execute('''
      SELECT COALESCE(SUM(totalDebtAcquired), 0) as lastWeekTotal
      FROM Loan
      WHERE status = 'ACTIVE' AND signDate < ?
    ''', [startOfWeekStr]);

    double portfolioGrowth = 0;
    if (lastWeekResult.isNotEmpty) {
      final lastWeekTotal =
          (lastWeekResult.first['lastWeekTotal'] as num?)?.toDouble() ?? 0;
      if (lastWeekTotal > 0) {
        portfolioGrowth = ((totalPortfolio - lastWeekTotal) / lastWeekTotal) * 100;
      }
    }

    return DashboardStats(
      totalPortfolio: totalPortfolio,
      collectedAmount: collectedAmount,
      pendingAmount: pendingAmount,
      collectionProgress: collectionProgress,
      weeklyLoansCount: weeklyLoansCount,
      weeklyLoansAmount: weeklyLoansAmount,
      weeklyPaymentsCount: weeklyPaymentsCount,
      weeklyPaymentsAmount: weeklyPaymentsAmount,
      pendingCollectionsToday: pendingCollectionsToday,
      newClientsThisWeek: newClientsThisWeek,
      portfolioGrowth: portfolioGrowth,
      userName: userName,
      currentWeek: currentWeek,
      isOnline: !isSyncing,
    );
  } catch (e) {
    // Return empty stats if queries fail
    return DashboardStats(
      totalPortfolio: 0,
      collectedAmount: 0,
      pendingAmount: 0,
      collectionProgress: 0,
      weeklyLoansCount: 0,
      weeklyLoansAmount: 0,
      weeklyPaymentsCount: 0,
      weeklyPaymentsAmount: 0,
      pendingCollectionsToday: 0,
      newClientsThisWeek: 0,
      portfolioGrowth: 0,
      userName: userName,
      currentWeek: currentWeek,
      isOnline: !isSyncing,
    );
  }
});

/// Helper to get ISO week number
int _getWeekNumber(DateTime date) {
  final firstDayOfYear = DateTime(date.year, 1, 1);
  final daysDifference = date.difference(firstDayOfYear).inDays;
  return ((daysDifference + firstDayOfYear.weekday) / 7).ceil();
}
