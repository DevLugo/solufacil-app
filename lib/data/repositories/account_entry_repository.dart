import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

/// Types of account entry sources
enum EntrySourceType {
  loanGrant('LOAN_GRANT'),
  loanGrantCommission('LOAN_GRANT_COMMISSION'),
  loanPaymentCash('LOAN_PAYMENT_CASH'),
  loanPaymentBank('LOAN_PAYMENT_BANK'),
  paymentCommission('PAYMENT_COMMISSION'),
  transfer('TRANSFER'),
  adjustment('ADJUSTMENT');

  final String value;
  const EntrySourceType(this.value);
}

/// Types of account entries
enum EntryType {
  credit('CREDIT'),
  debit('DEBIT');

  final String value;
  const EntryType(this.value);
}

/// Input for creating an account entry
class CreateAccountEntryInput {
  final String accountId;
  final EntryType entryType;
  final double amount;
  final EntrySourceType sourceType;
  final DateTime entryDate;
  final String? loanId;
  final String? loanPaymentId;
  final String? leadPaymentReceivedId;
  final String? description;
  final String? leadId;
  final String? routeId;
  final double? profitAmount;
  final double? returnToCapital;

  const CreateAccountEntryInput({
    required this.accountId,
    required this.entryType,
    required this.amount,
    required this.sourceType,
    required this.entryDate,
    this.loanId,
    this.loanPaymentId,
    this.leadPaymentReceivedId,
    this.description,
    this.leadId,
    this.routeId,
    this.profitAmount,
    this.returnToCapital,
  });
}

/// Account Entry model
class AccountEntry {
  final String id;
  final String accountId;
  final double amount;
  final String entryType;
  final String sourceType;
  final double? profitAmount;
  final double? returnToCapital;
  final String? loanId;
  final String? loanPaymentId;
  final DateTime entryDate;
  final DateTime createdAt;

  const AccountEntry({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.entryType,
    required this.sourceType,
    this.profitAmount,
    this.returnToCapital,
    this.loanId,
    this.loanPaymentId,
    required this.entryDate,
    required this.createdAt,
  });

  factory AccountEntry.fromRow(Map<String, dynamic> row) {
    return AccountEntry(
      id: row['id'] as String,
      accountId: row['accountId'] as String,
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      entryType: row['entryType'] as String? ?? 'DEBIT',
      sourceType: row['sourceType'] as String? ?? 'ADJUSTMENT',
      profitAmount: (row['profitAmount'] as num?)?.toDouble(),
      returnToCapital: (row['returnToCapital'] as num?)?.toDouble(),
      loanId: row['loanId'] as String?,
      loanPaymentId: row['loanPaymentId'] as String?,
      entryDate: DateTime.parse(row['entryDate'] as String),
      createdAt: DateTime.parse(row['createdAt'] as String),
    );
  }
}

/// Repository for AccountEntry operations using PowerSync (ledger-based accounting)
class AccountEntryRepository {
  final PowerSyncDatabase _db;
  final _uuid = const Uuid();

  AccountEntryRepository(this._db);

