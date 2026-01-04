import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufacil_mobile/data/models/loan.dart';

/// Test helpers and utilities for SoluFácil mobile tests

/// Creates a test Loan with sensible defaults
Loan createTestLoan({
  String id = 'test-loan-123',
  String borrowerName = 'Juan Pérez García',
  double requestedAmount = 5000,
  double amountGived = 5000,
  double profitAmount = 750,
  double totalDebtAcquired = 5750,
  double expectedWeeklyPayment = 575,
  double totalPaid = 1150,
  double pendingAmountStored = 4600,
  LoanStatus status = LoanStatus.active,
  String borrowerId = 'borrower-123',
  String? leadId = 'lead-123',
  int weekDuration = 10,
  double rate = 0.15,
  DateTime? signDate,
  DateTime? createdAt,
}) {
  final now = DateTime.now();
  return Loan(
    id: id,
    requestedAmount: requestedAmount,
    amountGived: amountGived,
    signDate: signDate ?? now.subtract(const Duration(days: 14)),
    profitAmount: profitAmount,
    totalDebtAcquired: totalDebtAcquired,
    expectedWeeklyPayment: expectedWeeklyPayment,
    totalPaid: totalPaid,
    pendingAmountStored: pendingAmountStored,
    status: status,
    borrowerId: borrowerId,
    leadId: leadId,
    createdAt: createdAt ?? now,
    updatedAt: now,
    weekDuration: weekDuration,
    rate: rate,
    borrowerName: borrowerName,
  );
}

/// Creates a test LoanPayment with sensible defaults
LoanPayment createTestPayment({
  String id = 'test-payment-123',
  double amount = 575,
  double comission = 10,
  String type = 'NORMAL',
  PaymentMethod paymentMethod = PaymentMethod.cash,
  String loanId = 'test-loan-123',
  DateTime? receivedAt,
  DateTime? createdAt,
}) {
  final now = DateTime.now();
  return LoanPayment(
    id: id,
    amount: amount,
    comission: comission,
    type: type,
    paymentMethod: paymentMethod,
    receivedAt: receivedAt ?? now,
    loanId: loanId,
    createdAt: createdAt ?? now,
  );
}

/// Wraps a widget with necessary providers for testing
Widget wrapWithProviders(
  Widget child, {
  List<Override>? overrides,
}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      home: child,
      // Add theme if needed
    ),
  );
}

/// Extension for common widget test operations
extension WidgetTesterX on WidgetTester {
  /// Pumps until no more frames are scheduled or timeout
  Future<void> pumpUntilSettled({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      await pump(const Duration(milliseconds: 100));
      if (!hasRunningAnimations) break;
    }
  }

  /// Taps and waits for animations to settle
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Enters text and waits
  Future<void> enterTextAndSettle(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettle();
  }
}

/// Matcher for currency formatted strings
Matcher matchesCurrency(double amount) {
  return predicate<String>((text) {
    // Remove currency symbol and formatting
    final cleaned = text.replaceAll(RegExp(r'[^\d.-]'), '');
    final parsed = double.tryParse(cleaned);
    return parsed != null && (parsed - amount).abs() < 0.01;
  }, 'matches currency $amount');
}

/// Test data constants
class TestData {
  static const String testLeadId = 'test-lead-123';
  static const String testLocationId = 'test-location-123';
  static const String testBorrowerId = 'test-borrower-123';
  static const String testLoanId = 'test-loan-123';
  static const String testPaymentId = 'test-payment-123';

  static const String testBorrowerName = 'María González López';
  static const String testLeadName = 'Ruta Centro';
  static const String testLocationName = 'Centro';

  static const double testExpectedPayment = 575.0;
  static const double testPendingAmount = 4600.0;
  static const double testBaseCommission = 10.0;
}

/// Creates a list of test loans with varying states
List<Loan> createTestLoanList({int count = 10}) {
  return List.generate(count, (index) {
    final isPaid = index < 3; // First 3 are paid
    final isCV = index >= 7; // Last 3 are CV

    return createTestLoan(
      id: 'loan-$index',
      borrowerName: 'Cliente $index',
      borrowerId: 'borrower-$index',
      totalPaid: isPaid ? 5750 : (index * 575),
      pendingAmountStored: isPaid ? 0 : (5750 - (index * 575)),
      status: isPaid ? LoanStatus.finished : LoanStatus.active,
      signDate: DateTime.now().subtract(Duration(days: 7 * (isCV ? 5 : index + 1))),
    );
  });
}
