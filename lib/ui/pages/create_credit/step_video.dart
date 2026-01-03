import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../providers/create_credit_provider.dart';
import '../../../providers/collector_dashboard_provider.dart';
import 'create_credit_page.dart';

/// Step 8: Video recording
class StepVideo extends ConsumerStatefulWidget {
  final CreateCreditState state;
  final CreateCreditNotifier notifier;

  const StepVideo({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  ConsumerState<StepVideo> createState() => _StepVideoState();
}

class _StepVideoState extends ConsumerState<StepVideo> {
  final _imagePicker = ImagePicker();
  bool _isRecording = false;
  final _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

  Future<void> _recordVideo() async {
    if (_isRecording) return;

    setState(() => _isRecording = true);

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );

      if (video == null) {
        setState(() => _isRecording = false);
        return;
      }

      // Save to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final savedPath = path.join(appDir.path, 'videos', fileName);

      // Create directory if it doesn't exist
      final dir = Directory(path.dirname(savedPath));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Copy file to permanent location
      await File(video.path).copy(savedPath);

      // Get video duration (approximate based on file size)
      final file = File(savedPath);
      final fileSize = await file.length();
      // Rough estimate: ~1MB per 10 seconds at medium quality
      final estimatedDuration = Duration(seconds: (fileSize / 100000).round());

      widget.notifier.setVideoRecording(
        videoPath: savedPath,
        duration: estimatedDuration,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video guardado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al grabar video: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isRecording = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider directly to get updated state for canProceed
    final selectedRoute = ref.watch(selectedRouteProvider);
    final currentState = ref.watch(createCreditProvider(selectedRoute?.id));

    final videoData = currentState.videoData;
    final clientName = currentState.selectedClient?.fullName ??
                       currentState.newClientInput?.fullName ??
                       'Cliente';
    final loanAmount = currentState.requestedAmount;
    final loanType = currentState.selectedLoanType;

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
                  'Grabación de Video',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Graba un video con el cliente aceptando el crédito',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Script/Prompt box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.infoSurfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.fileText, size: 18, color: AppColors.info),
                          const SizedBox(width: 8),
                          Text(
                            'Guión del Video',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.info,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ScriptLine(
                        speaker: 'Asesor',
                        text: '¿Es usted $clientName?',
                      ),
                      const SizedBox(height: 8),
                      _ScriptLine(
                        speaker: 'Cliente',
                        text: 'Sí, soy yo.',
                        isClient: true,
                      ),
                      const SizedBox(height: 8),
                      _ScriptLine(
                        speaker: 'Asesor',
                        text: '¿Está de acuerdo en recibir un crédito de ${_currencyFormat.format(loanAmount)} tipo ${loanType?.name ?? ""}?',
                      ),
                      const SizedBox(height: 8),
                      _ScriptLine(
                        speaker: 'Cliente',
                        text: 'Sí, estoy de acuerdo.',
                        isClient: true,
                      ),
                      const SizedBox(height: 8),
                      _ScriptLine(
                        speaker: 'Asesor',
                        text: '¿Entiende que el pago semanal será de ${_currencyFormat.format(currentState.calculatedMetrics?.expectedWeeklyPayment ?? 0)} durante ${loanType?.weekDuration ?? 0} semanas?',
                      ),
                      const SizedBox(height: 8),
                      _ScriptLine(
                        speaker: 'Cliente',
                        text: 'Sí, entiendo.',
                        isClient: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Video preview or record button
                if (videoData?.hasVideo ?? false) ...[
                  _buildVideoPreview(videoData!),
                ] else ...[
                  _buildRecordButton(),
                ],

                const SizedBox(height: 24),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.alertTriangle, size: 18, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Text(
                            'Importante',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.warningDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• El rostro del cliente debe ser claramente visible\n'
                        '• El cliente debe responder todas las preguntas\n'
                        '• El video debe tener audio claro\n'
                        '• Duración máxima: 2 minutos',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.warningDark,
                          height: 1.5,
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

  Widget _buildRecordButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isRecording ? null : _recordVideo,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: _isRecording
                      ? const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        )
                      : Icon(
                          LucideIcons.video,
                          size: 36,
                          color: AppColors.primary,
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isRecording ? 'Grabando...' : 'Iniciar Grabación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _isRecording ? AppColors.error : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toca para abrir la cámara',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview(VideoRecordingData videoData) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success, width: 2),
      ),
      child: Column(
        children: [
          // Video info
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.successSurfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.videoOff,
                    size: 28,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Video Grabado',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.clock, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            videoData.duration != null
                                ? _formatDuration(videoData.duration!)
                                : 'Duración desconocida',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(LucideIcons.checkCircle, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'Guardado correctamente',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      widget.notifier.clearVideoRecording();
                    },
                    icon: const Icon(LucideIcons.trash2, size: 18),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _recordVideo,
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    label: const Text('Volver a grabar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Script line widget
class _ScriptLine extends StatelessWidget {
  final String speaker;
  final String text;
  final bool isClient;

  const _ScriptLine({
    required this.speaker,
    required this.text,
    this.isClient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isClient
                ? AppColors.success.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            speaker,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isClient ? AppColors.success : AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontStyle: isClient ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}
