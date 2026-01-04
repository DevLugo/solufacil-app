import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/loan.dart';
import '../data/models/payment_input.dart';
import '../data/repositories/payment_repository.dart';
import 'powersync_provider.dart';
import 'collector_dashboard_provider.dart';

// =============================================================================
// REPOSITORY PROVIDER
// =============================================================================

/// Payment repository provider
final paymentRepositoryProvider = Provider<PaymentRepository?>((ref) {
  final dbAsyncValue = ref.watch(powerSyncDatabaseProvider);
  final db = dbAsyncValue.valueOrNull;
  if (db == null) return null;
  return PaymentRepository(db);
});

// =============================================================================
// ACTIVE LOANS FOR LOCALITY
// =============================================================================

/// Active loan for collection display
class CollectionLoan {
  final String loanId;
  final String borrowerId;
  final String borrowerName;
  final String? clientCode;
  final String? phone;
  final double expectedWeeklyPayment;
  final double pendingAmount;
  final double totalPaid;
  final double totalDebt;
  final int weeksSinceSign;
  final DateTime signDate;
  final DateTime? lastPaymentDate;
  final bool paidThisWeek;
  final int weeksWithoutPayment;
  final bool isBadDebt;
  final double loanPaymentComission;  // Commission per payment from LoanType

  const CollectionLoan({
    required this.loanId,
    required this.borrowerId,
    required this.borrowerName,
    this.clientCode,
    this.phone,
    required this.expectedWeeklyPayment,
    required this.pendingAmount,
    required this.totalPaid,
    required this.totalDebt,
    required this.weeksSinceSign,
    required this.signDate,
    this.lastPaymentDate,
    required this.paidThisWeek,
    required this.weeksWithoutPayment,
    required this.isBadDebt,
    required this.loanPaymentComission,
  });

  /// Priority for sorting (higher = more urgent)
  int get priority {
    if (paidThisWeek) return 0; // Already paid - lowest priority
    if (weeksWithoutPayment >= 4) return 100 + weeksWithoutPayment; // Critical
    if (weeksWithoutPayment >= 2) return 50 + weeksWithoutPayment; // Warning
    return 10; // Normal
  }

  /// Status label for display
  String get statusLabel {
    if (paidThisWeek) return 'Pagado';
    if (weeksWithoutPayment >= 4) return 'Critico';
    if (weeksWithoutPayment >= 2) return 'CV $weeksWithoutPayment sem';
    if (weeksWithoutPayment == 1) return 'CV';
    return 'Pendiente';
  }

  /// Is in cartera vencida
  bool get isInCV => !paidThisWeek && weeksWithoutPayment >= 1;
}

/// Helper to build a CollectionLoan from database row
CollectionLoan _buildCollectionLoan(
  Map<String, dynamic> row,
  Map<String, Map<String, dynamic>> paymentInfo,
  Set<String> paidThisWeek,
  dynamic weekState,
) {
  final loanId = row['id'] as String;
  final signDateStr = row['signDate'] as String?;
  final signDate = DateTime.tryParse(signDateStr ?? '') ?? DateTime.now();
  final badDebtDateStr = row['badDebtDate'] as String?;

  final lastPaymentDate = _getLastPaymentDate(paymentInfo[loanId]);
  final weeksWithoutPayment = _calculateWeeksWithoutPayment(
    weekState.weekStart,
    lastPaymentDate ?? signDate,
  );

  return CollectionLoan(
    loanId: loanId,
    borrowerId: row['borrower'] as String? ?? '',
    borrowerName: row['borrowerName'] as String? ?? 'Sin nombre',
    clientCode: row['clientCode'] as String?,
    phone: row['phone'] as String?,
    expectedWeeklyPayment:
        (row['expectedWeeklyPayment'] as num?)?.toDouble() ?? 0,
    pendingAmount: (row['pendingAmountStored'] as num?)?.toDouble() ?? 0,
    totalPaid: (row['totalPaid'] as num?)?.toDouble() ?? 0,
    totalDebt: (row['totalDebtAcquired'] as num?)?.toDouble() ?? 0,
    weeksSinceSign: DateTime.now().difference(signDate).inDays ~/ 7,
    signDate: signDate,
    lastPaymentDate: lastPaymentDate,
    paidThisWeek: paidThisWeek.contains(loanId),
    weeksWithoutPayment: weeksWithoutPayment,
    isBadDebt: badDebtDateStr != null && badDebtDateStr.isNotEmpty,
    loanPaymentComission:
        (row['loanPaymentComission'] as num?)?.toDouble() ?? 0,
  );
}

