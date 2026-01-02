import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'powersync_provider.dart';
import 'auth_provider.dart';

/// Route model for selector
class RouteModel {
  final String id;
  final String name;

  const RouteModel({required this.id, required this.name});
}

/// Selected week state
class WeekState {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int weekNumber;
  final int year;
  final bool isCurrentWeek;

  WeekState({
    required this.weekStart,
    required this.weekEnd,
    required this.weekNumber,
    required this.year,
    required this.isCurrentWeek,
  });

  String get label => 'Semana $weekNumber de $year';

  String get rangeLabel {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final startMonth = months[weekStart.month - 1];
    final endMonth = months[weekEnd.month - 1];

    if (startMonth == endMonth) {
      return 'Lun ${weekStart.day} - Sáb ${weekEnd.day} $startMonth';
    } else {
      return 'Lun ${weekStart.day} $startMonth - Sáb ${weekEnd.day} $endMonth';
    }
  }

  factory WeekState.current() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 5)); // Saturday
    return WeekState(
      weekStart: DateTime(weekStart.year, weekStart.month, weekStart.day),
      weekEnd: DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59),
      weekNumber: _getWeekNumber(now),
      year: now.year,
      isCurrentWeek: true,
    );
  }

  WeekState previousWeek() {
    final newWeekStart = weekStart.subtract(const Duration(days: 7));
    final newWeekEnd = weekEnd.subtract(const Duration(days: 7));
    return WeekState(
      weekStart: newWeekStart,
      weekEnd: newWeekEnd,
      weekNumber: weekNumber == 1 ? 52 : weekNumber - 1,
      year: weekNumber == 1 ? year - 1 : year,
      isCurrentWeek: false,
    );
  }

  WeekState nextWeek() {
    final newWeekStart = weekStart.add(const Duration(days: 7));
    final newWeekEnd = weekEnd.add(const Duration(days: 7));
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final isNowCurrentWeek = newWeekStart.year == currentWeekStart.year &&
        newWeekStart.month == currentWeekStart.month &&
        newWeekStart.day == currentWeekStart.day;

    return WeekState(
      weekStart: newWeekStart,
      weekEnd: newWeekEnd,
      weekNumber: weekNumber == 52 ? 1 : weekNumber + 1,
      year: weekNumber == 52 ? year + 1 : year,
      isCurrentWeek: isNowCurrentWeek,
    );
  }

  static int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday) / 7).ceil();
  }
}

/// Week state notifier
class WeekStateNotifier extends StateNotifier<WeekState> {
  WeekStateNotifier() : super(WeekState.current());

  void goToPreviousWeek() {
    state = state.previousWeek();
  }

  void goToNextWeek() {
    if (!state.isCurrentWeek) {
      state = state.nextWeek();
    }
  }

  void goToCurrentWeek() {
    state = WeekState.current();
  }
}

final weekStateProvider =
    StateNotifierProvider<WeekStateNotifier, WeekState>((ref) {
  return WeekStateNotifier();
});

/// Routes provider
final routesProvider = FutureProvider<List<RouteModel>>((ref) async {
  final dbAsyncValue = ref.watch(powerSyncDatabaseProvider);
  final db = dbAsyncValue.valueOrNull;
  if (db == null) return [];

  try {
    final result = await db.execute('''
      SELECT id, name FROM Route ORDER BY name
    ''');

    return result.map((row) => RouteModel(
          id: row['id'] as String,
          name: row['name'] as String,
        )).toList();
  } catch (e) {
    return [];
  }
});

/// Selected route provider
final selectedRouteProvider = StateProvider<RouteModel?>((ref) => null);

/// Collector-focused dashboard stats
class CollectorDashboardStats {
  // Route info
  final String? routeName;

  // Week comparison
  final int expectedPaymentsThisWeek; // How many clients should pay this week
  final int collectedPaymentsThisWeek; // How many actually paid
  final int missingPaymentsThisWeek; // Expected - Collected
  final double collectedAmountThisWeek;
  final double expectedAmountThisWeek;

  // Last week comparison
  final int collectedPaymentsLastWeek;
  final double collectedAmountLastWeek;
  final int comparisonVsLastWeek; // Difference in count
  final double comparisonAmountVsLastWeek;

  // Goal progress
  final double goalProgress; // % of expected collected
  final bool isAheadOfLastWeek;

  // Portfolio (active loans only - PortfolioCleanup concept)
  final int activeLoansCount;
  final double totalPendingDebt;
  final double totalCollected;

