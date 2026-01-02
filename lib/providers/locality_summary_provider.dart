import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'powersync_provider.dart';
import 'collector_dashboard_provider.dart';

/// Summary data for a single locality
class LocalitySummary {
  final String routeId;
  final String routeName;
  final String? leaderName;

  // Payments
  final int paymentCount;
  final double totalPayments;
  final double cashPayments;
  final double bankPayments;

  // Credits
  final int loansGrantedCount;
  final double totalLoansGranted;
  final int renewalsCount;

  // Expenses
  final int expenseCount;
  final double totalExpenses;

  // Commissions
  final double totalCommissions;

  // Balances
  final double balanceEfectivo;
  final double balanceBanco;

  const LocalitySummary({
    required this.routeId,
    required this.routeName,
    this.leaderName,
    required this.paymentCount,
    required this.totalPayments,
    required this.cashPayments,
    required this.bankPayments,
    required this.loansGrantedCount,
    required this.totalLoansGranted,
    required this.renewalsCount,
    required this.expenseCount,
    required this.totalExpenses,
    required this.totalCommissions,
    required this.balanceEfectivo,
    required this.balanceBanco,
  });

  double get totalBalance => balanceEfectivo + balanceBanco;

  bool get hasActivity => paymentCount > 0 || loansGrantedCount > 0 || expenseCount > 0;
}

/// Executive summary for all localities
class ExecutiveSummary {
  final double totalPaymentsReceived;
  final double totalCashPayments;
  final double totalBankPayments;
  final double totalCommissions;
  final double totalExpenses;
  final double totalLoansGranted;
  final int paymentCount;
  final int expenseCount;
  final int loansGrantedCount;
  final double netBalance;

  const ExecutiveSummary({
    required this.totalPaymentsReceived,
    required this.totalCashPayments,
    required this.totalBankPayments,
    required this.totalCommissions,
    required this.totalExpenses,
    required this.totalLoansGranted,
    required this.paymentCount,
    required this.expenseCount,
    required this.loansGrantedCount,
    required this.netBalance,
  });

  factory ExecutiveSummary.empty() => const ExecutiveSummary(
    totalPaymentsReceived: 0,
    totalCashPayments: 0,
    totalBankPayments: 0,
    totalCommissions: 0,
    totalExpenses: 0,
    totalLoansGranted: 0,
    paymentCount: 0,
    expenseCount: 0,
    loansGrantedCount: 0,
    netBalance: 0,
  );
}

/// All localities summary data
class AllLocalitiesSummary {
  final List<LocalitySummary> localities;
  final ExecutiveSummary executive;

  const AllLocalitiesSummary({
    required this.localities,
    required this.executive,
  });

  factory AllLocalitiesSummary.empty() => AllLocalitiesSummary(
    localities: const [],
    executive: ExecutiveSummary.empty(),
  );
}

