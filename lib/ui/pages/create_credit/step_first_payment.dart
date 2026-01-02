import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../providers/create_credit_provider.dart';
import 'create_credit_page.dart';

/// Step 4: Optional first payment registration
class StepFirstPayment extends ConsumerStatefulWidget {
  final CreateCreditState state;
  final CreateCreditNotifier notifier;

  const StepFirstPayment({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  ConsumerState<StepFirstPayment> createState() => _StepFirstPaymentState();
}

class _StepFirstPaymentState extends ConsumerState<StepFirstPayment> {
  final _amountController = TextEditingController();
  final _commissionController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    if (widget.state.firstPayment != null) {
      _amountController.text = widget.state.firstPayment!.amount.toStringAsFixed(0);
      _commissionController.text = widget.state.firstPayment!.commissionAmount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  'Primer Pago (Opcional)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '¿El cliente quiere realizar un pago hoy?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Toggle first payment
                _buildFirstPaymentToggle(),

                // First payment content
                if (widget.state.hasFirstPayment) ...[
                  const SizedBox(height: 24),

                  // Amount input
                  _buildAmountSection(),

                  const SizedBox(height: 24),

                  // Payment method
                  _buildPaymentMethodSection(),

                  const SizedBox(height: 24),

                  // Commission (optional)
                  _buildCommissionSection(),

                  const SizedBox(height: 24),

                  // Summary
                  _buildPaymentSummary(),
                ],
              ],
            ),
          ),
        ),

        // Bottom bar
        WizardBottomBar(
          backLabel: 'Atrás',
          nextLabel: widget.state.hasFirstPayment ? 'Siguiente' : 'Omitir',
          onBack: () => widget.notifier.previousStep(),
          onNext: () => widget.notifier.nextStep(),
        ),
      ],
    );
  }

  Widget _buildFirstPaymentToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.state.hasFirstPayment
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.banknote,
              color: widget.state.hasFirstPayment ? AppColors.success : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Registrar primer pago?',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'El pago se registrará con fecha de hoy',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.state.hasFirstPayment,
            onChanged: (value) {
              widget.notifier.toggleFirstPayment(value);
              if (value && widget.state.calculatedMetrics != null) {
                _amountController.text = widget.state.calculatedMetrics!.expectedWeeklyPayment.toStringAsFixed(0);
              }
            },
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    final suggestedAmount = widget.state.calculatedMetrics?.expectedWeeklyPayment ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monto del pago',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Amount input
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              const Text(
                '\$',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    final amount = double.tryParse(value) ?? 0;
                    widget.notifier.setFirstPaymentAmount(amount);
                  },
                ),
              ),
            ],
          ),
        ),

        // Suggested amount
        if (suggestedAmount > 0) ...[
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _amountController.text = suggestedAmount.toStringAsFixed(0);
                widget.notifier.setFirstPaymentAmount(suggestedAmount);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.successSurfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.lightbulb, size: 18, color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pago semanal sugerido',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _currencyFormat.format(suggestedAmount),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Usar',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    final isCash = widget.state.firstPayment?.isCash ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Método de pago',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PaymentMethodCard(
                icon: LucideIcons.banknote,
                label: 'Efectivo',
                isSelected: isCash,
                onTap: () => widget.notifier.setFirstPaymentMethod(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PaymentMethodCard(
                icon: LucideIcons.creditCard,
                label: 'Transferencia',
                isSelected: !isCash,
                onTap: () => widget.notifier.setFirstPaymentMethod(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommissionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Comisión por pago',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Opcional',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                '\$',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _commissionController,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    final commission = double.tryParse(value) ?? 0;
                    widget.notifier.setFirstPaymentCommission(commission);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Se descontará del pago registrado',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    final payment = widget.state.firstPayment;
    if (payment == null) return const SizedBox.shrink();

    final netPayment = payment.amount - payment.commissionAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successSurfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.receipt, size: 18, color: AppColors.success),
              const SizedBox(width: 8),
              const Text(
                'Resumen del pago',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            label: 'Monto del pago',
            value: _currencyFormat.format(payment.amount),
          ),
          if (payment.commissionAmount > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Comisión',
              value: '- ${_currencyFormat.format(payment.commissionAmount)}',
              valueColor: AppColors.error,
            ),
            const Divider(height: 24),
            _SummaryRow(
              label: 'Pago neto a registrar',
              value: _currencyFormat.format(netPayment),
              isBold: true,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                payment.isCash ? LucideIcons.banknote : LucideIcons.creditCard,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                payment.isCash ? 'Efectivo' : 'Transferencia',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Payment method card
class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.success.withOpacity(0.1) : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.success : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? AppColors.success : AppColors.textMuted,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Summary row
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
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
