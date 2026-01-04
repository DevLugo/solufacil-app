import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/payment_input.dart';
import '../../providers/collection_provider.dart';

/// Shows the distribution bottom sheet for finalizing day's payments
Future<bool?> showDistributionSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const DistributionSheet(),
  );
}

class DistributionSheet extends ConsumerStatefulWidget {
  const DistributionSheet({super.key});

  @override
  ConsumerState<DistributionSheet> createState() => _DistributionSheetState();
}

class _DistributionSheetState extends ConsumerState<DistributionSheet> {
  final _bankTransferController = TextEditingController();
  final _falcoController = TextEditingController();
  bool _isLoading = false;

  double get _bankTransferAmount => _parseAmount(_bankTransferController.text);
  double get _falcoAmount => _parseAmount(_falcoController.text);

  double _parseAmount(String text) => double.tryParse(text) ?? 0;

  @override
  void dispose() {
    _bankTransferController.dispose();
    _falcoController.dispose();
    super.dispose();
  }

  Future<void> _savePayments() async {
    final dayState = ref.read(dayPaymentStateProvider);
    if (dayState == null) return;

    setState(() => _isLoading = true);

    try {
      await _performSave(dayState);
      if (!mounted) return;

      _showSuccessAndClose(dayState.paymentCount);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _performSave(DayPaymentState dayState) async {
    final repository = ref.read(paymentRepositoryProvider);
    if (repository == null) {
      throw Exception('Database not ready');
    }

    await repository.saveDayPayments(dayState);
    ref.read(dayPaymentStateProvider.notifier).clear();
  }

  void _showSuccessAndClose(int paymentCount) {
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$paymentCount pagos guardados correctamente'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showErrorSnackbar(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al guardar: $error'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  double _calculateCashPaidAmount(double totalCash) {
    return totalCash - _bankTransferAmount - _falcoAmount;
  }

  double _calculateBankPaidAmount(double totalBank) {
    return totalBank + _bankTransferAmount;
  }

  @override
  Widget build(BuildContext context) {
    final dayState = ref.watch(dayPaymentStateProvider);
    if (dayState == null) return const SizedBox.shrink();

    final cashPaidAmount = _calculateCashPaidAmount(dayState.totalCash);
    final bankPaidAmount = _calculateBankPaidAmount(dayState.totalBank);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Row(
                children: [
                  Icon(LucideIcons.receipt, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Distribución del Día',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      '${dayState.paymentCount} pagos',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Summary section
              _SummarySection(
                totalCollected: dayState.totalCollected,
                totalCash: dayState.totalCash,
                totalBank: dayState.totalBank,
                totalComission: dayState.totalComission,
                noPaymentCount: dayState.noPaymentCount,
              ),

              const SizedBox(height: 24),

              // Distribution inputs
              _DistributionInputs(
                totalCash: dayState.totalCash,
                bankTransferController: _bankTransferController,
                falcoController: _falcoController,
                onChanged: () => setState(() {}),
              ),

              const SizedBox(height: 24),

              // Final distribution
              _FinalDistribution(
                cashPaidAmount: cashPaidAmount,
                bankPaidAmount: bankPaidAmount,
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePayments,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.save,
                                    size: 18, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Guardar Día',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final double totalCollected;
  final double totalCash;
  final double totalBank;
  final double totalComission;
  final int noPaymentCount;

  const _SummarySection({
    required this.totalCollected,
    required this.totalCash,
    required this.totalBank,
    required this.totalComission,
    required this.noPaymentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Total Cobrado',
            value: formatCurrency(totalCollected),
            color: AppColors.success,
            isTotal: true,
          ),
          const Divider(height: 24),
          _SummaryRow(
            icon: LucideIcons.banknote,
            label: 'En Efectivo',
            value: formatCurrency(totalCash),
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            icon: LucideIcons.creditCard,
            label: 'Transferencias',
            value: formatCurrency(totalBank),
            color: AppColors.info,
          ),
          if (totalComission > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              icon: LucideIcons.coins,
              label: 'Comisiones',
              value: formatCurrency(totalComission),
              color: AppColors.warning,
            ),
          ],
          if (noPaymentCount > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              icon: LucideIcons.userX,
              label: 'Sin Pago',
              value: '$noPaymentCount clientes',
              color: AppColors.error,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final Color color;
  final bool isTotal;

  const _SummaryRow({
    this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.secondary : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DistributionInputs extends StatelessWidget {
  final double totalCash;
  final TextEditingController bankTransferController;
  final TextEditingController falcoController;
  final VoidCallback onChanged;

  const _DistributionInputs({
    required this.totalCash,
    required this.bankTransferController,
    required this.falcoController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribución del Efectivo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tienes ${formatCurrency(totalCash)} en efectivo. ¿Cuánto depositas al banco?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        // Bank transfer input
        _AmountInput(
          label: 'Depósito al Banco',
          icon: LucideIcons.building2,
          controller: bankTransferController,
          maxAmount: totalCash,
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),

        // FALCO input (optional)
        _AmountInput(
          label: 'FALCO (Pérdida de efectivo)',
          icon: LucideIcons.alertTriangle,
          controller: falcoController,
          maxAmount: totalCash,
          onChanged: onChanged,
          isOptional: true,
        ),
      ],
    );
  }
}

class _AmountInput extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final double maxAmount;
  final VoidCallback onChanged;
  final bool isOptional;

  const _AmountInput({
    required this.label,
    required this.icon,
    required this.controller,
    required this.maxAmount,
    required this.onChanged,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (isOptional)
              Text(
                ' (opcional)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            prefixText: '\$ ',
            hintText: '0',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _FinalDistribution extends StatelessWidget {
  final double cashPaidAmount;
  final double bankPaidAmount;

  const _FinalDistribution({
    required this.cashPaidAmount,
    required this.bankPaidAmount,
  });

  @override
  Widget build(BuildContext context) {
    final isNegativeCash = cashPaidAmount < 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNegativeCash
            ? AppColors.error.withOpacity(0.1)
            : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isNegativeCash ? AppColors.error : AppColors.primary,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Resultado Final',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ResultItem(
                  icon: LucideIcons.wallet,
                  label: 'Efectivo',
                  value: formatCurrency(cashPaidAmount),
                  color: isNegativeCash ? AppColors.error : AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.border,
              ),
              Expanded(
                child: _ResultItem(
                  icon: LucideIcons.building2,
                  label: 'Banco',
                  value: formatCurrency(bankPaidAmount),
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          if (isNegativeCash) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.alertCircle, size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El monto a depositar excede el efectivo disponible',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResultItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
