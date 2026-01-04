import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';
import '../models/loan.dart';
import '../models/payment_input.dart';

/// SQL query constants
const _insertPaymentQuery = '''
  INSERT INTO LoanPayment (
    id, loan, amount, comission, type, paymentMethod, receivedAt, createdAt
  ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
''';

const _getPaymentsForLoanQuery = '''
  SELECT * FROM LoanPayment
  WHERE loan = ?
  ORDER BY receivedAt DESC
''';

const _getPaymentsByDateAndLeadQuery = '''
  SELECT lp.*
  FROM LoanPayment lp
  INNER JOIN Loan l ON lp.loan = l.id
  WHERE l.lead = ? OR l.snapshotLeadId = ?
    AND lp.receivedAt >= ?
    AND lp.receivedAt <= ?
  ORDER BY lp.receivedAt DESC
''';

const _updateLoanAfterPaymentQuery = '''
  UPDATE Loan
  SET
    totalPaid = totalPaid + ?,
    pendingAmountStored = pendingAmountStored - ?,
    updatedAt = ?
  WHERE id = ?
''';

const _getLoanPendingQuery = '''
  SELECT pendingAmountStored FROM Loan WHERE id = ?
''';

const _markLoanFinishedQuery = '''
  UPDATE Loan
  SET status = 'FINISHED', finishedDate = ?, updatedAt = ?
  WHERE id = ?
''';

/// Repository for Payment CRUD operations using PowerSync
class PaymentRepository {
  final PowerSyncDatabase _db;
  final _uuid = const Uuid();

  PaymentRepository(this._db);

  /// Create a new payment locally (offline-first)
  Future<String> createPayment(CreatePaymentInput input) async {
    final paymentId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.execute(_insertPaymentQuery, [
      paymentId,
      input.loanId,
      input.amount,
      input.comission,
      input.type,
      _paymentMethodToString(input.paymentMethod),
      input.receivedAt.toIso8601String(),
      now,
    ]);

    await _updateLoanAfterPayment(input.loanId, input.amount);
    return paymentId;
  }

  String _paymentMethodToString(PaymentMethod method) {
    return method == PaymentMethod.cash ? 'CASH' : 'MONEY_TRANSFER';
  }

  /// Get payments for a specific loan
  Future<List<LoanPayment>> getPaymentsForLoan(String loanId) async {
    final results = await _db.execute(_getPaymentsForLoanQuery, [loanId]);
    return results.map((r) => LoanPayment.fromRow(r)).toList();
  }

  /// Get payments for a date range and lead
  Future<List<LoanPayment>> getPaymentsByDateAndLead(
    String leadId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final results = await _db.execute(_getPaymentsByDateAndLeadQuery, [
      leadId,
      leadId,
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);

    return results.map((r) => LoanPayment.fromRow(r)).toList();
  }

  /// Get today's payments for a lead
  Future<List<LoanPayment>> getTodayPaymentsForLead(String leadId) async {
    final (startOfDay, endOfDay) = _getTodayRange();
    return getPaymentsByDateAndLead(leadId, startOfDay, endOfDay);
  }

  (DateTime, DateTime) _getTodayRange() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    return (startOfDay, endOfDay);
  }

  /// Save all payments for a day (batch operation)
  /// Returns list of created payment IDs
  Future<List<String>> saveDayPayments(DayPaymentState dayState) async {
    final paymentIds = <String>[];

    for (final entry in dayState.payments) {
      if (entry.isNoPayment) continue;

      final id = await _createPaymentFromEntry(entry, dayState.date);
      paymentIds.add(id);
    }

    return paymentIds;
  }

  Future<String> _createPaymentFromEntry(
    PaymentEntry entry,
    DateTime receivedAt,
  ) async {
    final input = CreatePaymentInput(
      loanId: entry.loanId,
      amount: entry.amount,
      comission: entry.comission,
      paymentMethod: entry.paymentMethod,
      receivedAt: receivedAt,
    );

    return createPayment(input);
  }

