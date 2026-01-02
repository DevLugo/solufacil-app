import 'package:equatable/equatable.dart';
import 'personal_data.dart';
import 'loan.dart';

/// Client search result for autocomplete
class ClientSearchResult extends Equatable {
  final String id;
  final String name;
  final String? clientCode;
  final String? phone;
  final String? address;
  final String? routeName;
  final String? locationName;
  final int totalLoans;
  final int collateralLoans;
  final bool hasLoans;
  final bool hasBeenCollateral;

  const ClientSearchResult({
    required this.id,
    required this.name,
    this.clientCode,
    this.phone,
    this.address,
    this.routeName,
    this.locationName,
    this.totalLoans = 0,
    this.collateralLoans = 0,
    this.hasLoans = false,
    this.hasBeenCollateral = false,
  });

  /// Display code (null if auto-generated)
  String? get displayCode {
    if (clientCode == null || clientCode!.length > 15) return null;
    return clientCode;
  }

  factory ClientSearchResult.fromPersonalData(
    PersonalData personalData, {
    int totalLoans = 0,
    int collateralLoans = 0,
  }) {
    final primaryAddress = personalData.primaryAddress;
    return ClientSearchResult(
      id: personalData.id,
      name: personalData.fullName,
      clientCode: personalData.clientCode,
      phone: personalData.primaryPhone,
      address: primaryAddress?.shortAddress,
      routeName: primaryAddress?.routeName,
      locationName: primaryAddress?.locationName,
      totalLoans: totalLoans,
      collateralLoans: collateralLoans,
      hasLoans: totalLoans > 0,
      hasBeenCollateral: collateralLoans > 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        clientCode,
        phone,
        address,
        routeName,
        locationName,
        totalLoans,
        collateralLoans,
        hasLoans,
        hasBeenCollateral,
      ];
}

/// Client summary statistics
class ClientSummary extends Equatable {
  final int totalLoansAsClient;
  final int totalLoansAsCollateral;
  final int activeLoansAsClient;
  final int activeLoansAsCollateral;
  final double totalAmountRequestedAsClient;
  final double totalAmountPaidAsClient;
  final double currentPendingDebtAsClient;
  final bool hasBeenClient;
  final bool hasBeenCollateral;
  final DateTime? firstLoanDate;
  final double avgMissedPaymentsPerLoan;

  const ClientSummary({
    this.totalLoansAsClient = 0,
    this.totalLoansAsCollateral = 0,
    this.activeLoansAsClient = 0,
    this.activeLoansAsCollateral = 0,
    this.totalAmountRequestedAsClient = 0,
    this.totalAmountPaidAsClient = 0,
    this.currentPendingDebtAsClient = 0,
    this.hasBeenClient = false,
    this.hasBeenCollateral = false,
    this.firstLoanDate,
    this.avgMissedPaymentsPerLoan = 0,
  });

  /// Calculate summary from loans
  factory ClientSummary.fromLoans({
    required List<Loan> loansAsClient,
    required List<Loan> loansAsCollateral,
  }) {
    final activeAsClient =
        loansAsClient.where((l) => l.status == LoanStatus.active).length;
    final activeAsCollateral =
        loansAsCollateral.where((l) => l.status == LoanStatus.active).length;

    final totalRequested =
        loansAsClient.fold<double>(0, (sum, l) => sum + l.amountGived);
    final totalPaid =
        loansAsClient.fold<double>(0, (sum, l) => sum + l.totalPaid);
    final pendingDebt = loansAsClient
        .where((l) => l.status == LoanStatus.active)
        .fold<double>(0, (sum, l) => sum + l.pendingDebt);

    DateTime? firstDate;
    for (final loan in [...loansAsClient, ...loansAsCollateral]) {
      if (firstDate == null || loan.signDate.isBefore(firstDate)) {
        firstDate = loan.signDate;
      }
    }

    // Calculate average missed payments per loan
    final avgMissed = _calculateAvgMissedPayments(loansAsClient);

    return ClientSummary(
      totalLoansAsClient: loansAsClient.length,
      totalLoansAsCollateral: loansAsCollateral.length,
      activeLoansAsClient: activeAsClient,
      activeLoansAsCollateral: activeAsCollateral,
      totalAmountRequestedAsClient: totalRequested,
      totalAmountPaidAsClient: totalPaid,
      currentPendingDebtAsClient: pendingDebt,
      hasBeenClient: loansAsClient.isNotEmpty,
      hasBeenCollateral: loansAsCollateral.isNotEmpty,
      firstLoanDate: firstDate,
      avgMissedPaymentsPerLoan: avgMissed,
    );
  }