  /// Create an account entry (offline-first)
  ///
  /// This creates a ledger entry that will be synced to the backend.
  /// The backend will update the Account.amount based on these entries.
  Future<String> createEntry(CreateAccountEntryInput input) async {
    final entryId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.execute('''
      INSERT INTO AccountEntry (
        id, accountId, amount, entryType, sourceType,
        profitAmount, returnToCapital,
        snapshotLeadId, snapshotRouteId,
        entryDate, description,
        loanId, loanPaymentId, leadPaymentReceivedId,
        createdAt
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      entryId,
      input.accountId,
      input.amount,
      input.entryType.value,
      input.sourceType.value,
      input.profitAmount,
      input.returnToCapital,
      input.leadId,
      input.routeId,
      input.entryDate.toIso8601String(),
      input.description,
      input.loanId,
      input.loanPaymentId,
      input.leadPaymentReceivedId,
      now,
    ]);

    return entryId;
  }

  /// Create a DEBIT entry for loan grant (money leaving the account)
  Future<String> createLoanGrantEntry({
    required String accountId,
    required double amountGived,
    required String loanId,
    required DateTime entryDate,
    required String? leadId,
    required String? routeId,
  }) async {
    return createEntry(CreateAccountEntryInput(
      accountId: accountId,
      entryType: EntryType.debit,
      amount: amountGived,
      sourceType: EntrySourceType.loanGrant,
      entryDate: entryDate,
      loanId: loanId,
      leadId: leadId,
      routeId: routeId,
      description: 'Crédito otorgado',
    ));
  }

  /// Create a DEBIT entry for loan grant commission
  Future<String> createLoanCommissionEntry({
    required String accountId,
    required double commissionAmount,
    required String loanId,
    required DateTime entryDate,
    required String? leadId,
    required String? routeId,
  }) async {
    return createEntry(CreateAccountEntryInput(
      accountId: accountId,
      entryType: EntryType.debit,
      amount: commissionAmount,
      sourceType: EntrySourceType.loanGrantCommission,
      entryDate: entryDate,
      loanId: loanId,
      leadId: leadId,
      routeId: routeId,
      description: 'Comisión por crédito',
    ));
  }

  /// Create a CREDIT entry for loan payment (money entering the account)
  Future<String> createPaymentEntry({
    required String accountId,
    required double paymentAmount,
    required String loanId,
    required String loanPaymentId,
    required DateTime entryDate,
    required String? leadId,
    required String? routeId,
    required bool isCash,
    double? profitAmount,
    double? returnToCapital,
  }) async {
    return createEntry(CreateAccountEntryInput(
      accountId: accountId,
      entryType: EntryType.credit,
      amount: paymentAmount,
      sourceType: isCash ? EntrySourceType.loanPaymentCash : EntrySourceType.loanPaymentBank,
      entryDate: entryDate,
      loanId: loanId,
      loanPaymentId: loanPaymentId,
      leadId: leadId,
      routeId: routeId,
      profitAmount: profitAmount,
      returnToCapital: returnToCapital,
      description: 'Pago de crédito',
    ));
  }

  /// Create a DEBIT entry for payment commission
  Future<String> createPaymentCommissionEntry({
    required String accountId,
    required double commissionAmount,
    required String loanPaymentId,
    required DateTime entryDate,
    required String? leadId,
    required String? routeId,
  }) async {
    return createEntry(CreateAccountEntryInput(
      accountId: accountId,
      entryType: EntryType.debit,
      amount: commissionAmount,
      sourceType: EntrySourceType.paymentCommission,
      entryDate: entryDate,
      loanPaymentId: loanPaymentId,
      leadId: leadId,
      routeId: routeId,
      description: 'Comisión por pago',
    ));
  }

  /// Get entries for a specific loan
  Future<List<AccountEntry>> getEntriesForLoan(String loanId) async {
    final results = await _db.execute('''
      SELECT * FROM AccountEntry
      WHERE loanId = ?
      ORDER BY entryDate ASC
    ''', [loanId]);

    return results.map((r) => AccountEntry.fromRow(r)).toList();
  }

  /// Get entries for a specific account on a date range
  Future<List<AccountEntry>> getEntriesForAccount(
    String accountId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    String query = 'SELECT * FROM AccountEntry WHERE accountId = ?';
    final params = <dynamic>[accountId];

    if (fromDate != null) {
      query += ' AND entryDate >= ?';
      params.add(fromDate.toIso8601String());
    }

    if (toDate != null) {
      query += ' AND entryDate <= ?';
      params.add(toDate.toIso8601String());
    }

    query += ' ORDER BY entryDate DESC';

    final results = await _db.execute(query, params);
    return results.map((r) => AccountEntry.fromRow(r)).toList();
  }

  /// Calculate account balance from entries (for offline verification)
  ///
  /// Balance = SUM(CREDIT amounts) - SUM(DEBIT amounts)
  Future<double> calculateAccountBalance(String accountId) async {
    final results = await _db.execute('''
      SELECT
        COALESCE(SUM(CASE WHEN entryType = 'CREDIT' THEN amount ELSE 0 END), 0) as totalCredits,
        COALESCE(SUM(CASE WHEN entryType = 'DEBIT' THEN amount ELSE 0 END), 0) as totalDebits
      FROM AccountEntry
      WHERE accountId = ?
    ''', [accountId]);

    if (results.isEmpty) return 0;

    final row = results.first;
    final totalCredits = (row['totalCredits'] as num?)?.toDouble() ?? 0;
    final totalDebits = (row['totalDebits'] as num?)?.toDouble() ?? 0;

    return totalCredits - totalDebits;
  }

  /// Get day summary for entries
  Future<DayEntrySummary> getDaySummary(String accountId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final results = await _db.execute('''
      SELECT
        COALESCE(SUM(CASE WHEN entryType = 'CREDIT' THEN amount ELSE 0 END), 0) as totalCredits,
        COALESCE(SUM(CASE WHEN entryType = 'DEBIT' THEN amount ELSE 0 END), 0) as totalDebits,
        COALESCE(SUM(CASE WHEN sourceType = 'LOAN_GRANT' THEN amount ELSE 0 END), 0) as loansGiven,
        COALESCE(SUM(CASE WHEN sourceType IN ('LOAN_PAYMENT_CASH', 'LOAN_PAYMENT_BANK') THEN amount ELSE 0 END), 0) as paymentsReceived,
        COALESCE(SUM(profitAmount), 0) as totalProfit
      FROM AccountEntry
      WHERE accountId = ?
        AND entryDate >= ?
        AND entryDate <= ?
    ''', [accountId, startOfDay, endOfDay]);

    if (results.isEmpty) {
      return const DayEntrySummary.empty();
    }

    final row = results.first;
    return DayEntrySummary(
      totalCredits: (row['totalCredits'] as num?)?.toDouble() ?? 0,
      totalDebits: (row['totalDebits'] as num?)?.toDouble() ?? 0,
      loansGiven: (row['loansGiven'] as num?)?.toDouble() ?? 0,
      paymentsReceived: (row['paymentsReceived'] as num?)?.toDouble() ?? 0,
      totalProfit: (row['totalProfit'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Summary of entries for a day
class DayEntrySummary {
  final double totalCredits;
  final double totalDebits;
  final double loansGiven;
  final double paymentsReceived;
  final double totalProfit;

  const DayEntrySummary({
    required this.totalCredits,
    required this.totalDebits,
    required this.loansGiven,
    required this.paymentsReceived,
    required this.totalProfit,
  });

  const DayEntrySummary.empty()
      : totalCredits = 0,
        totalDebits = 0,
        loansGiven = 0,
        paymentsReceived = 0,
        totalProfit = 0;

  double get netChange => totalCredits - totalDebits;
}
