import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../core/theme/colors.dart';
import '../../../providers/create_credit_provider.dart';
import '../../../providers/collector_dashboard_provider.dart';
import 'create_credit_page.dart';

/// Step 5: Document photos (INE, proof of address, promissory note)
class StepDocuments extends ConsumerStatefulWidget {
  final CreateCreditState state;
  final CreateCreditNotifier notifier;

  const StepDocuments({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  ConsumerState<StepDocuments> createState() => _StepDocumentsState();
}

class _StepDocumentsState extends ConsumerState<StepDocuments> {
  final _imagePicker = ImagePicker();
  bool _isCapturing = false;

  Future<String?> _capturePhoto() async {
    if (_isCapturing) return null;

    setState(() => _isCapturing = true);

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) return null;

      // Save to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = path.join(appDir.path, 'documents', fileName);

      // Create directory if it doesn't exist
      final dir = Directory(path.dirname(savedPath));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Copy file to permanent location
      await File(image.path).copy(savedPath);

      return savedPath;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al capturar foto: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      return null;
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider directly to get updated state for canProceed
    final selectedRoute = ref.watch(selectedRouteProvider);
    final currentState = ref.watch(createCreditProvider(selectedRoute?.id));

    final docs = currentState.documentPhotosData;
    final hasCollateral = currentState.hasCollateral;
    final clientName = currentState.selectedClient?.fullName ??
                       currentState.newClientInput?.fullName ??
                       'Cliente';

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
                  'Documentos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Captura las fotos de los documentos requeridos',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Borrower documents section
                _buildSectionHeader(
                  icon: LucideIcons.user,
                  title: 'Documentos del Cliente',
                  subtitle: clientName,
                ),
                const SizedBox(height: 16),

                // INE Front
                _DocumentPhotoCard(
                  title: 'INE - Frente',
                  subtitle: 'Foto clara del frente de la identificación',
                  icon: LucideIcons.creditCard,
                  imagePath: docs?.borrowerIneFrontPath,
                  isRequired: true,
                  isCapturing: _isCapturing,
                  onCapture: () async {
                    final path = await _capturePhoto();
                    if (path != null) {
                      widget.notifier.setBorrowerIneFront(path);
                    }
                  },
                  onClear: () {
                    // Clear via notifier if needed
                  },
                ),
                const SizedBox(height: 12),

                // INE Back
                _DocumentPhotoCard(
                  title: 'INE - Reverso',
                  subtitle: 'Foto clara del reverso de la identificación',
                  icon: LucideIcons.creditCard,
                  imagePath: docs?.borrowerIneBackPath,
                  isRequired: true,
                  isCapturing: _isCapturing,
                  onCapture: () async {
                    final path = await _capturePhoto();
                    if (path != null) {
                      widget.notifier.setBorrowerIneBack(path);
                    }
                  },
                  onClear: () {},
                ),
                const SizedBox(height: 12),

                // Proof of address
                _DocumentPhotoCard(
                  title: 'Comprobante de Domicilio',
                  subtitle: 'Recibo de luz, agua, teléfono (máx. 3 meses)',
                  icon: LucideIcons.home,
                  imagePath: docs?.borrowerProofOfAddressPath,
                  isRequired: true,
                  isCapturing: _isCapturing,
                  onCapture: () async {
                    final path = await _capturePhoto();
                    if (path != null) {
                      widget.notifier.setBorrowerProofOfAddress(path);
                    }
                  },
                  onClear: () {},
                ),
                const SizedBox(height: 12),

                // Signed promissory note (optional at this stage)
                _DocumentPhotoCard(
                  title: 'Pagaré Firmado',
                  subtitle: 'Foto del pagaré con la firma del cliente',
                  icon: LucideIcons.fileSignature,
                  imagePath: docs?.signedPromissoryNotePath,
                  isRequired: false,
                  isCapturing: _isCapturing,
                  onCapture: () async {
                    final path = await _capturePhoto();
                    if (path != null) {
                      widget.notifier.setSignedPromissoryNote(path);
                    }
                  },
                  onClear: () {},
                ),

                // Collateral documents if applicable
                if (hasCollateral) ...[
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    icon: LucideIcons.shield,
                    title: 'Documentos del Aval',
                    subtitle: currentState.selectedCollateral?.fullName ??
                             currentState.newCollateralInput?.fullName ??
                             'Aval',
                  ),
                  const SizedBox(height: 16),

                  // Collateral INE Front
                  _DocumentPhotoCard(
                    title: 'INE - Frente (Aval)',
                    subtitle: 'Foto clara del frente de la identificación',
                    icon: LucideIcons.creditCard,
                    imagePath: docs?.collateralIneFrontPath,
                    isRequired: false,
                    isCapturing: _isCapturing,
                    onCapture: () async {
                      final path = await _capturePhoto();
                      if (path != null) {
                        widget.notifier.setCollateralIneFront(path);
                      }
                    },
                    onClear: () {},
                  ),
                  const SizedBox(height: 12),

                  // Collateral INE Back
                  _DocumentPhotoCard(
                    title: 'INE - Reverso (Aval)',
                    subtitle: 'Foto clara del reverso de la identificación',
                    icon: LucideIcons.creditCard,
                    imagePath: docs?.collateralIneBackPath,
                    isRequired: false,
                    isCapturing: _isCapturing,
                    onCapture: () async {
                      final path = await _capturePhoto();
                      if (path != null) {
                        widget.notifier.setCollateralIneBack(path);
                      }
                    },
                    onClear: () {},
                  ),
                  const SizedBox(height: 12),

                  // Collateral proof of address
                  _DocumentPhotoCard(
                    title: 'Comprobante de Domicilio (Aval)',
                    subtitle: 'Recibo de luz, agua, teléfono (máx. 3 meses)',
                    icon: LucideIcons.home,
                    imagePath: docs?.collateralProofOfAddressPath,
                    isRequired: false,
                    isCapturing: _isCapturing,
                    onCapture: () async {
                      final path = await _capturePhoto();
                      if (path != null) {
                        widget.notifier.setCollateralProofOfAddress(path);
                      }
                    },
                    onClear: () {},
                  ),
                ],

                const SizedBox(height: 24),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.infoSurfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, size: 20, color: AppColors.info),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Asegúrate de que las fotos sean claras y legibles. Los documentos marcados con * son obligatorios.',
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
          nextLabel: 'Siguiente',
          onBack: () => widget.notifier.previousStep(),
          onNext: currentState.canProceed ? () => widget.notifier.nextStep() : null,
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Document photo card widget
class _DocumentPhotoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? imagePath;
  final bool isRequired;
  final bool isCapturing;
  final VoidCallback onCapture;
  final VoidCallback onClear;

  const _DocumentPhotoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.imagePath,
    required this.isRequired,
    required this.isCapturing,
    required this.onCapture,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasImage ? AppColors.success : AppColors.border,
          width: hasImage ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCapturing ? null : onCapture,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Thumbnail or icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: hasImage
                        ? AppColors.successSurfaceLight
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    image: hasImage
                        ? DecorationImage(
                            image: FileImage(File(imagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: hasImage
                      ? null
                      : Icon(
                          icon,
                          size: 28,
                          color: AppColors.textMuted,
                        ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.textPrimary,
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
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (hasImage) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.checkCircle,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Capturado',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Action
                if (isCapturing)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (hasImage)
                  IconButton(
                    onPressed: onCapture,
                    icon: Icon(
                      LucideIcons.refreshCw,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  Icon(
                    LucideIcons.camera,
                    size: 24,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