  // New loans this week
  final int newLoansThisWeek;
  final double newLoansAmountThisWeek;

  // User info
  final String userName;
  final bool isOnline;

  const CollectorDashboardStats({
    this.routeName,
    required this.expectedPaymentsThisWeek,
    required this.collectedPaymentsThisWeek,
    required this.missingPaymentsThisWeek,
    required this.collectedAmountThisWeek,
    required this.expectedAmountThisWeek,
    required this.collectedPaymentsLastWeek,
    required this.collectedAmountLastWeek,
    required this.comparisonVsLastWeek,
    required this.comparisonAmountVsLastWeek,
    required this.goalProgress,
    required this.isAheadOfLastWeek,
    required this.activeLoansCount,
    required this.totalPendingDebt,
    required this.totalCollected,
    required this.newLoansThisWeek,
    required this.newLoansAmountThisWeek,
    required this.userName,
    required this.isOnline,
  });

  factory CollectorDashboardStats.empty() => const CollectorDashboardStats(
        routeName: null,
        expectedPaymentsThisWeek: 0,
        collectedPaymentsThisWeek: 0,
        missingPaymentsThisWeek: 0,
        collectedAmountThisWeek: 0,
        expectedAmountThisWeek: 0,
        collectedPaymentsLastWeek: 0,
        collectedAmountLastWeek: 0,
        comparisonVsLastWeek: 0,
        comparisonAmountVsLastWeek: 0,
        goalProgress: 0,
        isAheadOfLastWeek: false,
        activeLoansCount: 0,
        totalPendingDebt: 0,
        totalCollected: 0,
        newLoansThisWeek: 0,
        newLoansAmountThisWeek: 0,
        userName: 'Usuario',
        isOnline: false,
      );
}

