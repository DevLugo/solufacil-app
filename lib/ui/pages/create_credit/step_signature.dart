import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../core/theme/colors.dart';
import '../../../providers/create_credit_provider.dart';
import '../../../providers/collector_dashboard_provider.dart';
import 'create_credit_page.dart';

/// Step 6: Contract/Promissory note signature
class StepSignature extends ConsumerStatefulWidget {
  final CreateCreditState state;
  final CreateCreditNotifier notifier;

  const StepSignature({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  ConsumerState<StepSignature> createState() => _StepSignatureState();
}

class _StepSignatureState extends ConsumerState<StepSignature> {
  int _currentSignature = 0; // 0 = borrower, 1 = collateral

  @override
  Widget build(BuildContext context) {
    // Watch the provider directly to get updated state for canProceed
    final selectedRoute = ref.watch(selectedRouteProvider);
    final currentState = ref.watch(createCreditProvider(selectedRoute?.id));

    final signatureData = currentState.signatureData;
    final hasCollateral = currentState.hasCollateral;
    final clientName = currentState.selectedClient?.fullName ??
                       currentState.newClientInput?.fullName ??
                       'Cliente';
    final collateralName = currentState.selectedCollateral?.fullName ??
                           currentState.newCollateralInput?.fullName ??
                           'Aval';

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
                  'Firma Digital',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Captura la firma del cliente para el pagaré',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Signature tabs if has collateral
                if (hasCollateral) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _SignatureTab(
                          title: 'Cliente',
                          subtitle: clientName,
                          isSelected: _currentSignature == 0,
                          hasSignature: signatureData?.hasBorrowerSignature ?? false,
                          onTap: () => setState(() => _currentSignature = 0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SignatureTab(
                          title: 'Aval',
                          subtitle: collateralName,
                          isSelected: _currentSignature == 1,
                          hasSignature: signatureData?.hasCollateralSignature ?? false,
                          onTap: () => setState(() => _currentSignature = 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Current signer info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _currentSignature == 0 ? LucideIcons.user : LucideIcons.shield,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Firma de: ${_currentSignature == 0 ? clientName : collateralName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              _currentSignature == 0
                                  ? 'El cliente debe firmar dentro del recuadro'
                                  : 'El aval debe firmar dentro del recuadro',
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
                const SizedBox(height: 24),

                // Signature pad
                _SignaturePad(
                  key: ValueKey('signature_$_currentSignature'),
                  existingSignaturePath: _currentSignature == 0
                      ? signatureData?.borrowerSignaturePath
                      : signatureData?.collateralSignaturePath,
                  onSignatureSaved: (path) {
                    if (_currentSignature == 0) {
                      widget.notifier.setBorrowerSignature(path);
                    } else {
                      widget.notifier.setCollateralSignature(path);
                    }
                  },
                  onClear: () {
                    if (_currentSignature == 0) {
                      widget.notifier.clearBorrowerSignature();
                    } else {
                      widget.notifier.clearCollateralSignature();
                    }
                  },
                ),

                const SizedBox(height: 24),

                // Status summary
                _buildStatusSummary(signatureData, hasCollateral),
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

  Widget _buildStatusSummary(SignatureData? data, bool hasCollateral) {
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
            label: 'Firma del cliente',
            isComplete: data?.hasBorrowerSignature ?? false,
            isRequired: true,
          ),
          if (hasCollateral) ...[
            const SizedBox(height: 12),
            _StatusRow(
              label: 'Firma del aval',
              isComplete: data?.hasCollateralSignature ?? false,
              isRequired: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Signature tab button
class _SignatureTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool hasSignature;
  final VoidCallback onTap;

  const _SignatureTab({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.hasSignature,
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
              if (hasSignature)
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

/// Signature pad widget
class _SignaturePad extends StatefulWidget {
  final String? existingSignaturePath;
  final Function(String) onSignatureSaved;
  final VoidCallback onClear;

  const _SignaturePad({
    super.key,
    this.existingSignaturePath,
    required this.onSignatureSaved,
    required this.onClear,
  });

  @override
  State<_SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<_SignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSignaturePath != null) {
      // Could load existing signature but for simplicity just show it
    }
  }

  void _clearSignature() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
    widget.onClear();
  }

  Future<void> _saveSignature() async {
    if (_strokes.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      // Create image from signature
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // White background
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 600, 300),
        Paint()..color = Colors.white,
      );

      // Draw strokes
      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (final stroke in _strokes) {
        if (stroke.length > 1) {
          final path = Path();
          path.moveTo(stroke.first.dx * 2, stroke.first.dy * 2);
          for (int i = 1; i < stroke.length; i++) {
            path.lineTo(stroke[i].dx * 2, stroke[i].dy * 2);
          }
          canvas.drawPath(path, paint);
        }
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(600, 300);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception('Failed to get image data');

      // Save to file
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedPath = path.join(appDir.path, 'signatures', fileName);

      final dir = Directory(path.dirname(savedPath));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File(savedPath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      widget.onSignatureSaved(savedPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firma guardada'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar firma: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExisting = widget.existingSignaturePath != null;
    final hasDrawing = _strokes.isNotEmpty;

    return Column(
      children: [
        // Signature canvas
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: hasExisting && !hasDrawing
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(widget.existingSignaturePath!),
                    fit: BoxFit.contain,
                  ),
                )
              : GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _currentStroke = [details.localPosition];
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _currentStroke.add(details.localPosition);
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _strokes.add(List.from(_currentStroke));
                      _currentStroke.clear();
                    });
                  },
                  child: CustomPaint(
                    painter: _SignaturePainter(
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                    ),
                    size: Size.infinite,
                  ),
                ),
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _clearSignature,
                icon: const Icon(LucideIcons.trash2, size: 18),
                label: const Text('Limpiar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: hasDrawing && !_isSaving ? _saveSignature : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(LucideIcons.save, size: 18),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Signature painter
class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.length > 1) {
        final path = Path();
        path.moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    // Draw current stroke
    if (currentStroke.length > 1) {
      final path = Path();
      path.moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
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
