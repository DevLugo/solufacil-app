import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/loan.dart';

class PaymentHistorySheet extends StatelessWidget {
  final Loan loan;

  const PaymentHistorySheet({
    super.key,
    required this.loan,
  });

  @override
  Widget build(BuildContext context) {
    final chronology = _generatePaymentChronology();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Historial de Pagos',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Préstamo del ${Formatters.dateShort(loan.signDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Summary row
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surfaceVariant,
                child: Row(
                  children: [
                    _SummaryItem(
                      label: 'Total',
                      value: Formatters.currencyCompact(loan.totalAmountDue),
                    ),
                    _SummaryItem(
                      label: 'Pagado',
                      value: Formatters.currencyCompact(loan.totalPaid),
                      color: AppColors.success,
                    ),
                    _SummaryItem(
                      label: 'Pendiente',
                      value: Formatters.currencyCompact(loan.pendingDebt),
                      color: loan.pendingDebt > 0 ? AppColors.error : AppColors.success,
                    ),
                  ],
                ),
              ),

              // Table header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        'Sem',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Esperado',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Pagado',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        'Est',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Payment rows
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: chronology.length,
                  itemBuilder: (context, index) {
                    final item = chronology[index];
                    return _PaymentRow(item: item);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<PaymentChronologyItem> _generatePaymentChronology() {
    final items = <PaymentChronologyItem>[];
    final weekDuration = loan.weekDuration ?? 20;
    final expectedWeekly = loan.expectedWeeklyPayment;

    // Group payments by week
    final paymentsByWeek = <int, double>{};
    for (final payment in loan.payments) {
      final weekNumber = ((payment.receivedAt.difference(loan.signDate).inDays) / 7).floor() + 1;
      paymentsByWeek[weekNumber] = (paymentsByWeek[weekNumber] ?? 0) + payment.amount;
    }

    double runningBalance = loan.totalAmountDue;
    double surplus = 0;

    for (int week = 1; week <= weekDuration; week++) {
      final paid = paymentsByWeek[week] ?? 0;
      final coverageType = _getCoverageType(paid, expectedWeekly, surplus);

      // Update surplus
      if (paid > expectedWeekly) {
        surplus += paid - expectedWeekly;
      } else if (paid < expectedWeekly && surplus > 0) {
        final needed = expectedWeekly - paid;
        if (surplus >= needed) {
          surplus -= needed;
        } else {
          surplus = 0;
        }
      }

      runningBalance -= paid;
      if (runningBalance < 0) runningBalance = 0;

      items.add(PaymentChronologyItem(
        weekNumber: week,
        expectedAmount: expectedWeekly,
        paidAmount: paid,
        balance: runningBalance,
        coverageType: coverageType,
      ));
    }

    return items;
  }

  CoverageType _getCoverageType(double paid, double expected, double surplus) {
    if (paid >= expected) {
      return CoverageType.full;
    } else if (paid > 0) {
      return CoverageType.partial;
    } else if (surplus >= expected) {
      return CoverageType.coveredBySurplus;
    } else {
      return CoverageType.miss;
    }
  }
}

enum CoverageType {
  full,
  partial,
  miss,
  coveredBySurplus,
}

class PaymentChronologyItem {
  final int weekNumber;
  final double expectedAmount;
  final double paidAmount;
  final double balance;
  final CoverageType coverageType;

  PaymentChronologyItem({
    required this.weekNumber,
    required this.expectedAmount,
    required this.paidAmount,
    required this.balance,
    required this.coverageType,
  });
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color ?? AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final PaymentChronologyItem item;

  const _PaymentRow({required this.item});

  Color get _backgroundColor {
    switch (item.coverageType) {
      case CoverageType.full:
        return AppColors.successLight;
      case CoverageType.partial:
        return AppColors.warningLight;
      case CoverageType.miss:
        return AppColors.errorLight;
      case CoverageType.coveredBySurplus:
        return AppColors.infoLight;
    }
  }

  Color get _statusColor {
    switch (item.coverageType) {
      case CoverageType.full:
        return AppColors.success;
      case CoverageType.partial:
        return AppColors.warning;
      case CoverageType.miss:
        return AppColors.error;
      case CoverageType.coveredBySurplus:
        return AppColors.info;
    }
  }

  IconData get _statusIcon {
    switch (item.coverageType) {
      case CoverageType.full:
        return Icons.check_circle;
      case CoverageType.partial:
        return Icons.remove_circle;
      case CoverageType.miss:
        return Icons.cancel;
      case CoverageType.coveredBySurplus:
        return Icons.swap_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _backgroundColor.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${item.weekNumber}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              Formatters.currencyCompact(item.expectedAmount),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              item.paidAmount > 0
                  ? Formatters.currencyCompact(item.paidAmount)
                  : '-',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: item.paidAmount > 0 ? _statusColor : AppColors.textMuted,
                    fontWeight: item.paidAmount > 0 ? FontWeight.w500 : null,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 40,
            child: Icon(
              _statusIcon,
              color: _statusColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
