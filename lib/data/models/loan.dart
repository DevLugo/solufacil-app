import 'package:equatable/equatable.dart';

/// Loan status enumeration
enum LoanStatus {
  active,
  finished,
  renovated,
  cancelled;

  static LoanStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'ACTIVE':
        return LoanStatus.active;
      case 'FINISHED':
        return LoanStatus.finished;
      case 'RENOVATED':
        return LoanStatus.renovated;
      case 'CANCELLED':
        return LoanStatus.cancelled;
      default:
        return LoanStatus.active;
    }
  }

  String get displayName {
    switch (this) {
      case LoanStatus.active:
        return 'Activo';
      case LoanStatus.finished:
        return 'Terminado';
      case LoanStatus.renovated:
        return 'Renovado';
      case LoanStatus.cancelled:
        return 'Cancelado';
    }
  }
}

/// Loan model
class Loan extends Equatable {
  final String id;
  final String? oldId;
  final double requestedAmount;
  final double amountGived;
  final DateTime signDate;
  final DateTime? finishedDate;
  final DateTime? renewedDate;
  final DateTime? badDebtDate;
  final bool isDeceased;
  final double profitAmount;
  final double totalDebtAcquired;
  final double expectedWeeklyPayment;
  final double totalPaid;
  final double pendingAmountStored;
  final LoanStatus status;
  final String borrowerId;
  final String? leadId;
  final String? snapshotRouteName;
  final String? previousLoanId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Loan type info
  final int? weekDuration;
  final double? rate;

  // Related data (populated from joins)
  final String? borrowerName;
  final String? leadName;
  final List<String> collateralNames;
  final List<LoanPayment> payments;

  const Loan({
    required this.id,
    this.oldId,
    required this.requestedAmount,
    required this.amountGived,
    required this.signDate,
    this.finishedDate,
    this.renewedDate,
    this.badDebtDate,
    this.isDeceased = false,
    required this.profitAmount,
    required this.totalDebtAcquired,
    required this.expectedWeeklyPayment,
    required this.totalPaid,
    required this.pendingAmountStored,
    required this.status,
    required this.borrowerId,
    this.leadId,
    this.snapshotRouteName,
    this.previousLoanId,
    required this.createdAt,
    required this.updatedAt,
    this.weekDuration,
    this.rate,
    this.borrowerName,
    this.leadName,
    this.collateralNames = const [],
    this.payments = const [],
  });

  /// Pending debt (balance remaining)
  double get pendingDebt => pendingAmountStored;

  /// Interest amount
  double get interestAmount => profitAmount;

  /// Total amount due (principal + interest)
  double get totalAmountDue => totalDebtAcquired;

  /// Payment progress as percentage (0-100)
  double get paymentProgress {
    if (totalDebtAcquired == 0) return 0;
    return (totalPaid / totalDebtAcquired * 100).clamp(0, 100);
  }

  /// Check if loan was renewed
  bool get wasRenewed => renewedDate != null || status == LoanStatus.renovated;

  /// Check if loan is bad debt
  bool get isBadDebt => badDebtDate != null;

  /// Days since loan was signed
  int get daysSinceSign => DateTime.now().difference(signDate).inDays;

  /// Weeks since loan was signed
  int get weeksSinceSign => (daysSinceSign / 7).floor();

  /// Check if fully paid
  bool get isFullyPaid => pendingAmountStored <= 0;

  factory Loan.fromRow(Map<String, dynamic> row, {
    String? borrowerName,
    String? leadName,
    List<String> collateralNames = const [],
    List<LoanPayment> payments = const [],
    int? weekDuration,
    double? rate,
  }) {
    return Loan(
      id: row['id'] as String,
      oldId: row['oldId'] as String?,
      requestedAmount: (row['requestedAmount'] as num?)?.toDouble() ?? 0,
      amountGived: (row['amountGived'] as num?)?.toDouble() ?? 0,
      signDate: DateTime.parse(row['signDate'] as String),
      finishedDate: row['finishedDate'] != null
          ? DateTime.tryParse(row['finishedDate'] as String)
          : null,
      renewedDate: row['renewedDate'] != null
          ? DateTime.tryParse(row['renewedDate'] as String)
          : null,
      badDebtDate: row['badDebtDate'] != null
          ? DateTime.tryParse(row['badDebtDate'] as String)
          : null,
      isDeceased: (row['isDeceased'] as int?) == 1,
      profitAmount: (row['profitAmount'] as num?)?.toDouble() ?? 0,
      totalDebtAcquired: (row['totalDebtAcquired'] as num?)?.toDouble() ?? 0,
      expectedWeeklyPayment:
          (row['expectedWeeklyPayment'] as num?)?.toDouble() ?? 0,
      totalPaid: (row['totalPaid'] as num?)?.toDouble() ?? 0,
      pendingAmountStored:
          (row['pendingAmountStored'] as num?)?.toDouble() ?? 0,
      status: LoanStatus.fromString(row['status'] as String?),
      borrowerId: row['borrower'] as String,
      leadId: row['lead'] as String?,
      snapshotRouteName: row['snapshotRouteName'] as String?,
      previousLoanId: row['previousLoan'] as String?,
      createdAt: DateTime.parse(row['createdAt'] as String),
      updatedAt: DateTime.parse(row['updatedAt'] as String),
      weekDuration: weekDuration,
      rate: rate,
      borrowerName: borrowerName,
      leadName: leadName,
      collateralNames: collateralNames,
      payments: payments,
    );
  }

  @override
  List<Object?> get props => [
        id,
        oldId,
        requestedAmount,
        amountGived,
        signDate,
        finishedDate,
        renewedDate,
        badDebtDate,
        isDeceased,
        profitAmount,
        totalDebtAcquired,
        expectedWeeklyPayment,
        totalPaid,
        pendingAmountStored,
        status,
        borrowerId,
        leadId,
        snapshotRouteName,
        previousLoanId,
        createdAt,
        updatedAt,
        weekDuration,
        rate,
        borrowerName,
        leadName,
        collateralNames,
        payments,
      ];
}

/// Payment method enumeration
enum PaymentMethod {
  cash,
  moneyTransfer;

  static PaymentMethod fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'MONEY_TRANSFER':
        return PaymentMethod.moneyTransfer;
      case 'CASH':
      default:
        return PaymentMethod.cash;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.moneyTransfer:
        return 'Transferencia';
    }
  }
}

/// Loan payment model
class LoanPayment extends Equatable {
  final String id;
  final double amount;
  final String type;
  final PaymentMethod paymentMethod;
  final DateTime receivedAt;
  final String loanId;
  final DateTime createdAt;

  const LoanPayment({
    required this.id,
    required this.amount,
    required this.type,
    required this.paymentMethod,
    required this.receivedAt,
    required this.loanId,
    required this.createdAt,
  });

  factory LoanPayment.fromRow(Map<String, dynamic> row) {
    return LoanPayment(
      id: row['id'] as String,
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      type: row['type'] as String? ?? 'NORMAL',
      paymentMethod: PaymentMethod.fromString(row['paymentMethod'] as String?),
      receivedAt: DateTime.parse(row['receivedAt'] as String),
      loanId: row['loan'] as String,
      createdAt: DateTime.parse(row['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        type,
        paymentMethod,
        receivedAt,
        loanId,
        createdAt,
      ];
}
