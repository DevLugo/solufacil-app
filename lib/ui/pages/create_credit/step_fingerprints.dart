import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:local_auth/local_auth.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../providers/create_credit_provider.dart';
import '../../../providers/collector_dashboard_provider.dart';
import 'create_credit_page.dart';

/// Step 7: Biometric verification (fingerprint/face)
/// For renewals (renovaciones), fingerprint verification is MANDATORY
class StepFingerprints extends ConsumerStatefulWidget {
  final CreateCreditState state;
  final CreateCreditNotifier notifier;
  final bool isRenewal;

  const StepFingerprints({
    super.key,
    required this.state,
    required this.notifier,
    this.isRenewal = false,
  });

  @override
  ConsumerState<StepFingerprints> createState() => _StepFingerprintsState();
}

class _StepFingerprintsState extends ConsumerState<StepFingerprints> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  int _currentPerson = 0; // 0 = borrower, 1 = collateral
  bool _isAuthenticating = false;
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final available = await _localAuth.getAvailableBiometrics();

      setState(() {
        _canCheckBiometrics = canCheck && isDeviceSupported;
        _availableBiometrics = available;
      });
    } on PlatformException catch (_) {
      setState(() {
        _canCheckBiometrics = false;
      });
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating || !_canCheckBiometrics) return;

    setState(() => _isAuthenticating = true);

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: _currentPerson == 0
            ? 'Verificación biométrica del cliente'
            : 'Verificación biométrica del aval',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        if (_currentPerson == 0) {
          widget.notifier.setBorrowerBiometricVerified(true);
        } else {
          widget.notifier.setCollateralBiometricVerified(true);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verificación biométrica exitosa'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de autenticación: ${e.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  String _getBiometricTypeText() {
    if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'huella dactilar';
    } else if (_availableBiometrics.contains(BiometricType.face)) {
      return 'reconocimiento facial';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'reconocimiento de iris';
    }
    return 'biométricos';
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return LucideIcons.scan;
    }
    return LucideIcons.fingerprint;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider directly to get updated state for canProceed
    final selectedRoute = ref.watch(selectedRouteProvider);
    final currentState = ref.watch(createCreditProvider(selectedRoute?.id));

    final fingerprintData = currentState.fingerprintData;
    final hasCollateral = currentState.hasCollateral;
    final clientName = currentState.selectedClient?.fullName ??
                       currentState.newClientInput?.fullName ??
                       'Cliente';
    final collateralName = currentState.selectedCollateral?.fullName ??
                           currentState.newCollateralInput?.fullName ??
                           'Aval';

    final currentVerified = _currentPerson == 0
        ? fingerprintData?.borrowerVerified ?? false
        : fingerprintData?.collateralVerified ?? false;
    final currentVerifiedAt = _currentPerson == 0
        ? fingerprintData?.borrowerVerifiedAt
        : fingerprintData?.collateralVerifiedAt;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Renewal mandatory warning banner
                if (widget.isRenewal) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.alertCircle,
                          size: 24,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RENOVACIÓN - Verificación Obligatoria',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'La huella digital del cliente es requerida para continuar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.error.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Header
                const Text(
                  'Verificación Biométrica',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isRenewal
                      ? 'Verificación obligatoria usando ${_getBiometricTypeText()}'
                      : 'Verifica la identidad usando ${_getBiometricTypeText()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isRenewal ? AppColors.error : AppColors.textSecondary,
                    fontWeight: widget.isRenewal ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 24),

                // Person tabs if has collateral
                if (hasCollateral) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _PersonTab(
                          title: 'Cliente',
                          subtitle: clientName,
                          isSelected: _currentPerson == 0,
                          isVerified: fingerprintData?.borrowerVerified ?? false,
                          onTap: () => setState(() => _currentPerson = 0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PersonTab(
                          title: 'Aval',
                          subtitle: collateralName,
                          isSelected: _currentPerson == 1,
                          isVerified: fingerprintData?.collateralVerified ?? false,
                          onTap: () => setState(() => _currentPerson = 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Biometric availability check
                if (!_canCheckBiometrics) ...[
                  _buildNoBiometricsWarning(),
                ] else ...[
                  // Current person info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getBiometricIcon(),
                          color: AppColors.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verificar: ${_currentPerson == 0 ? clientName : collateralName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                'El ${_currentPerson == 0 ? "cliente" : "aval"} debe colocar su dedo en el sensor',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Verification status or button
                  if (currentVerified) ...[
                    _buildVerifiedCard(currentVerifiedAt),
                  ] else ...[
                    _buildVerifyButton(),
                  ],
                ],

                const SizedBox(height: 24),

                // Status summary
                _buildStatusSummary(fingerprintData, hasCollateral),
              ],
            ),
          ),
        ),

        // Bottom bar
        WizardBottomBar(
          backLabel: 'Atrás',
          nextLabel: 'Siguiente',
          onBack: () => widget.notifier.previousStep(),
          onNext: currentState.canProceed ? () => widget.notifier.nextStep() : null,
        ),
      ],
    );
  }

  Widget _buildNoBiometricsWarning() {
    // For renewals, cannot skip - must have biometrics
    if (widget.isRenewal) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.errorSurfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              LucideIcons.shieldAlert,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Verificación Obligatoria',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Para renovaciones, la verificación biométrica es OBLIGATORIA.\n\nEste dispositivo no tiene sensor biométrico configurado. Por favor usa otro dispositivo con huella digital.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.info, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                    'No puedes continuar sin verificación',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // For new credits, can skip
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warningSurfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.alertTriangle,
            size: 48,
            color: AppColors.warning,
          ),
          const SizedBox(height: 16),
          const Text(
            'Biométricos no disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este dispositivo no tiene sensor biométrico configurado o no está disponible.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Skip biometric verification
              widget.notifier.setBorrowerBiometricVerified(true);
            },
            icon: const Icon(LucideIcons.skipForward, size: 18),
            label: const Text('Omitir verificación'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isAuthenticating ? null : _authenticate,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _isAuthenticating
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: _isAuthenticating
                      ? const Center(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        )
                      : Icon(
                          _getBiometricIcon(),
                          size: 48,
                          color: AppColors.primary,
                        ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isAuthenticating ? 'Verificando...' : 'Toca para verificar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _isAuthenticating ? AppColors.textSecondary : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'El ${_currentPerson == 0 ? "cliente" : "aval"} debe usar su ${_getBiometricTypeText()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedCard(DateTime? verifiedAt) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.successSurfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.checkCircle,
                size: 40,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verificación Exitosa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
            if (verifiedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Verificado: ${_dateFormat.format(verifiedAt)}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Verificar de nuevo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSummary(FingerprintData? data, bool hasCollateral) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _StatusRow(
            label: 'Verificación del cliente',
            isComplete: data?.borrowerVerified ?? false,
            isRequired: true,
          ),
          if (hasCollateral) ...[
            const SizedBox(height: 12),
            _StatusRow(
              label: 'Verificación del aval',
              isComplete: data?.collateralVerified ?? false,
              isRequired: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Person tab button
class _PersonTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isVerified;
  final VoidCallback onTap;

  const _PersonTab({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isVerified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isVerified)
                Icon(
                  LucideIcons.checkCircle,
                  size: 20,
                  color: AppColors.success,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status row widget
class _StatusRow extends StatelessWidget {
  final String label;
  final bool isComplete;
  final bool isRequired;

  const _StatusRow({
    required this.label,
    required this.isComplete,
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isComplete ? LucideIcons.checkCircle : LucideIcons.circle,
          size: 20,
          color: isComplete ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isComplete ? AppColors.success : AppColors.textSecondary,
                  fontWeight: isComplete ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        Text(
          isComplete ? 'Completado' : 'Pendiente',
          style: TextStyle(
            fontSize: 12,
            color: isComplete ? AppColors.success : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