/// Collector dashboard stats provider
final collectorDashboardStatsProvider =
    FutureProvider<CollectorDashboardStats>((ref) async {
  final dbAsyncValue = ref.watch(powerSyncDatabaseProvider);
  final authState = ref.watch(authProvider);
  final isSyncing = ref.watch(isSyncingProvider);
  final weekState = ref.watch(weekStateProvider);
  final selectedRoute = ref.watch(selectedRouteProvider);

  final db = dbAsyncValue.valueOrNull;
  if (db == null) {
    return CollectorDashboardStats.empty();
  }

  final userName = authState.user?.fullName?.split(' ').first ?? 'Usuario';
  final weekStartStr = weekState.weekStart.toIso8601String().split('T')[0];
  final weekEndStr = weekState.weekEnd.toIso8601String().split('T')[0];
  final lastWeekStartStr =
      weekState.weekStart.subtract(const Duration(days: 7)).toIso8601String().split('T')[0];
  final lastWeekEndStr =
      weekState.weekEnd.subtract(const Duration(days: 7)).toIso8601String().split('T')[0];

  // Route filter clause
  final routeFilter = selectedRoute != null
      ? "AND snapshotRouteId = '${selectedRoute.id}'"
      : '';

  try {
    // Build renewal map: Get all loan IDs that have been renewed
    // (i.e., another loan exists with previousLoan = this.id)
    final renewedLoansResult = await db.execute('''
      SELECT DISTINCT previousLoan as renewedLoanId
      FROM Loan
      WHERE previousLoan IS NOT NULL AND previousLoan != ''
    ''');

    final renewedLoanIds = <String>{};
    for (final row in renewedLoansResult) {
      final id = row['renewedLoanId'] as String?;
      if (id != null && id.isNotEmpty) {
        renewedLoanIds.add(id);
      }
    }

    // Query 1: Get all loans active during the selected week
    // Matching API's getRouteKPIs historical logic:
    // - signDate <= weekEnd (signed before or during this week)
    // - excludedByCleanup IS NULL
    // - finishedDate IS NULL OR finishedDate >= weekStart (not finished before this week)
    // - renewedDate IS NULL OR renewedDate >= weekStart (not renewed before this week)
    // Then in Dart: check stillActiveAtWeekEnd (finishedDate/renewedDate IS NULL OR > weekEnd)

    final potentialLoansResult = await db.execute('''
      SELECT
        id,
        pendingAmountStored,
        totalPaid,
        totalDebtAcquired,
        expectedWeeklyPayment,
        signDate,
        finishedDate,
        renewedDate,
        previousLoan
      FROM Loan
      WHERE (excludedByCleanup IS NULL OR excludedByCleanup = '')
        AND signDate <= ?
        AND (finishedDate IS NULL OR finishedDate = '' OR finishedDate >= ?)
        AND (renewedDate IS NULL OR renewedDate = '' OR renewedDate >= ?)
        ${selectedRoute != null ? "AND snapshotRouteId = '${selectedRoute.id}'" : ''}
    ''', [weekEndStr, weekStartStr, weekStartStr]);

    // Filter loans matching API's isLoanConsideredOnDate logic:
    // 1. stillActiveAtWeekEnd (finishedDate/renewedDate IS NULL OR > weekEnd)
    // 2. realPendingAmount > 0 (totalDebt - totalPaid)
    // 3. Only check renewalMap for loans with previousLoan
    int activeLoansCount = 0;
    double totalPendingDebt = 0;
    double totalCollected = 0;
    double expectedWeeklyTotal = 0;

    for (final row in potentialLoansResult) {
      final loanId = row['id'] as String?;
      final finishedDateStr = row['finishedDate'] as String?;
      final renewedDateStr = row['renewedDate'] as String?;
      final previousLoan = row['previousLoan'] as String?;
      final totalPaid = (row['totalPaid'] as num?)?.toDouble() ?? 0;
      final totalDebt = (row['totalDebtAcquired'] as num?)?.toDouble() ?? 0;
      final pendingStored = (row['pendingAmountStored'] as num?)?.toDouble() ?? 0;

      // Check if still active at week end (matching API's stillActiveAtWeekEnd logic)
      final finishedAfterWeekEnd = finishedDateStr == null || finishedDateStr.isEmpty || finishedDateStr.compareTo(weekEndStr) > 0;
      final renewedAfterWeekEnd = renewedDateStr == null || renewedDateStr.isEmpty || renewedDateStr.compareTo(weekEndStr) > 0;
      final stillActiveAtWeekEnd = finishedAfterWeekEnd && renewedAfterWeekEnd;

      // Calculate real pending amount (matching API's isLoanConsideredOnDate)
      final realPendingAmount = totalDebt > 0 ? (totalDebt - totalPaid) : pendingStored;

      // Only check renewedLoanIds for loans with previousLoan (matching API logic)
      final hasNewerRenewal = (previousLoan != null && previousLoan.isNotEmpty)
          ? renewedLoanIds.contains(loanId)
          : false;

      if (loanId != null && stillActiveAtWeekEnd && realPendingAmount > 0 && !hasNewerRenewal) {
        activeLoansCount++;
        totalPendingDebt += pendingStored;
        totalCollected += totalPaid;
        expectedWeeklyTotal += (row['expectedWeeklyPayment'] as num?)?.toDouble() ?? 0;
      }
    }

    // Query 2: Payments collected this week (filtering out renewed loans)
    // Matching API's buildActiveLoansWhereClause logic exactly
    final paymentsThisWeekResult = await db.execute('''
      SELECT
        lp.loan as loanId,
        lp.amount
      FROM LoanPayment lp
      INNER JOIN Loan l ON lp.loan = l.id
      WHERE lp.receivedAt >= ? AND lp.receivedAt <= ?
        AND l.pendingAmountStored > 0
        AND (l.excludedByCleanup IS NULL OR l.excludedByCleanup = '')
        AND (l.finishedDate IS NULL OR l.finishedDate = '')
        AND (l.renewedDate IS NULL OR l.renewedDate = '')
        ${selectedRoute != null ? "AND l.snapshotRouteId = '${selectedRoute.id}'" : ''}
    ''', [weekStartStr, weekEndStr + 'T23:59:59']);

    final paidLoansThisWeek = <String>{};
    double collectedAmountThisWeek = 0;

    for (final row in paymentsThisWeekResult) {
      final loanId = row['loanId'] as String?;
      if (loanId != null && !renewedLoanIds.contains(loanId)) {
        paidLoansThisWeek.add(loanId);
        collectedAmountThisWeek += (row['amount'] as num?)?.toDouble() ?? 0;
      }
    }
    final collectedPaymentsThisWeek = paidLoansThisWeek.length;

    // Query 3: Payments collected last week (for comparison)
    // Matching API's buildActiveLoansWhereClause logic exactly
    final paymentsLastWeekResult = await db.execute('''
      SELECT
        lp.loan as loanId,
        lp.amount
      FROM LoanPayment lp
      INNER JOIN Loan l ON lp.loan = l.id
      WHERE lp.receivedAt >= ? AND lp.receivedAt <= ?
        AND l.pendingAmountStored > 0
        AND (l.excludedByCleanup IS NULL OR l.excludedByCleanup = '')
        AND (l.finishedDate IS NULL OR l.finishedDate = '')
        AND (l.renewedDate IS NULL OR l.renewedDate = '')
        ${selectedRoute != null ? "AND l.snapshotRouteId = '${selectedRoute.id}'" : ''}
    ''', [lastWeekStartStr, lastWeekEndStr + 'T23:59:59']);

    final paidLoansLastWeek = <String>{};
    double collectedAmountLastWeek = 0;

    for (final row in paymentsLastWeekResult) {
      final loanId = row['loanId'] as String?;
      if (loanId != null && !renewedLoanIds.contains(loanId)) {
        paidLoansLastWeek.add(loanId);
        collectedAmountLastWeek += (row['amount'] as num?)?.toDouble() ?? 0;
      }
    }
    final collectedPaymentsLastWeek = paidLoansLastWeek.length;

    // Query 4: New loans this week
    final newLoansResult = await db.execute('''
      SELECT
        COUNT(*) as count,
        COALESCE(SUM(requestedAmount), 0) as amount
      FROM Loan
      WHERE signDate >= ? AND signDate <= ?
        $routeFilter
    ''', [weekStartStr, weekEndStr]);

    int newLoansThisWeek = 0;
    double newLoansAmountThisWeek = 0;

    if (newLoansResult.isNotEmpty) {
      final row = newLoansResult.first;
      newLoansThisWeek = (row['count'] as num?)?.toInt() ?? 0;
      newLoansAmountThisWeek = (row['amount'] as num?)?.toDouble() ?? 0;
    }

    // Calculate metrics
    final expectedPaymentsThisWeek = activeLoansCount; // Each active loan expects 1 payment per week
    final missingPaymentsThisWeek = (expectedPaymentsThisWeek - collectedPaymentsThisWeek).clamp(0, expectedPaymentsThisWeek);
    final expectedAmountThisWeek = expectedWeeklyTotal;

    final goalProgress = expectedPaymentsThisWeek > 0
        ? (collectedPaymentsThisWeek / expectedPaymentsThisWeek * 100).clamp(0.0, 100.0)
        : 0.0;

    final comparisonVsLastWeek = collectedPaymentsThisWeek - collectedPaymentsLastWeek;
    final comparisonAmountVsLastWeek = collectedAmountThisWeek - collectedAmountLastWeek;
    final isAheadOfLastWeek = comparisonVsLastWeek >= 0;

    return CollectorDashboardStats(
      routeName: selectedRoute?.name,
      expectedPaymentsThisWeek: expectedPaymentsThisWeek,
      collectedPaymentsThisWeek: collectedPaymentsThisWeek,
      missingPaymentsThisWeek: missingPaymentsThisWeek,
      collectedAmountThisWeek: collectedAmountThisWeek,
      expectedAmountThisWeek: expectedAmountThisWeek,
      collectedPaymentsLastWeek: collectedPaymentsLastWeek,
      collectedAmountLastWeek: collectedAmountLastWeek,
      comparisonVsLastWeek: comparisonVsLastWeek,
      comparisonAmountVsLastWeek: comparisonAmountVsLastWeek,
      goalProgress: goalProgress,
      isAheadOfLastWeek: isAheadOfLastWeek,
      activeLoansCount: activeLoansCount,
      totalPendingDebt: totalPendingDebt,
      totalCollected: totalCollected,
      newLoansThisWeek: newLoansThisWeek,
      newLoansAmountThisWeek: newLoansAmountThisWeek,
      userName: userName,
      isOnline: !isSyncing,
    );
  } catch (e) {
    return CollectorDashboardStats(
      routeName: selectedRoute?.name,
      expectedPaymentsThisWeek: 0,
      collectedPaymentsThisWeek: 0,
      missingPaymentsThisWeek: 0,
      collectedAmountThisWeek: 0,
      expectedAmountThisWeek: 0,
      collectedPaymentsLastWeek: 0,
      collectedAmountLastWeek: 0,
      comparisonVsLastWeek: 0,
      comparisonAmountVsLastWeek: 0,
      goalProgress: 0,
      isAheadOfLastWeek: false,
      activeLoansCount: 0,
      totalPendingDebt: 0,
      totalCollected: 0,
      newLoansThisWeek: 0,
      newLoansAmountThisWeek: 0,
      userName: userName,
      isOnline: !isSyncing,
    );
  }
});
