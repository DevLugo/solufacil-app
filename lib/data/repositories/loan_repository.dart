import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';
import '../models/loan.dart';

/// Input for creating a new loan
class CreateLoanInput {
  final String borrowerId;
  final String loantypeId;
  final double requestedAmount;
  final double amountGived;
  final double profitAmount;
  final double totalDebtAcquired;
  final double expectedWeeklyPayment;
  final double comissionAmount;
  final String leadId;
  final String routeId;
  final String routeName;
  final String? previousLoanId;
  final List<String> collateralIds;

  const CreateLoanInput({
    required this.borrowerId,
    required this.loantypeId,
    required this.requestedAmount,
    required this.amountGived,
    required this.profitAmount,
    required this.totalDebtAcquired,
    required this.expectedWeeklyPayment,
    this.comissionAmount = 0,
    required this.leadId,
    required this.routeId,
    required this.routeName,
    this.previousLoanId,
    this.collateralIds = const [],
  });
}

/// Repository for Loan CRUD operations using PowerSync
class LoanRepository {
  final PowerSyncDatabase _db;
  final _uuid = const Uuid();

  LoanRepository(this._db);

  /// Create a new loan locally (offline-first)
  ///
  /// This will be synced to the backend when online.
  Future<String> createLoan(CreateLoanInput input) async {
    final loanId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.execute('''
      INSERT INTO Loan (
        id, requestedAmount, amountGived, signDate,
        profitAmount, totalDebtAcquired, expectedWeeklyPayment,
        pendingAmountStored, totalPaid, comissionAmount, status,
        borrower, loantype, lead, previousLoan,
        snapshotLeadId, snapshotRouteId, snapshotRouteName,
        createdAt, updatedAt
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, 'ACTIVE', ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      loanId,
      input.requestedAmount,
      input.amountGived,
      now,
      input.profitAmount,
      input.totalDebtAcquired,
      input.expectedWeeklyPayment,
      input.totalDebtAcquired, // pendingAmountStored = totalDebt initially
      input.comissionAmount,
      input.borrowerId,
      input.loantypeId,
      input.leadId,
      input.previousLoanId,
      input.leadId,
      input.routeId,
      input.routeName,
      now,
      now,
    ]);

    // Add collaterals if any
    for (final collateralId in input.collateralIds) {
      await _db.execute('''
        INSERT INTO "_LoanCollaterals" (A, B) VALUES (?, ?)
      ''', [loanId, collateralId]);
    }

    // If renewal, mark previous loan as FINISHED
    if (input.previousLoanId != null) {
      await _db.execute('''
        UPDATE Loan
        SET status = 'FINISHED', renewedDate = ?, finishedDate = ?, updatedAt = ?
        WHERE id = ?
      ''', [now, now, now, input.previousLoanId]);
    }

    return loanId;
  }

  /// Get active loan for a borrower (for renewal detection)
  Future<Loan?> getActiveLoanForBorrower(String borrowerId) async {
    final results = await _db.execute('''
      SELECT
        l.*,
        lt.weekDuration,
        lt.rate,
        lt.loanPaymentComission,
        pd.fullName as borrowerName
      FROM Loan l
      JOIN Borrower b ON l.borrower = b.id
      JOIN PersonalData pd ON b.personalData = pd.id
      LEFT JOIN Loantype lt ON l.loantype = lt.id
      WHERE l.borrower = ? AND l.status = 'ACTIVE'
      ORDER BY l.signDate DESC
      LIMIT 1
    ''', [borrowerId]);

    if (results.isEmpty) return null;

    final row = results.first;
    final payments = await _getPaymentsForLoan(row['id'] as String);

    return Loan.fromRow(
      row,
      borrowerName: row['borrowerName'] as String?,
      payments: payments,
      weekDuration: row['weekDuration'] as int?,
      rate: (row['rate'] as num?)?.toDouble(),
      loanPaymentComission: (row['loanPaymentComission'] as num?)?.toDouble(),
    );
  }

  /// Get active loan by borrower's PersonalData ID
  Future<Loan?> getActiveLoanByPersonalDataId(String personalDataId) async {
    final results = await _db.execute('''
      SELECT
        l.*,
        lt.weekDuration,
        lt.rate,
        lt.loanPaymentComission,
        pd.fullName as borrowerName
      FROM Loan l
      JOIN Borrower b ON l.borrower = b.id
      JOIN PersonalData pd ON b.personalData = pd.id
      LEFT JOIN Loantype lt ON l.loantype = lt.id
      WHERE b.personalData = ? AND l.status = 'ACTIVE'
      ORDER BY l.signDate DESC
      LIMIT 1
    ''', [personalDataId]);

    if (results.isEmpty) return null;

    final row = results.first;
    final payments = await _getPaymentsForLoan(row['id'] as String);

    return Loan.fromRow(
      row,
      borrowerName: row['borrowerName'] as String?,
      payments: payments,
      weekDuration: row['weekDuration'] as int?,
      rate: (row['rate'] as num?)?.toDouble(),
      loanPaymentComission: (row['loanPaymentComission'] as num?)?.toDouble(),
    );
  }

  /// Get loans created today for a specific lead/route
  Future<List<Loan>> getLoansCreatedToday(String leadId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

    final results = await _db.execute('''
      SELECT
        l.*,
        lt.weekDuration,
        lt.rate,
        lt.loanPaymentComission,
        lt.name as loantypeName,
        pd.fullName as borrowerName,
        (SELECT pd2.fullName FROM Employee e
         JOIN PersonalData pd2 ON e.personalData = pd2.id
         WHERE e.id = l.lead) as leadName
      FROM Loan l
      JOIN Borrower b ON l.borrower = b.id
      JOIN PersonalData pd ON b.personalData = pd.id
      LEFT JOIN Loantype lt ON l.loantype = lt.id
      WHERE l.lead = ?
        AND l.signDate >= ?
        AND l.signDate <= ?
        AND l.status != 'CANCELLED'
      ORDER BY l.createdAt DESC
    ''', [leadId, startOfDay, endOfDay]);

    final loans = <Loan>[];
    for (final row in results) {
      final payments = await _getPaymentsForLoan(row['id'] as String);
      final collateralNames = await _getCollateralNames(row['id'] as String);

      loans.add(Loan.fromRow(
        row,
        borrowerName: row['borrowerName'] as String?,
        leadName: row['leadName'] as String?,
        collateralNames: collateralNames,
        payments: payments,
        weekDuration: row['weekDuration'] as int?,
        rate: (row['rate'] as num?)?.toDouble(),
        loanPaymentComission: (row['loanPaymentComission'] as num?)?.toDouble(),
      ));
    }

    return loans;
  }

  /// Get loan by ID with full details
  Future<Loan?> getLoanById(String loanId) async {
    final results = await _db.execute('''
      SELECT
        l.*,
        lt.weekDuration,
        lt.rate,
        lt.loanPaymentComission,
        pd.fullName as borrowerName,
        (SELECT pd2.fullName FROM Employee e
         JOIN PersonalData pd2 ON e.personalData = pd2.id
         WHERE e.id = l.lead) as leadName
      FROM Loan l
      JOIN Borrower b ON l.borrower = b.id
      JOIN PersonalData pd ON b.personalData = pd.id
      LEFT JOIN Loantype lt ON l.loantype = lt.id
      WHERE l.id = ?
    ''', [loanId]);

    if (results.isEmpty) return null;

    final row = results.first;
    final payments = await _getPaymentsForLoan(loanId);
    final collateralNames = await _getCollateralNames(loanId);

    return Loan.fromRow(
      row,
      borrowerName: row['borrowerName'] as String?,
      leadName: row['leadName'] as String?,
      collateralNames: collateralNames,
      payments: payments,
      weekDuration: row['weekDuration'] as int?,
      rate: (row['rate'] as num?)?.toDouble(),
      loanPaymentComission: (row['loanPaymentComission'] as num?)?.toDouble(),
    );
  }

  /// Check if a loan has already been renewed
  Future<bool> isLoanAlreadyRenewed(String loanId) async {
    final results = await _db.execute('''
      SELECT id FROM Loan WHERE previousLoan = ?
    ''', [loanId]);

    return results.isNotEmpty;
  }

  /// Update loan's pending amount after payment
  Future<void> updatePendingAmount(String loanId, double paymentAmount) async {
    final now = DateTime.now().toIso8601String();

    await _db.execute('''
      UPDATE Loan
      SET
        totalPaid = totalPaid + ?,
        pendingAmountStored = pendingAmountStored - ?,
        updatedAt = ?
      WHERE id = ?
    ''', [paymentAmount, paymentAmount, now, loanId]);

    // Check if fully paid and update status
    final results = await _db.execute('''
      SELECT pendingAmountStored FROM Loan WHERE id = ?
    ''', [loanId]);

    if (results.isNotEmpty) {
      final pending = (results.first['pendingAmountStored'] as num?)?.toDouble() ?? 0;
      if (pending <= 0) {
        await _db.execute('''
          UPDATE Loan
          SET status = 'FINISHED', finishedDate = ?, updatedAt = ?
          WHERE id = ?
        ''', [now, now, loanId]);
      }
    }
  }

  /// Cancel a loan
  Future<void> cancelLoan(String loanId) async {
    final now = DateTime.now().toIso8601String();

    await _db.execute('''
      UPDATE Loan
      SET status = 'CANCELLED', updatedAt = ?
      WHERE id = ?
    ''', [now, loanId]);
  }

  /// Get summary stats for loans created today
  Future<LoanDaySummary> getDaySummary(String leadId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

    final results = await _db.execute('''
      SELECT
        COUNT(*) as totalLoans,
        COALESCE(SUM(amountGived), 0) as totalAmountGiven,
        COALESCE(SUM(comissionAmount), 0) as totalCommission,
        COALESCE(SUM(CASE WHEN previousLoan IS NOT NULL THEN 1 ELSE 0 END), 0) as renewalCount,
        COALESCE(SUM(CASE WHEN previousLoan IS NULL THEN 1 ELSE 0 END), 0) as newLoanCount
      FROM Loan
      WHERE lead = ?
        AND signDate >= ?
        AND signDate <= ?
        AND status != 'CANCELLED'
    ''', [leadId, startOfDay, endOfDay]);

    if (results.isEmpty) {
      return const LoanDaySummary.empty();
    }

    final row = results.first;
    return LoanDaySummary(
      totalLoans: (row['totalLoans'] as int?) ?? 0,
      totalAmountGiven: (row['totalAmountGiven'] as num?)?.toDouble() ?? 0,
      totalCommission: (row['totalCommission'] as num?)?.toDouble() ?? 0,
      renewalCount: (row['renewalCount'] as int?) ?? 0,
      newLoanCount: (row['newLoanCount'] as int?) ?? 0,
    );
  }

  /// Get payments for a loan
  Future<List<LoanPayment>> _getPaymentsForLoan(String loanId) async {
    final results = await _db.execute('''
      SELECT * FROM LoanPayment
      WHERE loan = ?
      ORDER BY receivedAt ASC
    ''', [loanId]);

    return results.map((r) => LoanPayment.fromRow(r)).toList();
  }

  /// Get collateral names for a loan
  Future<List<String>> _getCollateralNames(String loanId) async {
    final results = await _db.execute('''
      SELECT pd.fullName
      FROM "_LoanCollaterals" lc
      JOIN PersonalData pd ON lc.B = pd.id
      WHERE lc.A = ?
    ''', [loanId]);

    return results.map((r) => r['fullName'] as String).toList();
  }
}

/// Summary of loans created in a day
class LoanDaySummary {
  final int totalLoans;
  final double totalAmountGiven;
  final double totalCommission;
  final int renewalCount;
  final int newLoanCount;

  const LoanDaySummary({
    required this.totalLoans,
    required this.totalAmountGiven,
    required this.totalCommission,
    required this.renewalCount,
    required this.newLoanCount,
  });

  const LoanDaySummary.empty()
      : totalLoans = 0,
        totalAmountGiven = 0,
        totalCommission = 0,
        renewalCount = 0,
        newLoanCount = 0;
}
