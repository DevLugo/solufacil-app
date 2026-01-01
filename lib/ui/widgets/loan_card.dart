import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/loan.dart';
import 'payment_history_sheet.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final bool isCollateral;

  const LoanCard({
    super.key,
    required this.loan,
    this.isCollateral = false,
  });

  Color get _statusColor {
    switch (loan.status) {
      case LoanStatus.active:
        return AppColors.success;
      case LoanStatus.finished:
        return AppColors.textMutedDark;
      case LoanStatus.renovated:
        return AppColors.info;
      case LoanStatus.cancelled:
        return AppColors.error;
    }
  }

  Color get _statusBgColor {
    switch (loan.status) {
      case LoanStatus.active:
        return AppColors.successSurface;
      case LoanStatus.finished:
        return AppColors.darkSurfaceHighlight;
      case LoanStatus.renovated:
        return AppColors.infoSurface;
      case LoanStatus.cancelled:
        return AppColors.errorSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppColors.darkBorder.withOpacity(0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: () => _showPaymentHistory(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Date and Status
                Row(
                  children: [
                    // Date with icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceHighlight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.dateShort(loan.signDate),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.textPrimaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (loan.weekDuration != null)
                          Text(
                            '${loan.weeksSinceSign}/${loan.weekDuration} semanas',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textMutedDark,
                                ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    _StatusBadge(
                      status: loan.status,
                      wasRenewed: loan.wasRenewed,
                      color: _statusColor,
                      bgColor: _statusBgColor,
                    ),
                  ],
                ),

                // Collateral/Borrower info
                if ((isCollateral && loan.borrowerName != null) ||
                    (!isCollateral && loan.collateralNames.isNotEmpty)) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceHighlight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCollateral ? Icons.person_rounded : Icons.verified_user_rounded,
                          size: 16,
                          color: isCollateral ? AppColors.primary : AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isCollateral
                                ? 'Cliente: ${loan.borrowerName}'
                                : 'Aval: ${loan.collateralNames.join(", ")}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondaryDark,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Amount Grid - Modern 3 column layout
                Row(
                  children: [
                    Expanded(
                      child: _AmountCard(
                        label: 'Prestado',
                        amount: loan.amountGived,
                        icon: Icons.arrow_upward_rounded,
                        iconColor: AppColors.textSecondaryDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AmountCard(
                        label: 'Pagado',
                        amount: loan.totalPaid,
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: AppColors.success,
                        valueColor: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AmountCard(
                        label: 'Pendiente',
                        amount: loan.pendingDebt,
                        icon: Icons.schedule_rounded,
                        iconColor: loan.pendingDebt > 0 ? AppColors.warning : AppColors.success,
                        valueColor: loan.pendingDebt > 0 ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress Section
                _ProgressSection(loan: loan),

                const SizedBox(height: 12),

                // Action Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.darkSurfaceHighlight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _showPaymentHistory(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ver historial de pagos',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentHistorySheet(loan: loan),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LoanStatus status;
  final bool wasRenewed;
  final Color color;
  final Color bgColor;

  const _StatusBadge({
    required this.status,
    required this.wasRenewed,
    required this.color,
    required this.bgColor,
  });

  String get _label {
    if (wasRenewed && status != LoanStatus.renovated) {
      return 'Renovado';
    }
    return status.displayName;
  }

  IconData get _icon {
    switch (status) {
      case LoanStatus.active:
        return Icons.play_circle_filled_rounded;
      case LoanStatus.finished:
        return Icons.check_circle_rounded;
      case LoanStatus.renovated:
        return Icons.refresh_rounded;
      case LoanStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;

  const _AmountCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceHighlight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMutedDark,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currencyCompact(amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: valueColor ?? AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final Loan loan;

  const _ProgressSection({required this.loan});

  @override
  Widget build(BuildContext context) {
    final progress = loan.paymentProgress / 100;
    final isComplete = loan.paymentProgress >= 100;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isComplete ? AppColors.success : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Progreso de pago',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isComplete
                    ? AppColors.successSurface
                    : AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${loan.paymentProgress.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isComplete ? AppColors.success : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              // Background
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceHighlight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Progress
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: isComplete
                        ? AppColors.successGradient
                        : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