  /// Calculate average missed payments per loan
  /// A missed week is one where no payment was made AND surplus didn't cover it
  static double _calculateAvgMissedPayments(List<Loan> loans) {
    if (loans.isEmpty) return 0;

    int totalMissedWeeks = 0;
    int totalLoansWithWeeks = 0;

    for (final loan in loans) {
      final weekDuration = loan.weekDuration ?? 20;
      final expectedWeekly = loan.expectedWeeklyPayment;
      final now = DateTime.now();

      // Only count weeks that are in the past
      final isFinished = loan.status == LoanStatus.finished;
      final isRenewed = loan.wasRenewed;
      final finishedDate = loan.finishedDate;

      // Determine how many weeks to evaluate
      int weeksToEvaluate = weekDuration;
      if (finishedDate != null && isFinished) {
        final weeksToFinish = ((finishedDate.difference(loan.signDate).inDays) / 7).ceil();
        weeksToEvaluate = weeksToFinish.clamp(1, weekDuration);
      }

      // Group payments by week number
      final paymentsByWeek = <int, double>{};
      for (final payment in loan.payments) {
        final daysSinceSign = payment.receivedAt.difference(loan.signDate).inDays;
        final weekNumber = (daysSinceSign / 7).floor() + 1;
        paymentsByWeek[weekNumber] = (paymentsByWeek[weekNumber] ?? 0) + payment.amount;
      }

      int missedWeeksForLoan = 0;

      for (int week = 1; week <= weeksToEvaluate; week++) {
        final weekEndDate = loan.signDate.add(Duration(days: week * 7));

        // Skip future weeks
        if (weekEndDate.isAfter(now)) continue;

        // Don't count after finish/renewal
        if ((isFinished || isRenewed) && finishedDate != null && weekEndDate.isAfter(finishedDate)) {
          continue;
        }

        final paid = paymentsByWeek[week] ?? 0;

        // Calculate surplus before this week
        double paidBeforeWeek = 0;
        for (int w = 1; w < week; w++) {
          paidBeforeWeek += paymentsByWeek[w] ?? 0;
        }
        final expectedBefore = (week - 1) * expectedWeekly;
        final surplusBefore = paidBeforeWeek - expectedBefore;

        // Check if this week is covered by surplus + current payment
        final coversWithSurplus = surplusBefore + paid >= expectedWeekly && expectedWeekly > 0;

        // Count as missed if no payment and surplus doesn't cover
        if (paid == 0 && !coversWithSurplus) {
          missedWeeksForLoan++;
        }
      }

      totalMissedWeeks += missedWeeksForLoan;
      totalLoansWithWeeks++;
    }

    if (totalLoansWithWeeks == 0) return 0;
    return totalMissedWeeks / totalLoansWithWeeks;
  }

  @override
  List<Object?> get props => [
        totalLoansAsClient,
        totalLoansAsCollateral,
        activeLoansAsClient,
        activeLoansAsCollateral,
        totalAmountRequestedAsClient,
        totalAmountPaidAsClient,
        currentPendingDebtAsClient,
        hasBeenClient,
        hasBeenCollateral,
        firstLoanDate,
        avgMissedPaymentsPerLoan,
      ];
}

/// Complete client history data
class ClientHistory extends Equatable {
  final PersonalData client;
  final ClientSummary summary;
  final List<Loan> loansAsClient;
  final List<Loan> loansAsCollateral;

  const ClientHistory({
    required this.client,
    required this.summary,
    this.loansAsClient = const [],
    this.loansAsCollateral = const [],
  });

  /// Get all loans sorted by sign date (newest first)
  List<Loan> get allLoansSorted {
    final allLoans = [...loansAsClient, ...loansAsCollateral];
    allLoans.sort((a, b) => b.signDate.compareTo(a.signDate));
    return allLoans;
  }

  /// Get the most recent loan as client
  Loan? get mostRecentLoanAsClient {
    if (loansAsClient.isEmpty) return null;
    return loansAsClient.reduce(
      (a, b) => a.signDate.isAfter(b.signDate) ? a : b,
    );
  }

  @override
  List<Object?> get props => [
        client,
        summary,
        loansAsClient,
        loansAsCollateral,
      ];
}
