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
      avgMissedPaymentsPerLoan: 0, // TODO: Calculate from payment data
    );
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
