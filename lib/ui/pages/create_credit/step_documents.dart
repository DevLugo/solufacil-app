import 'dart:io';
import 'dart:ui' as ui;
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

/// Laplacian variance threshold for blur detection
/// Values BELOW this threshold indicate a blurry image
/// Based on OpenCV best practices: ~100 is the standard threshold
/// Lower values = more strict (rejects more photos)
const double _blurThreshold = 100.0;

/// Result of blur analysis
class _BlurAnalysisResult {
  final double variance;
  final bool isBlurry;

  _BlurAnalysisResult({required this.variance, required this.isBlurry});

  /// Convert variance to a 0-100 quality score for display
  /// Maps: 0 variance -> 0%, 100 variance -> 50%, 500+ variance -> 100%
  int get qualityPercent {
    if (variance <= 0) return 0;
    if (variance >= 500) return 100;
    // Linear mapping: variance 100 = 50%
    return ((variance / 500) * 100).round().clamp(0, 100);
  }
}

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
  bool _isAnalyzing = false;

  /// Analyze image quality using Laplacian variance method
  /// Returns the Laplacian variance - higher values mean sharper image
  /// Based on OpenCV best practice: variance < 100 = blurry
  /// Reference: https://www.geeksforgeeks.org/computer-vision/how-to-check-for-blurry-images-in-your-dataset-using-the-laplacian-method/
  Future<_BlurAnalysisResult> _analyzeImageQuality(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final width = image.width;
      final height = image.height;

      debugPrint('[BlurDetection] Analyzing image: ${width}x$height');

      // Get pixel data
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        debugPrint('[BlurDetection] Could not get byte data');
        return _BlurAnalysisResult(variance: 200, isBlurry: false); // Assume OK
      }

      final pixels = byteData.buffer.asUint8List();

      // Convert to grayscale array for Laplacian calculation
      final grayscale = List<double>.filled(width * height, 0);
      for (int i = 0; i < width * height; i++) {
        final idx = i * 4;
        if (idx + 2 < pixels.length) {
          // Standard grayscale conversion (ITU-R BT.601)
          grayscale[i] = pixels[idx] * 0.299 + pixels[idx + 1] * 0.587 + pixels[idx + 2] * 0.114;
        }
      }

      // Apply Laplacian operator (3x3 kernel: [0,1,0], [1,-4,1], [0,1,0])
      // and collect all Laplacian values
      final laplacianValues = <double>[];

      for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          final center = grayscale[y * width + x];
          final up = grayscale[(y - 1) * width + x];
          final down = grayscale[(y + 1) * width + x];
          final left = grayscale[y * width + (x - 1)];
          final right = grayscale[y * width + (x + 1)];

          // Laplacian = 4*center - up - down - left - right
          final laplacian = 4 * center - up - down - left - right;
          laplacianValues.add(laplacian);
        }
      }

      if (laplacianValues.isEmpty) {
        return _BlurAnalysisResult(variance: 200, isBlurry: false);
      }

      // Calculate variance: Var(X) = E[X²] - E[X]²
      double sum = 0;
      double sumSq = 0;
      for (final val in laplacianValues) {
        sum += val;
        sumSq += val * val;
      }

      final mean = sum / laplacianValues.length;
      final variance = (sumSq / laplacianValues.length) - (mean * mean);

      // Determine if blurry based on threshold
      final isBlurry = variance < _blurThreshold;

      debugPrint('[BlurDetection] Laplacian variance: ${variance.toStringAsFixed(2)}');
      debugPrint('[BlurDetection] Threshold: $_blurThreshold');
      debugPrint('[BlurDetection] Is blurry: $isBlurry');

      return _BlurAnalysisResult(variance: variance, isBlurry: isBlurry);
    } catch (e, stack) {
      debugPrint('[BlurDetection] Error: $e');
      debugPrint('[BlurDetection] Stack: $stack');
      return _BlurAnalysisResult(variance: 200, isBlurry: false); // Assume OK on error
    }
  }

  /// Show dialog asking user to retake blurry photo
  Future<bool> _showBlurryPhotoDialog(_BlurAnalysisResult analysis) async {
    final qualityPercent = analysis.qualityPercent;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Foto Borrosa', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La foto está desenfocada y puede ser ilegible.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorSurfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Nitidez: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: qualityPercent / 100,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$qualityPercent%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Varianza: ${analysis.variance.toStringAsFixed(0)} (mínimo requerido: ${_blurThreshold.toInt()})',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoSurfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.lightbulb, size: 16, color: AppColors.info),
                      const SizedBox(width: 8),
                      Text(
                        'Consejos para mejor foto:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Buena iluminación (sin sombras)\n'
                    '• Mantén el celular firme\n'
                    '• Espera a que enfoque antes de capturar\n'
                    '• Evita movimiento al tomar la foto',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Usar de todos modos',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(LucideIcons.camera, size: 18),
            label: const Text('Tomar otra'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

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

      // Analyze image quality using Laplacian variance
      setState(() => _isAnalyzing = true);
      final analysis = await _analyzeImageQuality(image.path);
      setState(() => _isAnalyzing = false);

      // If image is blurry, ask user what to do
      if (analysis.isBlurry) {
        final useAnyway = await _showBlurryPhotoDialog(analysis);
        if (!useAnyway) {
          // User wants to retake - delete temp file and return null
          try {
            await File(image.path).delete();
          } catch (_) {}
          return null;
        }
      }

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

      // Show success message if quality was good
      if (!analysis.isBlurry && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Foto capturada (Nitidez: ${analysis.qualityPercent}%)'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }

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
      setState(() {
        _isCapturing = false;
        _isAnalyzing = false;
      });
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
                  isAnalyzing: _isAnalyzing,
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
                  isAnalyzing: _isAnalyzing,
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
                  isAnalyzing: _isAnalyzing,
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
                  isAnalyzing: _isAnalyzing,
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
                    isAnalyzing: _isAnalyzing,
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
                    isAnalyzing: _isAnalyzing,
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
                    isAnalyzing: _isAnalyzing,
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
  final bool isAnalyzing;
  final VoidCallback onCapture;
  final VoidCallback onClear;

  const _DocumentPhotoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.imagePath,
    required this.isRequired,
    required this.isCapturing,
    this.isAnalyzing = false,
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
                if (isCapturing || isAnalyzing)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      if (isAnalyzing) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Analizando...',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
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
