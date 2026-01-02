import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../providers/create_credit_provider.dart';
import 'create_credit_page.dart';

/// Step 5: Review and confirm loan creation
class StepConfirmation extends ConsumerWidget {
  final CreateCreditState state;
  final CreateCreditNotifier notifier;

  const StepConfirmation({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('d MMM yyyy', 'es');

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Confirmar crédito',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Revisa los datos antes de crear',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.isRenewal)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warningSurfaceLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.refreshCw, size: 14, color: AppColors.warningDark),
                            const SizedBox(width: 6),
                            Text(
                              'Renovación',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warningDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Error message
                if (state.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.alertCircle, color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.x, size: 18, color: AppColors.error),
                          onPressed: () => notifier.clearError(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Client section
                _buildSectionCard(
                  icon: LucideIcons.user,
                  title: 'Cliente',
                  onEdit: () => notifier.goToStep(CreditWizardStep.client),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                state.selectedClient?.fullName.isNotEmpty == true
                                    ? state.selectedClient!.fullName[0].toUpperCase()
                                    : state.newClientInput?.fullName.isNotEmpty == true
                                        ? state.newClientInput!.fullName[0].toUpperCase()
                                        : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.selectedClient?.fullName ?? state.newClientInput?.fullName ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (state.selectedClient?.phone != null || state.newClientInput?.phone != null)
                                  Text(
                                    state.selectedClient?.phone ?? state.newClientInput?.phone ?? '',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                if (state.isNewClient)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.infoSurfaceLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Nuevo cliente',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.info,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Loan type section
                _buildSectionCard(
                  icon: LucideIcons.creditCard,
                  title: 'Crédito',
                  onEdit: () => notifier.goToStep(CreditWizardStep.loanType),
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Tipo',
                        value: state.selectedLoanType?.name ?? 'No seleccionado',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Monto solicitado',
                        value: currencyFormat.format(state.requestedAmount),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Tasa',
                        value: state.selectedLoanType?.rateDisplay ?? '0%',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Duración',
                        value: state.selectedLoanType?.durationDisplay ?? '0 semanas',
                      ),
                      if (state.calculatedMetrics != null) ...[
                        const Divider(height: 24),
                        _InfoRow(
                          label: 'Ganancia',
                          value: currencyFormat.format(state.calculatedMetrics!.profitAmount),
                          valueColor: AppColors.success,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Deuda total',
                          value: currencyFormat.format(state.calculatedMetrics!.totalDebtAcquired),
                          isBold: true,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Pago semanal',
                          value: currencyFormat.format(state.calculatedMetrics!.expectedWeeklyPayment),
                        ),
                      ],
                    ],
                  ),
                ),

                // Renewal section
                if (state.isRenewal && state.renewalInfo != null) ...[
                  const SizedBox(height: 16),
                  Container(
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
                        _InfoRow(
                          label: 'Deuda anterior',
                          value: currencyFormat.format(state.renewalInfo!.pendingDebt),
                          valueColor: AppColors.error,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Ganancia heredada',
                          value: currencyFormat.format(state.renewalInfo!.inheritedProfit),
                          valueColor: AppColors.success,
                        ),
                        const Divider(height: 24, color: AppColors.warning),
                        _InfoRow(
                          label: 'Cliente recibe',
                          value: currencyFormat.format(state.renewalInfo!.amountToGive),
                          valueColor: AppColors.primary,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ] else if (state.amountToGive > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGradient.colors.first.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Monto a entregar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          currencyFormat.format(state.amountToGive),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Collateral section
                if (state.hasCollateral) ...[
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    icon: LucideIcons.shield,
                    title: 'Aval',
                    onEdit: () => notifier.goToStep(CreditWizardStep.collateral),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.successSurfaceLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(LucideIcons.shield, size: 20, color: AppColors.success),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.selectedCollateral?.fullName ?? state.newCollateralInput?.fullName ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              if (state.selectedCollateral?.phone != null || state.newCollateralInput?.phone != null)
                                Text(
                                  state.selectedCollateral?.phone ?? state.newCollateralInput?.phone ?? '',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              if (state.isNewCollateral)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.infoSurfaceLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Nuevo aval',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // First payment section
                if (state.hasFirstPayment && state.firstPayment != null) ...[
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    icon: LucideIcons.banknote,
                    title: 'Primer pago',
                    onEdit: () => notifier.goToStep(CreditWizardStep.firstPayment),
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Monto',
                          value: currencyFormat.format(state.firstPayment!.amount),
                          valueColor: AppColors.success,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Método',
                          value: state.firstPayment!.isCash ? 'Efectivo' : 'Transferencia',
                        ),
                        if (state.firstPayment!.commissionAmount > 0) ...[
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Comisión',
                            value: currencyFormat.format(state.firstPayment!.commissionAmount),
                            valueColor: AppColors.error,
                          ),
                        ],
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Fecha',
                          value: dateFormat.format(DateTime.now()),
                        ),
                      ],
                    ),
                  ),
                ],

                // Info note
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.infoSurfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.cloudOff, size: 20, color: AppColors.info),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'El crédito se guardará localmente y se sincronizará automáticamente cuando haya conexión a internet.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom bar
        WizardBottomBar(
          backLabel: 'Atrás',
          nextLabel: state.isRenewal ? 'Renovar Crédito' : 'Crear Crédito',
          onBack: () => notifier.previousStep(),
          onNext: () => notifier.submit(),
          isLoading: state.isSubmitting,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required VoidCallback onEdit,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(LucideIcons.pencil, size: 14),
                label: const Text('Editar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}

/// Info row widget
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _InfoRow({
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
            fontSize: 13,
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
