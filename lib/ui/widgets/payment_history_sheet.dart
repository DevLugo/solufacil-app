import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                        Text(
                          'Historial de Pagos',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Formatters.dateShort(loan.signDate)} • ${loan.weekDuration ?? 0} semanas',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),

              // 4 KPIs matching web: prestado, deuda, pagado, debe
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _KpiCard(
                      value: Formatters.currencyCompact(loan.requestedAmount),
                      label: 'prestado',
                      valueColor: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    _KpiCard(
                      value: Formatters.currencyCompact(loan.totalAmountDue),
                      label: 'deuda',
                    ),
                    const SizedBox(width: 6),
                    _KpiCard(
                      value: Formatters.currencyCompact(loan.totalPaid),
                      label: 'pagado',
                      valueColor: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    _KpiCard(
                      value: Formatters.currencyCompact(loan.pendingDebt),
                      label: 'debe',
                      valueColor: loan.pendingDebt > 0 ? AppColors.error : AppColors.success,
                    ),
                  ],
                ),
              ),

              // Interest rate and weeks info
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Interés: ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    Text(
                      '${((loan.rate ?? 0) * 100).round()}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      ' • ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    Text(
                      '${loan.weekDuration ?? 0}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      ' semanas',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),

              // Table header - 4 columns: #, Fecha, Pagado, Deuda
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '#',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Fecha',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Pagado',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Deuda',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.right,
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
                    return _PaymentRow(item: item, expectedWeekly: item.expectedAmount);
                  },
                ),
              ),

              // Empty state
              if (chronology.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Sin pagos registrados',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Helper to get Monday of the week containing a date
  DateTime _getWeekMonday(DateTime date) {
    final dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday
    return DateTime(date.year, date.month, date.day - (dayOfWeek - 1));
  }

  /// Helper to get Sunday of the week containing a date
  DateTime _getWeekSunday(DateTime monday) {
    return DateTime(monday.year, monday.month, monday.day + 6, 23, 59, 59, 999);
  }

  /// Generates payment chronology matching web logic exactly
  /// Uses calendar weeks (Monday-Sunday) for payment assignment
  List<PaymentChronologyItem> _generatePaymentChronology() {
    final items = <PaymentChronologyItem>[];
    final weekDuration = loan.weekDuration ?? 16;

    // Match web: totalDue = loan.totalAmountDue ?? (amountGived + profitAmount)
    final totalDue = loan.totalAmountDue > 0
        ? loan.totalAmountDue
        : (loan.requestedAmount + loan.profitAmount);

    // Match web: expectedWeekly = totalDue / weekDuration
    final expectedWeekly = weekDuration > 0 ? totalDue / weekDuration : 0.0;
    final now = DateTime.now();

    // Check if loan is finished or renewed
    final isFinished = loan.status == LoanStatus.finished;
    final isRenewed = loan.wasRenewed;
    final finishedDate = loan.finishedDate;

    // Determine how many weeks to show
    int totalWeeks = weekDuration;
    if (finishedDate != null && isFinished) {
      final weeksToFinish = ((finishedDate.difference(loan.signDate).inDays) / 7).ceil();
      totalWeeks = weeksToFinish.clamp(1, weekDuration);
    }

    // Sort payments by date
    final sortedPayments = [...loan.payments]..sort(
        (a, b) => a.receivedAt.compareTo(b.receivedAt),
      );

    // Track running balance
    double runningBalance = totalDue;

    for (int week = 1; week <= totalWeeks; week++) {
      // Calculate weekPaymentDate = signDate + (week * 7) days
      // This is the "due date" for week N
      final weekPaymentDate = loan.signDate.add(Duration(days: week * 7));

      // Get the calendar week (Monday-Sunday) containing weekPaymentDate
      final weekMonday = _getWeekMonday(weekPaymentDate);
      final weekSunday = _getWeekSunday(weekMonday);

      // Find all payments in this calendar week
      final paymentsInWeek = sortedPayments.where((p) {
        final paymentDate = DateTime(p.receivedAt.year, p.receivedAt.month, p.receivedAt.day);
        final mondayDate = DateTime(weekMonday.year, weekMonday.month, weekMonday.day);
        final sundayDate = DateTime(weekSunday.year, weekSunday.month, weekSunday.day);
        return !paymentDate.isBefore(mondayDate) && !paymentDate.isAfter(sundayDate);
      }).toList();

      // Calculate paid before this week (all payments before weekMonday)
      final paidBeforeWeek = sortedPayments
          .where((p) => p.receivedAt.isBefore(weekMonday))
          .fold<double>(0, (sum, p) => sum + p.amount);

      // Calculate weekly paid
      final weeklyPaid = paymentsInWeek.fold<double>(0, (sum, p) => sum + p.amount);

      // Calculate surplus before this week
      final expectedBefore = (week - 1) * expectedWeekly;
      final surplusBefore = paidBeforeWeek - expectedBefore;

      // Check if this week is covered by surplus + current payment
      final coversWithSurplus =
          surplusBefore + weeklyPaid >= expectedWeekly && expectedWeekly > 0;

      // Determine coverage type (same logic as web)
      CoverageType coverageType;
      if (weeklyPaid >= expectedWeekly && expectedWeekly > 0) {
        coverageType = CoverageType.full;
      } else if (coversWithSurplus && weeklyPaid > 0) {
        coverageType = CoverageType.coveredBySurplus;
      } else if (coversWithSurplus && weeklyPaid == 0) {
        coverageType = CoverageType.coveredBySurplus;
      } else if (weeklyPaid > 0) {
        coverageType = CoverageType.partial;
      } else {
        coverageType = CoverageType.miss;
      }

      // Don't show NO_PAYMENT after finish/renewal or for future weeks
      if (weeklyPaid == 0 && !coversWithSurplus) {
        if (isFinished || isRenewed) {
          continue; // Skip this week entirely
        }
        if (weekSunday.isAfter(now)) {
          coverageType = CoverageType.upcoming;
        }
      }

      // Update running balance
      runningBalance -= weeklyPaid;
      if (runningBalance < 0) runningBalance = 0;

      // Get date to display (payment date if payment exists, otherwise weekPaymentDate)
      DateTime displayDate;
      if (paymentsInWeek.isNotEmpty) {
        displayDate = paymentsInWeek.first.receivedAt;
      } else {
        displayDate = weekPaymentDate;
      }

      items.add(PaymentChronologyItem(
        weekNumber: week,
        expectedAmount: expectedWeekly,
        paidAmount: weeklyPaid,
        balance: runningBalance,
        coverageType: coverageType,
        surplusBefore: surplusBefore,
        surplusAfter: surplusBefore + weeklyPaid - expectedWeekly,
        date: displayDate,
      ));
    }

    return items;
  }
}

