import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../providers/create_credit_provider.dart';
import '../../../providers/loan_types_provider.dart';
import '../../../data/models/loan_type.dart';
import 'create_credit_page.dart';

/// Step 2: Select loan type and amount
class StepLoanType extends ConsumerStatefulWidget {
  final CreateCreditState state;
  final CreateCreditNotifier notifier;

  const StepLoanType({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  ConsumerState<StepLoanType> createState() => _StepLoanTypeState();
}

class _StepLoanTypeState extends ConsumerState<StepLoanType> {
  final _amountController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAmount();
  }

  void _initializeAmount() {
    if (widget.state.requestedAmount > 0) {
      _amountController.text = widget.state.requestedAmount.toStringAsFixed(0);
    } else if (widget.state.isRenewal && widget.state.selectedClient?.activeLoan != null) {
      // Pre-load amount from active loan for renewal
      final activeLoan = widget.state.selectedClient!.activeLoan!;
      final suggestedAmount = activeLoan.requestedAmount;
      _amountController.text = suggestedAmount.toStringAsFixed(0);
      // Update state after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasInitialized) {
          _hasInitialized = true;
          widget.notifier.setRequestedAmount(suggestedAmount);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant StepLoanType oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pre-select loan type for renewal if not already selected
    if (widget.state.isRenewal &&
        widget.state.selectedLoanType == null &&
        widget.state.selectedClient?.activeLoan != null) {
      _preSelectLoanType();
    }
  }

  void _preSelectLoanType() {
    final activeLoan = widget.state.selectedClient?.activeLoan;
    if (activeLoan == null) return;

    final loanTypesAsync = ref.read(loanTypesProvider);
    loanTypesAsync.whenData((loanTypes) {
      // Find matching loan type by name
      final matchingType = loanTypes.where(
        (lt) => lt.name.toLowerCase() == activeLoan.loantypeName.toLowerCase()
      ).firstOrNull;

      if (matchingType != null && widget.state.selectedLoanType == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.notifier.selectLoanType(matchingType);
        });
      }
    });
  }

