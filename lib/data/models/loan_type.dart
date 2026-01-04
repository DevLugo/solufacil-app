import 'package:equatable/equatable.dart';

/// Loan type configuration model
class LoanType extends Equatable {
  final String id;
  final String name;
  final int weekDuration;
  final double rate;
  final double initialComissionRate;
  final double renewComissionRate;
  final double loanPaymentComission;  // Commission per payment collected
  final double loanGrantedComission;  // Commission for granting loan

  const LoanType({
    required this.id,
    required this.name,
    required this.weekDuration,
    required this.rate,
    required this.initialComissionRate,
    required this.renewComissionRate,
    required this.loanPaymentComission,
    required this.loanGrantedComission,
  });

  /// Get commission rate based on whether it's a renewal
  double getComissionRate(bool isRenewal) {
    return isRenewal ? renewComissionRate : initialComissionRate;
  }

  /// Calculate commission amount for a loan
  double calculateComission(double requestedAmount, bool isRenewal) {
    final rate = getComissionRate(isRenewal);
    return (requestedAmount * rate).roundToDouble();
  }

  /// Display format for the rate (e.g., "40%")
  String get rateDisplay => '${(rate * 100).toStringAsFixed(0)}%';

  /// Display format for duration (e.g., "14 semanas")
  String get durationDisplay => '$weekDuration semanas';

  factory LoanType.fromRow(Map<String, dynamic> row) {
    return LoanType(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      weekDuration: (row['weekDuration'] as int?) ?? 14,
      rate: (row['rate'] as num?)?.toDouble() ?? 0,
      initialComissionRate: (row['initialComissionRate'] as num?)?.toDouble() ?? 0,
      renewComissionRate: (row['renewComissionRate'] as num?)?.toDouble() ?? 0,
      loanPaymentComission: (row['loanPaymentComission'] as num?)?.toDouble() ?? 0,
      loanGrantedComission: (row['loanGrantedComission'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        weekDuration,
        rate,
        initialComissionRate,
        renewComissionRate,
        loanPaymentComission,
        loanGrantedComission,
      ];
}