enum CoverageType {
  full,
  partial,
  miss,
  coveredBySurplus,
  upcoming,
}

class PaymentChronologyItem {
  final int weekNumber;
  final double expectedAmount;
  final double paidAmount;
  final double balance;
  final CoverageType coverageType;
  final double surplusBefore;
  final double surplusAfter;
  final DateTime date;

  PaymentChronologyItem({
    required this.weekNumber,
    required this.expectedAmount,
    required this.paidAmount,
    required this.balance,
    required this.coverageType,
    this.surplusBefore = 0,
    this.surplusAfter = 0,
    required this.date,
  });
}

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _KpiCard({
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final PaymentChronologyItem item;
  final double expectedWeekly;

  const _PaymentRow({
    required this.item,
    required this.expectedWeekly,
  });

  Color get _rowColor {
    switch (item.coverageType) {
      case CoverageType.full:
        // Overpaid: paid >= 1.5x expected
        if (item.paidAmount >= expectedWeekly * 1.5 && expectedWeekly > 0) {
          return AppColors.success.withOpacity(0.1);
        }
        return Colors.transparent;
      case CoverageType.partial:
        return AppColors.warning.withOpacity(0.1);
      case CoverageType.miss:
        return AppColors.error.withOpacity(0.1);
      case CoverageType.coveredBySurplus:
        return AppColors.info.withOpacity(0.1);
      case CoverageType.upcoming:
        return Colors.transparent;
    }
  }

  Color get _borderColor {
    switch (item.coverageType) {
      case CoverageType.full:
        if (item.paidAmount >= expectedWeekly * 1.5 && expectedWeekly > 0) {
          return AppColors.success;
        }
        return Colors.transparent;
      case CoverageType.partial:
        return AppColors.warning;
      case CoverageType.miss:
        return AppColors.error;
      case CoverageType.coveredBySurplus:
        return AppColors.info;
      case CoverageType.upcoming:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNoPayment = item.paidAmount == 0;
    final showBorder = _borderColor != Colors.transparent;
    final dateFormatter = DateFormat('dd/MM/yy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _rowColor,
        border: Border(
          left: showBorder
              ? BorderSide(color: _borderColor, width: 4)
              : BorderSide.none,
          bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          // Week number
          SizedBox(
            width: 28,
            child: Text(
              '${item.weekNumber}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
            ),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Text(
              dateFormatter.format(item.date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
          // Paid amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isNoPayment ? '-' : Formatters.currencyCompact(item.paidAmount),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isNoPayment ? null : FontWeight.w500,
                        color: isNoPayment ? AppColors.textMuted : null,
                        fontStyle: isNoPayment ? FontStyle.italic : null,
                      ),
                ),
                // Show "cubierto" indicator for covered by surplus
                if (item.coverageType == CoverageType.coveredBySurplus && isNoPayment)
                  Text(
                    'cubierto',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.info,
                          fontSize: 9,
                        ),
                  ),
              ],
            ),
          ),
          // Debt after payment
          Expanded(
            child: Text(
              Formatters.currencyCompact(item.balance),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: item.balance == 0 ? AppColors.success : AppColors.error,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
