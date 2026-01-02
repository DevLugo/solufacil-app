import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';

class RegisterPaymentPage extends StatefulWidget {
  final String? loanId;

  const RegisterPaymentPage({super.key, this.loanId});

  @override
  State<RegisterPaymentPage> createState() => _RegisterPaymentPageState();
}

class _RegisterPaymentPageState extends State<RegisterPaymentPage> {
  String _amount = '0';
  bool _isCash = true;
  bool _showSuccess = false;

  void _onDigit(String digit) {
    setState(() {
      if (_amount == '0') {
        _amount = digit;
      } else {
        _amount = _amount + digit;
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  void _onConfirm() {
    if (_amount == '0' || _amount.isEmpty) return;

    setState(() {
      _showSuccess = true;
    });

    // Wait then navigate back
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return _SuccessScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Registrar Pago'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Client info header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.background,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'MG',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'María García López',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Semana 4 de 10',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Progress bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.background,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso del préstamo',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Text(
                      '40%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  child: LinearProgressIndicator(
                    value: 0.4,
                    backgroundColor: AppColors.border.withOpacity(0.5),
                    valueColor: const AlwaysStoppedAnimation(AppColors.success),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Expected payment
          Text(
            'Pago esperado',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '\$350',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),

          const SizedBox(height: 24),

          // Amount input display
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '\$',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  _amount,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Payment method toggle
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isCash = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isCash ? AppColors.background : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        boxShadow: _isCash ? AppTheme.shadowCard : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.banknote,
                            size: 18,
                            color: _isCash ? AppColors.success : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Efectivo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isCash ? AppColors.secondary : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isCash = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isCash ? AppColors.background : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        boxShadow: !_isCash ? AppTheme.shadowCard : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.creditCard,
                            size: 18,
                            color: !_isCash ? AppColors.info : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Transferencia',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: !_isCash ? AppColors.secondary : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Numpad
          _Numpad(
            onDigit: _onDigit,
            onDelete: _onDelete,
            onConfirm: _onConfirm,
          ),
        ],
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final Function(String) onDigit;
  final VoidCallback onDelete;
  final VoidCallback onConfirm;

  const _Numpad({
    required this.onDigit,
    required this.onDelete,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                _NumpadButton(label: '1', onTap: () => onDigit('1')),
                _NumpadButton(label: '2', onTap: () => onDigit('2')),
                _NumpadButton(label: '3', onTap: () => onDigit('3')),
              ],
            ),
            Row(
              children: [
                _NumpadButton(label: '4', onTap: () => onDigit('4')),
                _NumpadButton(label: '5', onTap: () => onDigit('5')),
                _NumpadButton(label: '6', onTap: () => onDigit('6')),
              ],
            ),
            Row(
              children: [
                _NumpadButton(label: '7', onTap: () => onDigit('7')),
                _NumpadButton(label: '8', onTap: () => onDigit('8')),
                _NumpadButton(label: '9', onTap: () => onDigit('9')),
              ],
            ),
            Row(
              children: [
                _NumpadButton(
                  icon: LucideIcons.delete,
                  onTap: onDelete,
                  color: AppColors.error,
                ),
                _NumpadButton(label: '0', onTap: () => onDigit('0')),
                _NumpadButton(
                  icon: LucideIcons.check,
                  onTap: onConfirm,
                  color: AppColors.success,
                  bgColor: AppColors.success,
                  iconColor: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? bgColor;
  final Color? iconColor;

  const _NumpadButton({
    this.label,
    this.icon,
    required this.onTap,
    this.color,
    this.bgColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: bgColor ?? AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: icon != null
                  ? Icon(icon, size: 24, color: iconColor ?? color)
                  : Text(
                      label!,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color ?? AppColors.secondary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.success,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.check,
                size: 50,
                color: AppColors.success,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                )
                .fade(duration: 200.ms),
            const SizedBox(height: 24),
            const Text(
              '¡Pago Registrado!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            const Text(
              '\$350 recibidos',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ).animate().fade(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