/// Helper to extract last payment date from payment info
DateTime? _getLastPaymentDate(Map<String, dynamic>? info) {
  if (info == null) return null;

  final lastPaymentStr = info['lastPayment'] as String?;
  return lastPaymentStr != null ? DateTime.tryParse(lastPaymentStr) : null;
}

/// Helper to calculate weeks without payment
int _calculateWeeksWithoutPayment(DateTime weekStart, DateTime referenceDate) {
  final weeks = weekStart.difference(referenceDate).inDays ~/ 7;
  return weeks.clamp(0, 99);
}

/// Helper to get payment info for loans
Future<Map<String, Map<String, dynamic>>> _getPaymentInfo(
  dynamic db,
  List<String> loanIds,
) async {
  final placeholders = loanIds.map((_) => '?').join(',');
  final paymentsResult = await db.execute('''
    SELECT loan, receivedAt, MAX(receivedAt) as lastPayment
    FROM LoanPayment
    WHERE loan IN ($placeholders)
    GROUP BY loan
  ''', loanIds);

  final paymentInfo = <String, Map<String, dynamic>>{};
  for (final row in paymentsResult) {
    final loanId = row['loan'] as String;
    paymentInfo[loanId] = row;
  }
  return paymentInfo;
}

/// Helper to get loans paid this week
Future<Set<String>> _getPaidThisWeek(
  dynamic db,
  List<String> loanIds,
  dynamic weekState,
) async {
  final weekStartStr = weekState.weekStart.toIso8601String().split('T')[0];
  final weekEndStr = weekState.weekEnd.toIso8601String().split('T')[0];
  final placeholders = loanIds.map((_) => '?').join(',');

  final paidThisWeekResult = await db.execute('''
    SELECT DISTINCT loan
    FROM LoanPayment
    WHERE loan IN ($placeholders)
      AND receivedAt >= ?
      AND receivedAt <= ?
  ''', [...loanIds, weekStartStr, '${weekEndStr}T23:59:59']);

  final result = <String>{};
  for (final r in paidThisWeekResult) {
    result.add(r['loan'] as String);
  }
  return result;
}

/// SQL query for fetching active loans
/// Uses the same filters as API ListadoPDFService.getActiveLoans:
/// - finishedDate: null (not finished)
/// - excludedByCleanup: null (not excluded by cleanup)
/// - lead = leaderId (ONLY current lead, NOT snapshotLeadId)
/// Additional filters for truly active loans:
/// - pendingAmountStored > 0 (has pending payments)
/// - renewedDate: null (not renewed)
const _activeLoansQuery = '''
  SELECT
    l.id,
    l.borrower,
    l.expectedWeeklyPayment,
    l.pendingAmountStored,
    l.totalPaid,
    l.totalDebtAcquired,
    l.signDate,
    l.badDebtDate,
    pd.fullName as borrowerName,
    pd.clientCode,
    (SELECT phone FROM Phone WHERE personalData = pd.id LIMIT 1) as phone,
    lt.loanPaymentComission
  FROM Loan l
  JOIN Borrower b ON l.borrower = b.id
  JOIN PersonalData pd ON b.personalData = pd.id
  LEFT JOIN Loantype lt ON l.loantype = lt.id
  WHERE l.lead = ?
    AND (l.finishedDate IS NULL OR l.finishedDate = '')
    AND l.pendingAmountStored > 0
    AND (l.excludedByCleanup IS NULL OR l.excludedByCleanup = '')
    AND (l.renewedDate IS NULL OR l.renewedDate = '')
  ORDER BY pd.fullName
''';

/// Active loans for a specific locality/lead
final activeLoansForLocalityProvider =
    FutureProvider.family<List<CollectionLoan>, String>((ref, leadId) async {
  final dbAsyncValue = ref.watch(powerSyncDatabaseProvider);
  final db = dbAsyncValue.valueOrNull;
  if (db == null) return [];

  final weekState = ref.watch(weekStateProvider);

  try {
    final loansResult = await db.execute(_activeLoansQuery, [leadId]);

    final loanIds = loansResult.map((r) => r['id'] as String).toList();
    if (loanIds.isEmpty) return [];

    final paymentInfo = await _getPaymentInfo(db, loanIds);
    final paidThisWeek = await _getPaidThisWeek(db, loanIds, weekState);

    final loans = loansResult
        .map((row) => _buildCollectionLoan(
              row,
              paymentInfo,
              paidThisWeek,
              weekState,
            ))
        .toList();

    // Sort by priority (most urgent first), then by name
    loans.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.borrowerName.compareTo(b.borrowerName);
    });

    return loans;
  } catch (e) {
    debugPrint('[activeLoansForLocalityProvider] Error: $e');
    return [];
  }
});