  /// Get collection summary for a locality on a specific date
  Future<CollectionDaySummary> getCollectionSummary(
    String leadId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final startStr = startOfDay.toIso8601String();
    final endStr = endOfDay.toIso8601String();

    // Get payments made today
    final paymentsResult = await _db.execute('''
      SELECT
        lp.paymentMethod,
        SUM(lp.amount) as totalAmount,
        SUM(lp.comission) as totalComission,
        COUNT(*) as paymentCount
      FROM LoanPayment lp
      INNER JOIN Loan l ON lp.loan = l.id
      WHERE (l.lead = ? OR l.snapshotLeadId = ?)
        AND lp.receivedAt >= ?
        AND lp.receivedAt <= ?
      GROUP BY lp.paymentMethod
    ''', [leadId, leadId, startStr, endStr]);

    double totalCash = 0;
    double totalBank = 0;
    double totalComission = 0;
    int paymentCount = 0;

    for (final row in paymentsResult) {
      final method = row['paymentMethod'] as String?;
      final amount = (row['totalAmount'] as num?)?.toDouble() ?? 0;
      final comission = (row['totalComission'] as num?)?.toDouble() ?? 0;
      final count = (row['paymentCount'] as int?) ?? 0;

      if (method == 'CASH') {
        totalCash = amount;
      } else if (method == 'MONEY_TRANSFER') {
        totalBank = amount;
      }
      totalComission += comission;
      paymentCount += count;
    }

    // Get expected amount for active loans
    final expectedResult = await _db.execute('''
      SELECT
        COUNT(*) as loanCount,
        SUM(expectedWeeklyPayment) as expectedAmount
      FROM Loan
      WHERE (lead = ? OR snapshotLeadId = ?)
        AND status = 'ACTIVE'
    ''', [leadId, leadId]);

    double expectedAmount = 0;
    int activeLoans = 0;

    if (expectedResult.isNotEmpty) {
      expectedAmount =
          (expectedResult.first['expectedAmount'] as num?)?.toDouble() ?? 0;
      activeLoans = (expectedResult.first['loanCount'] as int?) ?? 0;
    }

    return CollectionDaySummary(
      date: date,
      totalCash: totalCash,
      totalBank: totalBank,
      totalCollected: totalCash + totalBank,
      totalComission: totalComission,
      paymentCount: paymentCount,
      expectedAmount: expectedAmount,
      activeLoans: activeLoans,
    );
  }

  /// Update loan after payment
  Future<void> _updateLoanAfterPayment(String loanId, double amount) async {
    final now = DateTime.now().toIso8601String();

    await _db.execute(_updateLoanAfterPaymentQuery, [
      amount,
      amount,
      now,
      loanId,
    ]);

    await _markLoanAsFinishedIfFullyPaid(loanId, now);
  }

  Future<void> _markLoanAsFinishedIfFullyPaid(
    String loanId,
    String timestamp,
  ) async {
    final result = await _db.execute(_getLoanPendingQuery, [loanId]);

    if (result.isEmpty) return;

    final pending = (result.first['pendingAmountStored'] as num?)?.toDouble() ?? 0;
    if (pending <= 0) {
      await _db.execute(_markLoanFinishedQuery, [timestamp, timestamp, loanId]);
    }
  }
}

/// Summary of collections for a day
class CollectionDaySummary {
  final DateTime date;
  final double totalCash;
  final double totalBank;
  final double totalCollected;
  final double totalComission;
  final int paymentCount;
  final double expectedAmount;
  final int activeLoans;

  const CollectionDaySummary({
    required this.date,
    required this.totalCash,
    required this.totalBank,
    required this.totalCollected,
    required this.totalComission,
    required this.paymentCount,
    required this.expectedAmount,
    required this.activeLoans,
  });

  double get pendingAmount => expectedAmount - totalCollected;

  double get progressPercent {
    if (expectedAmount == 0) return 0;
    return (totalCollected / expectedAmount * 100).clamp(0, 100);
  }

  int get pendingLoans => activeLoans - paymentCount;
}
