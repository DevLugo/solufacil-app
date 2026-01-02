import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/colors.dart';
import '../../../providers/create_credit_provider.dart';
import '../../../providers/collector_dashboard_provider.dart';

import 'step_client.dart';
import 'step_loan_type.dart';
import 'step_collateral.dart';
import 'step_first_payment.dart';
import 'step_confirmation.dart';

/// Main wizard page for creating/renewing credits
class CreateCreditPage extends ConsumerStatefulWidget {
  const CreateCreditPage({super.key});

  @override
  ConsumerState<CreateCreditPage> createState() => _CreateCreditPageState();
}

class _CreateCreditPageState extends ConsumerState<CreateCreditPage> {
  @override
  Widget build(BuildContext context) {
    final selectedRoute = ref.watch(selectedRouteProvider);
    final state = ref.watch(createCreditProvider(selectedRoute?.id));
    final notifier = ref.read(createCreditProvider(selectedRoute?.id).notifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () {
            if (state.currentStep.index > 0) {
              notifier.previousStep();
            } else {
              _showExitConfirmation(context, notifier);
            }
          },
        ),
        title: Text(
          state.isRenewal ? 'Renovar Crédito' : 'Nuevo Crédito',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          if (selectedRoute != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.mapPin, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        selectedRoute.name,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(state),

          // Step content
          Expanded(
            child: _buildStepContent(state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(CreateCreditState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Step labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepLabel(
                step: 1,
                label: 'Cliente',
                isActive: state.currentStep.index >= 0,
                isCurrent: state.currentStep == CreditWizardStep.client,
              ),
              _StepLabel(
                step: 2,
                label: 'Tipo',
                isActive: state.currentStep.index >= 1,
                isCurrent: state.currentStep == CreditWizardStep.loanType,
              ),
              _StepLabel(
                step: 3,
                label: 'Aval',
                isActive: state.currentStep.index >= 2,
                isCurrent: state.currentStep == CreditWizardStep.collateral,
              ),
              _StepLabel(
                step: 4,
                label: 'Pago',
                isActive: state.currentStep.index >= 3,
                isCurrent: state.currentStep == CreditWizardStep.firstPayment,
              ),
              _StepLabel(
                step: 5,
                label: 'Confirmar',
                isActive: state.currentStep.index >= 4,
                isCurrent: state.currentStep == CreditWizardStep.confirmation,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progress / 100,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(CreateCreditState state, CreateCreditNotifier notifier) {
    // Show success screen if loan was created
    if (state.isSuccess && state.createdLoanId != null) {
      return _buildSuccessScreen(state, notifier);
    }

    switch (state.currentStep) {
      case CreditWizardStep.client:
        return StepClient(state: state, notifier: notifier);
      case CreditWizardStep.loanType:
        return StepLoanType(state: state, notifier: notifier);
      case CreditWizardStep.collateral:
        return StepCollateral(state: state, notifier: notifier);
      case CreditWizardStep.firstPayment:
        return StepFirstPayment(state: state, notifier: notifier);
      case CreditWizardStep.confirmation:
        return StepConfirmation(state: state, notifier: notifier);
    }
  }

  Widget _buildSuccessScreen(CreateCreditState state, CreateCreditNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success animation placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.successSurfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.checkCircle,
              size: 64,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            state.isRenewal ? 'Crédito Renovado' : 'Crédito Creado',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'El crédito se ha registrado exitosamente',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Se sincronizará automáticamente cuando haya conexión',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    notifier.reset();
                    // Stay on the page for a new credit
                  },
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Nuevo Crédito'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.pop();
                  },
                  icon: const Icon(LucideIcons.home),
                  label: const Text('Ir al Inicio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context, CreateCreditNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('¿Salir del wizard?'),
        content: const Text('Se perderán los datos ingresados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.reset();
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

/// Step label widget
class _StepLabel extends StatelessWidget {
  final int step;
  final String label;
  final bool isActive;
  final bool isCurrent;

  const _StepLabel({
    required this.step,
    required this.label,
    required this.isActive,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.primary
                : isActive
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.border,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? Icon(
                    LucideIcons.check,
                    size: 14,
                    color: AppColors.primary,
                  )
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isCurrent ? Colors.white : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isCurrent ? AppColors.primary : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// Bottom action bar for wizard steps
class WizardBottomBar extends StatelessWidget {
  final String? backLabel;
  final String nextLabel;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final bool isLoading;
  final bool showBackButton;

  const WizardBottomBar({
    super.key,
    this.backLabel,
    required this.nextLabel,
    this.onBack,
    this.onNext,
    this.isLoading = false,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (showBackButton && onBack != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(backLabel ?? 'Atrás'),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              flex: showBackButton ? 2 : 1,
              child: ElevatedButton(
                onPressed: isLoading ? null : onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        nextLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