// =============================================================================
// EXTRA COBRANZAS (Cleanup + Bad Debt Loans)
// =============================================================================

/// SQL query for fetching cleanup/extra loans (excludedByCleanup OR badDebtDate)
/// These are loans that were excluded from active collection but can still receive payments
const _extraLoansQuery = '''
  SELECT
    l.id,
    l.borrower,
    l.expectedWeeklyPayment,
    l.pendingAmountStored,
    l.totalPaid,
    l.totalDebtAcquired,
    l.signDate,
    l.badDebtDate,
    l.excludedByCleanup,
    pd.fullName as borrowerName,
    pd.clientCode,
    (SELECT phone FROM Phone WHERE personalData = pd.id LIMIT 1) as phone,
    lt.loanPaymentComission
  FROM Loan l
  JOIN Borrower b ON l.borrower = b.id
  JOIN PersonalData pd ON b.personalData = pd.id
  LEFT JOIN Loantype lt ON l.loantype = lt.id
  WHERE l.lead = ?
    AND (l.finishedDate IS NULL OR l.finishedDate = '')
    AND l.pendingAmountStored > 0
    AND (l.renewedDate IS NULL OR l.renewedDate = '')
    AND (
      (l.excludedByCleanup IS NOT NULL AND l.excludedByCleanup != '')
      OR (l.badDebtDate IS NOT NULL AND l.badDebtDate != '')
    )
  ORDER BY pd.fullName
''';

/// Extra/cleanup loans for a specific locality/lead
/// These are clients excluded from regular collection but can still pay
final extraLoansForLocalityProvider =
    FutureProvider.family<List<CollectionLoan>, String>((ref, leadId) async {
  final dbAsyncValue = ref.watch(powerSyncDatabaseProvider);
  final db = dbAsyncValue.valueOrNull;
  if (db == null) return [];

  final weekState = ref.watch(weekStateProvider);

  try {
    final loansResult = await db.execute(_extraLoansQuery, [leadId]);

    final loanIds = loansResult.map((r) => r['id'] as String).toList();
    if (loanIds.isEmpty) return [];

    final paymentInfo = await _getPaymentInfo(db, loanIds);
    final paidThisWeek = await _getPaidThisWeek(db, loanIds, weekState);

    final loans = loansResult
        .map((row) => _buildCollectionLoan(
              row,
              paymentInfo,
              paidThisWeek,
              weekState,
            ))
        .toList();

    // Sort by name
    loans.sort((a, b) => a.borrowerName.compareTo(b.borrowerName));

    return loans;
  } catch (e) {
    debugPrint('[extraLoansForLocalityProvider] Error: $e');
    return [];
  }
});

// =============================================================================
// DAY PAYMENT STATE (IN-MEMORY)
// =============================================================================

/// State notifier for managing day's payments before saving
class DayPaymentStateNotifier extends StateNotifier<DayPaymentState?> {
  DayPaymentStateNotifier() : super(null);

  /// Initialize state for a new day/locality
  void initialize({
    required String leadId,
    required String localityId,
    required DateTime date,
  }) {
    state = DayPaymentState(
      leadId: leadId,
      localityId: localityId,
      date: date,
    );
  }

  /// Add or update a payment entry
  void addPayment(PaymentEntry payment) {
    if (state == null) return;
    state = state!.addPayment(payment);
  }

  /// Remove a payment entry
  void removePayment(String loanId) {
    if (state == null) return;
    state = state!.removePayment(loanId);
  }

  /// Clear all payments
  void clear() {
    state = null;
  }

  /// Check if loan has pending payment
  bool hasPaymentForLoan(String loanId) {
    if (state == null) return false;
    return state!.payments.any((p) => p.loanId == loanId);
  }

  /// Get payment for loan
  PaymentEntry? getPaymentForLoan(String loanId) {
    if (state == null) return null;
    try {
      return state!.payments.firstWhere((p) => p.loanId == loanId);
    } catch (_) {
      return null;
    }
  }
}