/// Provider for all localities summary (today's data)
final allLocalitiesSummaryProvider = FutureProvider<AllLocalitiesSummary>((ref) async {
  final dbAsync = ref.watch(powerSyncDatabaseProvider);
  final db = dbAsync.valueOrNull;
  if (db == null) return AllLocalitiesSummary.empty();

  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
  final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

  try {
    // Get all routes
    final routesResult = await db.execute('''
      SELECT id, name FROM Route ORDER BY name
    ''');

    final localities = <LocalitySummary>[];
    double totalPaymentsAll = 0;
    double totalCashAll = 0;
    double totalBankAll = 0;
    double totalCommissionsAll = 0;
    double totalExpensesAll = 0;
    double totalLoansGrantedAll = 0;
    int totalPaymentCount = 0;
    int totalExpenseCount = 0;
    int totalLoansCount = 0;

    for (final route in routesResult) {
      final routeId = route['id'] as String;
      final routeName = route['name'] as String;

      // Get payments for this route today
      final paymentsResult = await db.execute('''
        SELECT
          COUNT(*) as count,
          COALESCE(SUM(lp.amount), 0) as totalAmount,
          COALESCE(SUM(CASE WHEN lp.paymentMethod = 'CASH' THEN lp.amount ELSE 0 END), 0) as cashAmount,
          COALESCE(SUM(CASE WHEN lp.paymentMethod = 'MONEY_TRANSFER' THEN lp.amount ELSE 0 END), 0) as bankAmount,
          COALESCE(SUM(lp.comissionAmount), 0) as commissions
        FROM LoanPayment lp
        JOIN Loan l ON lp.loan = l.id
        WHERE lp.receivedAt >= ? AND lp.receivedAt <= ?
          AND l.snapshotRouteId = ?
      ''', [startOfDay, endOfDay, routeId]);

      int paymentCount = 0;
      double totalPayments = 0;
      double cashPayments = 0;
      double bankPayments = 0;
      double paymentCommissions = 0;

      if (paymentsResult.isNotEmpty) {
        final row = paymentsResult.first;
        paymentCount = (row['count'] as num?)?.toInt() ?? 0;
        totalPayments = (row['totalAmount'] as num?)?.toDouble() ?? 0;
        cashPayments = (row['cashAmount'] as num?)?.toDouble() ?? 0;
        bankPayments = (row['bankAmount'] as num?)?.toDouble() ?? 0;
        paymentCommissions = (row['commissions'] as num?)?.toDouble() ?? 0;
      }

      // Get loans granted for this route today
      final loansResult = await db.execute('''
        SELECT
          COUNT(*) as count,
          COALESCE(SUM(amountGived), 0) as totalAmount,
          COALESCE(SUM(comissionAmount), 0) as commissions,
          COALESCE(SUM(CASE WHEN previousLoan IS NOT NULL AND previousLoan != '' THEN 1 ELSE 0 END), 0) as renewals
        FROM Loan
        WHERE signDate >= ? AND signDate <= ?
          AND snapshotRouteId = ?
          AND status != 'CANCELLED'
      ''', [startOfDay, endOfDay, routeId]);

      int loansGrantedCount = 0;
      double totalLoansGranted = 0;
      double loanCommissions = 0;
      int renewalsCount = 0;

      if (loansResult.isNotEmpty) {
        final row = loansResult.first;
        loansGrantedCount = (row['count'] as num?)?.toInt() ?? 0;
        totalLoansGranted = (row['totalAmount'] as num?)?.toDouble() ?? 0;
        loanCommissions = (row['commissions'] as num?)?.toDouble() ?? 0;
        renewalsCount = (row['renewals'] as num?)?.toInt() ?? 0;
      }

      // Get expenses for this route today
      final expensesResult = await db.execute('''
        SELECT
          COUNT(*) as count,
          COALESCE(SUM(ae.amount), 0) as totalAmount
        FROM AccountEntry ae
        JOIN Account a ON ae.account = a.id
        WHERE ae.entryDate >= ? AND ae.entryDate <= ?
          AND ae.entryType = 'DEBIT'
          AND ae.sourceType IN ('EXPENSE_FUEL', 'EXPENSE_FOOD', 'EXPENSE_OTHER', 'EXPENSE_MOBILE', 'EXPENSE_VEHICLE')
          AND a.route = ?
      ''', [startOfDay, endOfDay, routeId]);

      int expenseCount = 0;
      double totalExpenses = 0;

      if (expensesResult.isNotEmpty) {
        final row = expensesResult.first;
        expenseCount = (row['count'] as num?)?.toInt() ?? 0;
        totalExpenses = (row['totalAmount'] as num?)?.toDouble() ?? 0;
      }

      final totalCommissions = paymentCommissions + loanCommissions;

      // Calculate balances
      // Balance Efectivo = Cash Payments - Commissions - Loans Granted - Expenses
      final balanceEfectivo = cashPayments - totalCommissions - totalLoansGranted - totalExpenses;
      // Balance Banco = Bank Payments
      final balanceBanco = bankPayments;

      // Only add localities with activity
      if (paymentCount > 0 || loansGrantedCount > 0 || expenseCount > 0) {
        localities.add(LocalitySummary(
          routeId: routeId,
          routeName: routeName,
          paymentCount: paymentCount,
          totalPayments: totalPayments,
          cashPayments: cashPayments,
          bankPayments: bankPayments,
          loansGrantedCount: loansGrantedCount,
          totalLoansGranted: totalLoansGranted,
          renewalsCount: renewalsCount,
          expenseCount: expenseCount,
          totalExpenses: totalExpenses,
          totalCommissions: totalCommissions,
          balanceEfectivo: balanceEfectivo,
          balanceBanco: balanceBanco,
        ));

        // Accumulate totals
        totalPaymentsAll += totalPayments;
        totalCashAll += cashPayments;
        totalBankAll += bankPayments;
        totalCommissionsAll += totalCommissions;
        totalExpensesAll += totalExpenses;
        totalLoansGrantedAll += totalLoansGranted;
        totalPaymentCount += paymentCount;
        totalExpenseCount += expenseCount;
        totalLoansCount += loansGrantedCount;
      }
    }

    // Sort localities by total payments (most active first)
    localities.sort((a, b) => b.totalPayments.compareTo(a.totalPayments));

    // Net balance = payments - commissions - expenses - loans granted
    final netBalance = totalPaymentsAll - totalCommissionsAll - totalExpensesAll - totalLoansGrantedAll;

    return AllLocalitiesSummary(
      localities: localities,
      executive: ExecutiveSummary(
        totalPaymentsReceived: totalPaymentsAll,
        totalCashPayments: totalCashAll,
        totalBankPayments: totalBankAll,
        totalCommissions: totalCommissionsAll,
        totalExpenses: totalExpensesAll,
        totalLoansGranted: totalLoansGrantedAll,
        paymentCount: totalPaymentCount,
        expenseCount: totalExpenseCount,
        loansGrantedCount: totalLoansCount,
        netBalance: netBalance,
      ),
    );
  } catch (e) {
    return AllLocalitiesSummary.empty();
  }
});
