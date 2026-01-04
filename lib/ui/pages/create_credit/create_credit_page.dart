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
import 'step_documents.dart';
import 'step_signature.dart';
import 'step_fingerprints.dart';
import 'step_video.dart';
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
    // Define step groups for compact display
    final stepInfo = _getStepInfo(state.currentStep);

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
          // Current step info
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${state.stepNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
                      stepInfo.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Paso ${state.stepNumber} de ${state.totalSteps}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                stepInfo.icon,
                color: AppColors.primary,
                size: 24,
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

  _StepInfo _getStepInfo(CreditWizardStep step) {
    switch (step) {
      case CreditWizardStep.client:
        return _StepInfo('Seleccionar Cliente', LucideIcons.user);
      case CreditWizardStep.loanType:
        return _StepInfo('Tipo de Crédito', LucideIcons.banknote);
      case CreditWizardStep.collateral:
        return _StepInfo('Aval (Opcional)', LucideIcons.shield);
      case CreditWizardStep.firstPayment:
        return _StepInfo('Primer Pago', LucideIcons.wallet);
      case CreditWizardStep.documents:
        return _StepInfo('Documentos', LucideIcons.fileText);
      case CreditWizardStep.signature:
        return _StepInfo('Firma Digital', LucideIcons.penTool);
      case CreditWizardStep.fingerprints:
        return _StepInfo('Huellas Dactilares', LucideIcons.fingerprint);
      case CreditWizardStep.videoRecording:
        return _StepInfo('Grabación de Video', LucideIcons.video);
      case CreditWizardStep.confirmation:
        return _StepInfo('Confirmación', LucideIcons.checkCircle);
    }
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
      case CreditWizardStep.documents:
        return StepDocuments(state: state, notifier: notifier);
      case CreditWizardStep.signature:
        return StepSignature(state: state, notifier: notifier);
      case CreditWizardStep.fingerprints:
        return StepFingerprints(
          state: state,
          notifier: notifier,
          isRenewal: state.isRenewal,
        );
      case CreditWizardStep.videoRecording:
        return StepVideo(state: state, notifier: notifier);
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

/// Step info helper class
class _StepInfo {
  final String title;
  final IconData icon;

  const _StepInfo(this.title, this.icon);
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