final dayPaymentStateProvider =
    StateNotifierProvider<DayPaymentStateNotifier, DayPaymentState?>((ref) {
  return DayPaymentStateNotifier();
});

// =============================================================================
// LOCALITY DAY SUMMARY
// =============================================================================

/// Summary for locality collection progress
class LocalityCollectionSummary {
  final int totalLoans;
  final int paidCount;
  final int pendingCount;
  final int noPaymentCount;
  final double expectedAmount;
  final double collectedAmount;
  final double pendingAmount;
  final double totalCash;
  final double totalBank;

  const LocalityCollectionSummary({
    required this.totalLoans,
    required this.paidCount,
    required this.pendingCount,
    required this.noPaymentCount,
    required this.expectedAmount,
    required this.collectedAmount,
    required this.pendingAmount,
    required this.totalCash,
    required this.totalBank,
  });

  double get progressPercent {
    if (totalLoans == 0) return 0;
    return (paidCount / totalLoans * 100).clamp(0, 100);
  }

  factory LocalityCollectionSummary.empty() => const LocalityCollectionSummary(
        totalLoans: 0,
        paidCount: 0,
        pendingCount: 0,
        noPaymentCount: 0,
        expectedAmount: 0,
        collectedAmount: 0,
        pendingAmount: 0,
        totalCash: 0,
        totalBank: 0,
      );
}

/// Helper to calculate in-memory payment totals
({
  int paidCount,
  int noPaymentCount,
  double cash,
  double bank,
  double collected,
}) _calculateInMemoryTotals(DayPaymentState? dayState) {
  if (dayState == null) {
    return (
      paidCount: 0,
      noPaymentCount: 0,
      cash: 0.0,
      bank: 0.0,
      collected: 0.0,
    );
  }

  int paidCount = 0;
  int noPaymentCount = 0;
  double cash = 0;
  double bank = 0;
  double collected = 0;

  for (final payment in dayState.payments) {
    if (payment.isNoPayment) {
      noPaymentCount++;
      continue;
    }

    paidCount++;
    collected += payment.amount;
    // Use cashAmount and bankAmount for mixed payment support
    cash += payment.cashAmount;
    bank += payment.bankAmount;
  }

  return (
    paidCount: paidCount,
    noPaymentCount: noPaymentCount,
    cash: cash,
    bank: bank,
    collected: collected,
  );
}

/// Summary provider combining DB data with in-memory payments
final localityDaySummaryProvider =
    Provider.family<LocalityCollectionSummary, String>((ref, leadId) {
  final loansAsync = ref.watch(activeLoansForLocalityProvider(leadId));
  final dayState = ref.watch(dayPaymentStateProvider);

  return loansAsync.when(
    data: (loans) {
      if (loans.isEmpty) return LocalityCollectionSummary.empty();

      final alreadyPaidCount = loans.where((l) => l.paidThisWeek).length;
      final inMemory = _calculateInMemoryTotals(dayState);

      final totalPaid = alreadyPaidCount + inMemory.paidCount;
      final pendingCount = loans.length - totalPaid - inMemory.noPaymentCount;
      final expectedAmount =
          loans.fold<double>(0, (sum, l) => sum + l.expectedWeeklyPayment);

      final alreadyCollected = loans
          .where((l) => l.paidThisWeek)
          .fold<double>(0, (sum, l) => sum + l.expectedWeeklyPayment);

      final totalCollected = alreadyCollected + inMemory.collected;

      return LocalityCollectionSummary(
        totalLoans: loans.length,
        paidCount: totalPaid,
        pendingCount: pendingCount,
        noPaymentCount: inMemory.noPaymentCount,
        expectedAmount: expectedAmount,
        collectedAmount: totalCollected,
        pendingAmount: expectedAmount - totalCollected,
        totalCash: inMemory.cash,
        totalBank: inMemory.bank,
      );
    },
    loading: () => LocalityCollectionSummary.empty(),
    error: (_, __) => LocalityCollectionSummary.empty(),
  );
});

// =============================================================================
// COMMISSION CALCULATOR
// =============================================================================

/// Calculate commission for a payment
double calculateCommission({
  required double amount,
  required double expectedWeeklyPayment,
  required double baseCommission,
}) {
  if (expectedWeeklyPayment <= 0 || baseCommission <= 0 || amount <= 0) {
    return 0;
  }

  final multiplier = (amount / expectedWeeklyPayment).floor();
  return multiplier >= 1 ? baseCommission * multiplier : 0;
}