  void _incrementAmount(int delta) {
    final current = double.tryParse(_amountController.text) ?? 0;
    final newAmount = (current + delta).clamp(0, 1000000);
    _amountController.text = newAmount.toStringAsFixed(0);
    widget.notifier.setRequestedAmount(newAmount.toDouble());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loanTypesAsync = ref.watch(loanTypesProvider);

    // Trigger pre-selection on first build for renewals
    if (widget.state.isRenewal && widget.state.selectedLoanType == null) {
      _preSelectLoanType();
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Monto y tipo de crédito',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa el monto solicitado y selecciona el tipo de crédito',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Amount input (FIRST)
                const Text(
                  'Monto solicitado',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildAmountInputWithButtons(),

                // Quick amount buttons
                const SizedBox(height: 12),
                _buildQuickAmountButtons(),

                const SizedBox(height: 24),

                // Loan type selector (SECOND)
                const Text(
                  'Tipo de crédito',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                loanTypesAsync.when(
                  data: (loanTypes) => _buildLoanTypeCards(loanTypes),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Error al cargar tipos de crédito',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ),

                // Metrics preview
                if (widget.state.calculatedMetrics != null) ...[
                  const SizedBox(height: 24),
                  _buildMetricsPreview(),
                ],

                // Renewal summary
                if (widget.state.isRenewal && widget.state.renewalInfo != null) ...[
                  const SizedBox(height: 16),
                  _buildRenewalSummary(),
                ],
              ],
            ),
          ),
        ),

        // Bottom bar
        WizardBottomBar(
          backLabel: 'Atrás',
          nextLabel: 'Siguiente',
          onBack: () => widget.notifier.previousStep(),
          onNext: widget.state.canProceed ? () => widget.notifier.nextStep() : null,
        ),
      ],
    );
  }

  Widget _buildLoanTypeCards(List<LoanType> loanTypes) {
    if (loanTypes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.alertCircle, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Text(
              'No hay tipos de crédito disponibles',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: loanTypes.map((loanType) {
        return _LoanTypeCard(
          loanType: loanType,
          isSelected: widget.state.selectedLoanType?.id == loanType.id,
          isRenewal: widget.state.isRenewal,
          onTap: () => widget.notifier.selectLoanType(loanType),
        );
      }).toList(),
    );
  }

  Widget _buildAmountInputWithButtons() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Minus button
          _AmountButton(
            icon: LucideIcons.minus,
            onTap: () => _incrementAmount(-500),
          ),
          const SizedBox(width: 8),
          // Amount input
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '\$',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) {
                        final amount = double.tryParse(value) ?? 0;
                        widget.notifier.setRequestedAmount(amount);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Plus button
          _AmountButton(
            icon: LucideIcons.plus,
            onTap: () => _incrementAmount(500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButtons() {
    final quickAmounts = [1000.0, 2000.0, 3000.0, 5000.0, 10000.0];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: quickAmounts.map((amount) {
          final isSelected = widget.state.requestedAmount == amount;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _amountController.text = amount.toStringAsFixed(0);
                  widget.notifier.setRequestedAmount(amount);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    _currencyFormat.format(amount),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricsPreview() {
    final metrics = widget.state.calculatedMetrics!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoSurfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.calculator, size: 18, color: AppColors.info),
              const SizedBox(width: 8),
              const Text(
                'Resumen del crédito',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MetricRow(
            label: 'Monto solicitado',
            value: _currencyFormat.format(widget.state.requestedAmount),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Ganancia (${widget.state.selectedLoanType?.rateDisplay ?? ''})',
            value: _currencyFormat.format(metrics.profitAmount),
            valueColor: AppColors.success,
          ),
          const Divider(height: 24),
          _MetricRow(
            label: 'Deuda total',
            value: _currencyFormat.format(metrics.totalDebtAcquired),
            isBold: true,
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Pago semanal',
            value: _currencyFormat.format(metrics.expectedWeeklyPayment),
            subtitle: '${widget.state.selectedLoanType?.weekDuration ?? 0} semanas',
          ),
          if (widget.state.isRenewal) ...[
            const Divider(height: 24),
            _MetricRow(
              label: 'Monto a entregar',
              value: _currencyFormat.format(widget.state.amountToGive),
              valueColor: AppColors.primary,
              isBold: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRenewalSummary() {
    final renewalInfo = widget.state.renewalInfo!;
    final client = widget.state.selectedClient;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningSurfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.refreshCw, size: 18, color: AppColors.warningDark),
              const SizedBox(width: 8),
              const Text(
                'Renovación',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.warningDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MetricRow(
            label: 'Deuda pendiente',
            value: _currencyFormat.format(renewalInfo.pendingDebt),
            valueColor: AppColors.error,
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Ganancia heredada',
            value: _currencyFormat.format(renewalInfo.inheritedProfit),
            valueColor: AppColors.success,
          ),
          const Divider(height: 24, color: AppColors.warning),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cliente recibe',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _currencyFormat.format(renewalInfo.amountToGive),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Se descuenta la deuda pendiente del monto solicitado',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Loan type card
class _LoanTypeCard extends StatelessWidget {
  final LoanType loanType;
  final bool isSelected;
  final bool isRenewal;
  final VoidCallback onTap;

  const _LoanTypeCard({
    required this.loanType,
    required this.isSelected,
    required this.isRenewal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final commissionRate = isRenewal ? loanType.renewComissionRate : loanType.initialComissionRate;
    final commissionLabel = '${(commissionRate * 100).toStringAsFixed(0)}%';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: (MediaQuery.of(context).size.width - 52) / 2, // Two cards per row
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loanType.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: LucideIcons.percent,
                label: 'Tasa',
                value: loanType.rateDisplay,
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: LucideIcons.calendar,
                label: 'Duración',
                value: loanType.durationDisplay,
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: LucideIcons.coins,
                label: 'Comisión',
                value: commissionLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Info row in loan type card
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Metric row
class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final bool isBold;

  const _MetricRow({
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

/// Amount increment/decrement button
class _AmountButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AmountButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
