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

/// Critical client model - clients in week 4+ without paying
class CriticalClient {
  final String loanId;
  final String borrowerId;
  final String clientName;
  final String? clientCode;
  final String? phone;
  final double pendingAmount;
  final double expectedWeeklyPayment;
  final int weeksWithoutPayment;
  final DateTime signDate;
  final DateTime? lastPaymentDate;
  final String? routeName;
  final String? leadLocality; // Localidad del líder asociado

  const CriticalClient({
    required this.loanId,
    required this.borrowerId,
    required this.clientName,
    this.clientCode,
    this.phone,
    required this.pendingAmount,
    required this.expectedWeeklyPayment,
    required this.weeksWithoutPayment,
    required this.signDate,
    this.lastPaymentDate,
    this.routeName,
    this.leadLocality,
  });
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
      return 'Lun ${weekStart.day} - Dom ${weekEnd.day} $startMonth';
    } else {
      return 'Lun ${weekStart.day} $startMonth - Dom ${weekEnd.day} $endMonth';
    }
  }

  factory WeekState.current() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6)); // Sunday
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
  final int expectedPaymentsThisWeek;
  final int collectedPaymentsThisWeek;
  final int missingPaymentsThisWeek;
  final double collectedAmountThisWeek;
  final double expectedAmountThisWeek;

  // Last week comparison
  final int collectedPaymentsLastWeek;
  final double collectedAmountLastWeek;
  final int comparisonVsLastWeek;
  final double comparisonAmountVsLastWeek;

  // Goal progress
  final double goalProgress;
  final bool isAheadOfLastWeek;

  // Portfolio
  final int activeLoansCount;
  final double totalPendingDebt;
  final double totalCollected;

  // New loans this week
  final int newLoansThisWeek;
  final double newLoansAmountThisWeek;

  // Portfolio movement (credits delta)
  final int renewedLoansThisWeek;    // Loans renewed this week
  final int finishedLoansThisWeek;   // Loans finished this week
  final int portfolioBalance;         // nuevos - finalizados (net change)

  // Critical clients (CV) breakdown
  final int clientsAlCorriente;  // Paid this week
  final int clientsWeek1CV;      // 1 week without paying
  final int clientsWeek2CV;      // 2 weeks without paying
  final int clientsWeek3CV;      // 3 weeks without paying
  final int clientsWeek4CV;      // 4 weeks - CRITICAL!
  final int clientsWeek5PlusCV;  // 5+ weeks - VERY CRITICAL!
  final List<CriticalClient> criticalClientsList;

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
    required this.renewedLoansThisWeek,
    required this.finishedLoansThisWeek,
    required this.portfolioBalance,
    required this.clientsAlCorriente,
    required this.clientsWeek1CV,
    required this.clientsWeek2CV,
    required this.clientsWeek3CV,
    required this.clientsWeek4CV,
    required this.clientsWeek5PlusCV,
    required this.criticalClientsList,
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
        renewedLoansThisWeek: 0,
        finishedLoansThisWeek: 0,
        portfolioBalance: 0,
        clientsAlCorriente: 0,
        clientsWeek1CV: 0,
        clientsWeek2CV: 0,
        clientsWeek3CV: 0,
        clientsWeek4CV: 0,
        clientsWeek5PlusCV: 0,
        criticalClientsList: [],
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

  // Minimum loading time for skeleton visibility
  final minLoadingTime = Future.delayed(const Duration(milliseconds: 400));

  final userName = authState.user?.fullName?.split(' ').first ?? 'Usuario';
  final weekStartStr = weekState.weekStart.toIso8601String().split('T')[0];
  final weekEndStr = weekState.weekEnd.toIso8601String().split('T')[0];
  final lastWeekStartStr =
      weekState.weekStart.subtract(const Duration(days: 7)).toIso8601String().split('T')[0];
  final lastWeekEndStr =
      weekState.weekEnd.subtract(const Duration(days: 7)).toIso8601String().split('T')[0];

  try {
    // Build renewal map
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

    // Query all active loans with full details for CV analysis
    final loansResult = await db.execute('''
      SELECT
        l.id,
        l.borrower,
        l.pendingAmountStored,
        l.totalPaid,
        l.totalDebtAcquired,
        l.expectedWeeklyPayment,
        l.signDate,
        l.finishedDate,
        l.renewedDate,
        l.previousLoan,
        l.snapshotRouteName,
        l.snapshotRouteId,
        l.snapshotLeadId,
        b.personalData as personalDataId,
        pd.fullName as clientName,
        pd.clientCode,
        (SELECT phone FROM Phone WHERE personalData = pd.id LIMIT 1) as phone,
        (SELECT name FROM Route WHERE id = l.snapshotRouteId LIMIT 1) as routeNameFromTable,
        (SELECT loc.name
         FROM Employee emp
         JOIN Address a ON a.personalData = emp.personalData
         JOIN Location loc ON a.location = loc.id
         WHERE emp.id = l.lead OR emp.id = l.snapshotLeadId
         LIMIT 1) as leadLocality
      FROM Loan l
      LEFT JOIN Borrower b ON l.borrower = b.id
      LEFT JOIN PersonalData pd ON b.personalData = pd.id
      WHERE (l.excludedByCleanup IS NULL OR l.excludedByCleanup = '')
        AND l.signDate <= ?
        AND (l.finishedDate IS NULL OR l.finishedDate = '' OR l.finishedDate >= ?)
        AND (l.renewedDate IS NULL OR l.renewedDate = '' OR l.renewedDate >= ?)
        ${selectedRoute != null ? "AND l.snapshotRouteId = '${selectedRoute.id}'" : ''}
    ''', [weekEndStr, weekStartStr, weekStartStr]);

    // Get all payments for analysis
    final paymentsResult = await db.execute('''
      SELECT loan, receivedAt, amount
      FROM LoanPayment
      ORDER BY receivedAt DESC
    ''');

    // Build payments map per loan
    final paymentsMap = <String, List<Map<String, dynamic>>>{};
    for (final row in paymentsResult) {
      final loanId = row['loan'] as String?;
      if (loanId != null) {
        paymentsMap.putIfAbsent(loanId, () => []);
        paymentsMap[loanId]!.add(row);
      }
    }

    // Process loans
    int activeLoansCount = 0;
    double totalPendingDebt = 0;
    double totalCollected = 0;
    double expectedWeeklyTotal = 0;

    int clientsAlCorriente = 0;
    int clientsWeek1CV = 0;
    int clientsWeek2CV = 0;
    int clientsWeek3CV = 0;
    int clientsWeek4CV = 0;
    int clientsWeek5PlusCV = 0;
    final criticalClientsList = <CriticalClient>[];

    final paidLoansThisWeek = <String>{};

    for (final row in loansResult) {
      final loanId = row['id'] as String?;
      final finishedDateStr = row['finishedDate'] as String?;
      final renewedDateStr = row['renewedDate'] as String?;
      final previousLoan = row['previousLoan'] as String?;
      final totalPaid = (row['totalPaid'] as num?)?.toDouble() ?? 0;
      final totalDebt = (row['totalDebtAcquired'] as num?)?.toDouble() ?? 0;
      final pendingStored = (row['pendingAmountStored'] as num?)?.toDouble() ?? 0;
      final signDateStr = row['signDate'] as String?;
      final expectedWeekly = (row['expectedWeeklyPayment'] as num?)?.toDouble() ?? 0;

      // Check if still active at week end
      final finishedAfterWeekEnd = finishedDateStr == null || finishedDateStr.isEmpty || finishedDateStr.compareTo(weekEndStr) > 0;
      final renewedAfterWeekEnd = renewedDateStr == null || renewedDateStr.isEmpty || renewedDateStr.compareTo(weekEndStr) > 0;
      final stillActiveAtWeekEnd = finishedAfterWeekEnd && renewedAfterWeekEnd;

      // Calculate real pending amount
      final realPendingAmount = totalDebt > 0 ? (totalDebt - totalPaid) : pendingStored;

      // Check renewal
      final hasNewerRenewal = (previousLoan != null && previousLoan.isNotEmpty)
          ? renewedLoanIds.contains(loanId)
          : false;

      if (loanId == null || !stillActiveAtWeekEnd || realPendingAmount <= 0 || hasNewerRenewal) {
        continue;
      }

      activeLoansCount++;
      totalPendingDebt += pendingStored;
      totalCollected += totalPaid;
      expectedWeeklyTotal += expectedWeekly;

      // Calculate weeks without payment
      final loanPayments = paymentsMap[loanId] ?? [];

      // Check if paid this week
      bool paidThisWeek = false;
      DateTime? lastPaymentDate;

      for (final payment in loanPayments) {
        final receivedAt = payment['receivedAt'] as String?;
        if (receivedAt != null) {
          final paymentDate = receivedAt.split('T')[0];
          if (lastPaymentDate == null) {
            lastPaymentDate = DateTime.tryParse(receivedAt);
          }
          if (paymentDate.compareTo(weekStartStr) >= 0 && paymentDate.compareTo(weekEndStr) <= 0) {
            paidThisWeek = true;
            paidLoansThisWeek.add(loanId);
            break;
          }
        }
      }

      if (paidThisWeek) {
        clientsAlCorriente++;
      } else {
        // Calculate weeks since last payment or sign date
        final signDate = DateTime.tryParse(signDateStr ?? '');
        final referenceDate = lastPaymentDate ?? signDate;

        if (referenceDate != null) {
          final weeksSincePayment = weekState.weekStart.difference(referenceDate).inDays ~/ 7;

          // Categorize by CV weeks (only count if signed before this week - not in grace period)
          final signedBeforeThisWeek = signDate != null &&
              signDate.isBefore(weekState.weekStart.subtract(const Duration(days: 6)));

          if (signedBeforeThisWeek) {
            // Get route name - prefer snapshotRouteName, fallback to Route table
            final snapshotRouteName = row['snapshotRouteName'] as String?;
            final routeNameFromTable = row['routeNameFromTable'] as String?;
            final effectiveRouteName = (snapshotRouteName != null && snapshotRouteName.isNotEmpty)
                ? snapshotRouteName
                : routeNameFromTable;
            final leadLocality = row['leadLocality'] as String?;

            if (weeksSincePayment >= 5) {
              clientsWeek5PlusCV++;
              // Add to critical list (very critical)
              criticalClientsList.add(CriticalClient(
                loanId: loanId,
                borrowerId: row['borrower'] as String? ?? '',
                clientName: row['clientName'] as String? ?? 'Sin nombre',
                clientCode: row['clientCode'] as String?,
                phone: row['phone'] as String?,
                pendingAmount: pendingStored,
                expectedWeeklyPayment: expectedWeekly,
                weeksWithoutPayment: weeksSincePayment,
                signDate: signDate,
                lastPaymentDate: lastPaymentDate,
                routeName: effectiveRouteName,
                leadLocality: leadLocality,
              ));
            } else if (weeksSincePayment == 4) {
              clientsWeek4CV++;
              // Add to critical list
              criticalClientsList.add(CriticalClient(
                loanId: loanId,
                borrowerId: row['borrower'] as String? ?? '',
                clientName: row['clientName'] as String? ?? 'Sin nombre',
                clientCode: row['clientCode'] as String?,
                phone: row['phone'] as String?,
                pendingAmount: pendingStored,
                expectedWeeklyPayment: expectedWeekly,
                weeksWithoutPayment: weeksSincePayment,
                signDate: signDate,
                lastPaymentDate: lastPaymentDate,
                routeName: effectiveRouteName,
                leadLocality: leadLocality,
              ));
            } else if (weeksSincePayment == 3) {
              clientsWeek3CV++;
            } else if (weeksSincePayment == 2) {
              clientsWeek2CV++;
            } else if (weeksSincePayment == 1) {
              clientsWeek1CV++;
            } else {
              // First week after sign, in grace or just started
              clientsAlCorriente++;
            }
          } else {
            // In grace period (just signed)
            clientsAlCorriente++;
          }
        }
      }
    }

    // Sort critical clients by weeks without payment (most critical first)
    criticalClientsList.sort((a, b) => b.weeksWithoutPayment.compareTo(a.weeksWithoutPayment));

    // Query payments this week (for amount calculation)
    final paymentsThisWeekResult = await db.execute('''
      SELECT lp.loan as loanId, lp.amount
      FROM LoanPayment lp
      INNER JOIN Loan l ON lp.loan = l.id
      WHERE lp.receivedAt >= ? AND lp.receivedAt <= ?
        AND (l.excludedByCleanup IS NULL OR l.excludedByCleanup = '')
        AND (l.finishedDate IS NULL OR l.finishedDate = '')
        AND (l.renewedDate IS NULL OR l.renewedDate = '')
        ${selectedRoute != null ? "AND l.snapshotRouteId = '${selectedRoute.id}'" : ''}
    ''', [weekStartStr, weekEndStr + 'T23:59:59']);

    double collectedAmountThisWeek = 0;
    for (final row in paymentsThisWeekResult) {
      final loanId = row['loanId'] as String?;
      if (loanId != null && !renewedLoanIds.contains(loanId)) {
        collectedAmountThisWeek += (row['amount'] as num?)?.toDouble() ?? 0;
      }
    }
    final collectedPaymentsThisWeek = paidLoansThisWeek.length;

    // Query payments last week
    final paymentsLastWeekResult = await db.execute('''
      SELECT lp.loan as loanId, lp.amount
      FROM LoanPayment lp
      INNER JOIN Loan l ON lp.loan = l.id
      WHERE lp.receivedAt >= ? AND lp.receivedAt <= ?
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

    // Query new loans this week
    final newLoansResult = await db.execute('''
      SELECT COUNT(*) as count, COALESCE(SUM(requestedAmount), 0) as amount
      FROM Loan
      WHERE signDate >= ? AND signDate <= ?
        AND (previousLoan IS NULL OR previousLoan = '')
        ${selectedRoute != null ? "AND snapshotRouteId = '${selectedRoute.id}'" : ''}
    ''', [weekStartStr, weekEndStr]);

    int newLoansThisWeek = 0;
    double newLoansAmountThisWeek = 0;
    if (newLoansResult.isNotEmpty) {
      final row = newLoansResult.first;
      newLoansThisWeek = (row['count'] as num?)?.toInt() ?? 0;
      newLoansAmountThisWeek = (row['amount'] as num?)?.toDouble() ?? 0;
    }

    // Query renewed loans this week (loans that have a previousLoan and were signed this week)
    final renewedLoansWeekResult = await db.execute('''
      SELECT COUNT(*) as count
      FROM Loan
      WHERE signDate >= ? AND signDate <= ?
        AND previousLoan IS NOT NULL AND previousLoan != ''
        ${selectedRoute != null ? "AND snapshotRouteId = '${selectedRoute.id}'" : ''}
    ''', [weekStartStr, weekEndStr]);

    int renewedLoansThisWeek = 0;
    if (renewedLoansWeekResult.isNotEmpty) {
      renewedLoansThisWeek = (renewedLoansWeekResult.first['count'] as num?)?.toInt() ?? 0;
    }

    // Query finished loans this week (loans that have finishedDate in this week)
    final finishedLoansResult = await db.execute('''
      SELECT COUNT(*) as count
      FROM Loan
      WHERE finishedDate >= ? AND finishedDate <= ?
        AND (excludedByCleanup IS NULL OR excludedByCleanup = '')
        ${selectedRoute != null ? "AND snapshotRouteId = '${selectedRoute.id}'" : ''}
    ''', [weekStartStr, weekEndStr + 'T23:59:59']);

    int finishedLoansThisWeek = 0;
    if (finishedLoansResult.isNotEmpty) {
      finishedLoansThisWeek = (finishedLoansResult.first['count'] as num?)?.toInt() ?? 0;
    }

    // Portfolio balance: nuevos - finalizados (net change in active clients)
    final portfolioBalance = newLoansThisWeek - finishedLoansThisWeek;

    // Calculate metrics
    final expectedPaymentsThisWeek = activeLoansCount;
    final missingPaymentsThisWeek = (expectedPaymentsThisWeek - collectedPaymentsThisWeek).clamp(0, expectedPaymentsThisWeek);
    final expectedAmountThisWeek = expectedWeeklyTotal;

    final goalProgress = expectedPaymentsThisWeek > 0
        ? (collectedPaymentsThisWeek / expectedPaymentsThisWeek * 100).clamp(0.0, 100.0)
        : 0.0;

    final comparisonVsLastWeek = collectedPaymentsThisWeek - collectedPaymentsLastWeek;
    final comparisonAmountVsLastWeek = collectedAmountThisWeek - collectedAmountLastWeek;
    final isAheadOfLastWeek = comparisonVsLastWeek >= 0;

    final stats = CollectorDashboardStats(
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
      renewedLoansThisWeek: renewedLoansThisWeek,
      finishedLoansThisWeek: finishedLoansThisWeek,
      portfolioBalance: portfolioBalance,
      clientsAlCorriente: clientsAlCorriente,
      clientsWeek1CV: clientsWeek1CV,
      clientsWeek2CV: clientsWeek2CV,
      clientsWeek3CV: clientsWeek3CV,
      clientsWeek4CV: clientsWeek4CV,
      clientsWeek5PlusCV: clientsWeek5PlusCV,
      criticalClientsList: criticalClientsList,
      userName: userName,
      isOnline: !isSyncing,
    );

    // Ensure minimum loading time for skeleton visibility
    await minLoadingTime;
    return stats;
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
      renewedLoansThisWeek: 0,
      finishedLoansThisWeek: 0,
      portfolioBalance: 0,
      clientsAlCorriente: 0,
      clientsWeek1CV: 0,
      clientsWeek2CV: 0,
      clientsWeek3CV: 0,
      clientsWeek4CV: 0,
      clientsWeek5PlusCV: 0,
      criticalClientsList: [],
      userName: userName,
      isOnline: !isSyncing,
    );
  }
});
