import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/loan.dart';
import '../../../data/models/payment_input.dart';
import '../../../data/repositories/loan_repository.dart';
import '../../../providers/collection_provider.dart';
import '../../../providers/collector_dashboard_provider.dart';
import '../../../providers/powersync_provider.dart';

/// Provider to get loan details by ID
final loanByIdProvider = FutureProvider.family<Loan?, String>((ref, loanId) async {
  final dbAsyncValue = ref.watch(powerSyncDatabaseProvider);
  final db = dbAsyncValue.valueOrNull;
  if (db == null) return null;

  final repo = LoanRepository(db);
  return repo.getLoanById(loanId);
});

class RegisterPaymentPage extends ConsumerStatefulWidget {
  final String? loanId;

  const RegisterPaymentPage({super.key, this.loanId});

  @override
  ConsumerState<RegisterPaymentPage> createState() => _RegisterPaymentPageState();
}

class _RegisterPaymentPageState extends ConsumerState<RegisterPaymentPage> {
  String _primaryAmount = '0';
  String _secondaryAmount = '0';
  bool _isNoPayment = false;
  bool _showSuccess = false;

  // Primary payment type (true = cash, false = transfer)
  bool _isPrimaryCash = true;

  // Show secondary payment field (for mixed payments - edge case)
  bool _showSecondaryPayment = false;

  // Initial state to track changes
  String _initialPrimaryAmount = '0';
  String _initialSecondaryAmount = '0';
  bool _initialIsPrimaryCash = true;
  bool _initialIsNoPayment = false;
  bool _hasExistingPayment = false;

  bool get _hasChanges {
    return _primaryAmount != _initialPrimaryAmount ||
        _secondaryAmount != _initialSecondaryAmount ||
        _isPrimaryCash != _initialIsPrimaryCash ||
        _isNoPayment != _initialIsNoPayment;
  }

  double get _totalAmount {
    final primary = double.tryParse(_primaryAmount) ?? 0.0;
    final secondary = _showSecondaryPayment ? (double.tryParse(_secondaryAmount) ?? 0.0) : 0.0;
    return primary + secondary;
  }

  // Get cash and bank amounts based on primary type
  double get _cashAmount {
    final primary = double.tryParse(_primaryAmount) ?? 0.0;
    final secondary = _showSecondaryPayment ? (double.tryParse(_secondaryAmount) ?? 0.0) : 0.0;
    return _isPrimaryCash ? primary : secondary;
  }

  double get _bankAmount {
    final primary = double.tryParse(_primaryAmount) ?? 0.0;
    final secondary = _showSecondaryPayment ? (double.tryParse(_secondaryAmount) ?? 0.0) : 0.0;
    return _isPrimaryCash ? secondary : primary;
  }

  @override
  void initState() {
    super.initState();
    // Check if there's an existing pending payment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingPayment();
    });
  }

  void _loadExistingPayment() {
    final loanId = widget.loanId;
    if (loanId == null) return;

    final dayState = ref.read(dayPaymentStateProvider);
    if (dayState == null) return;

    final existing = dayState.payments
        .where((p) => p.loanId == loanId)
        .firstOrNull;

    if (existing == null) return;

    setState(() {
      _isNoPayment = existing.isNoPayment;
      _hasExistingPayment = true;

      // Determine primary type based on amounts
      final hasCash = existing.cashAmount > 0;
      final hasBank = existing.bankAmount > 0;
      final isMixed = hasCash && hasBank;

      if (isMixed) {
        // Mixed payment - show secondary, cash as primary
        _isPrimaryCash = true;
        _primaryAmount = existing.cashAmount.toInt().toString();
        _secondaryAmount = existing.bankAmount.toInt().toString();
        _showSecondaryPayment = true;
      } else if (hasBank) {
        // Bank only
        _isPrimaryCash = false;
        _primaryAmount = existing.bankAmount.toInt().toString();
        _secondaryAmount = '0';
        _showSecondaryPayment = false;
      } else {
        // Cash only (default)
        _isPrimaryCash = true;
        _primaryAmount = existing.cashAmount.toInt().toString();
        _secondaryAmount = '0';
        _showSecondaryPayment = false;
      }

      // Store initial values
      _initialPrimaryAmount = _primaryAmount;
      _initialSecondaryAmount = _secondaryAmount;
      _initialIsPrimaryCash = _isPrimaryCash;
      _initialIsNoPayment = _isNoPayment;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar cambios?'),
        content: const Text('Tienes cambios sin guardar. ¿Deseas descartarlos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Descartar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _onDigit(String digit) {
    if (_isNoPayment) return;
    setState(() {
      if (_primaryAmount == '0') {
        _primaryAmount = digit;
      } else if (_primaryAmount.length < 7) {
        _primaryAmount = _primaryAmount + digit;
      }
    });
  }

  void _onDelete() {
    if (_isNoPayment) return;
    setState(() {
      if (_primaryAmount.length > 1) {
        _primaryAmount = _primaryAmount.substring(0, _primaryAmount.length - 1);
      } else {
        _primaryAmount = '0';
      }
    });
  }

  void _onQuickAmount(double amount) {
    if (_isNoPayment) return;
    setState(() {
      _primaryAmount = amount.toInt().toString();
    });
  }

  void _toggleNoPayment() {
    setState(() {
      _isNoPayment = !_isNoPayment;
      if (_isNoPayment) {
        _primaryAmount = '0';
        _secondaryAmount = '0';
        _showSecondaryPayment = false;
      }
    });
  }

  void _togglePaymentType() {
    setState(() {
      _isPrimaryCash = !_isPrimaryCash;
    });
  }

  void _toggleSecondaryPayment() {
    setState(() {
      _showSecondaryPayment = !_showSecondaryPayment;
      if (!_showSecondaryPayment) {
        _secondaryAmount = '0';
      }
    });
  }

  void _onSecondaryDigit(String digit) {
    if (_isNoPayment) return;
    setState(() {
      if (_secondaryAmount == '0') {
        _secondaryAmount = digit;
      } else if (_secondaryAmount.length < 7) {
        _secondaryAmount = _secondaryAmount + digit;
      }
    });
  }

  void _onSecondaryDelete() {
    if (_isNoPayment) return;
    setState(() {
      if (_secondaryAmount.length > 1) {
        _secondaryAmount = _secondaryAmount.substring(0, _secondaryAmount.length - 1);
      } else {
        _secondaryAmount = '0';
      }
    });
  }

  double _calculateCommission(double amount, double expectedWeekly, double baseCommission) {
    return calculateCommission(
      amount: amount,
      expectedWeeklyPayment: expectedWeekly,
      baseCommission: baseCommission,
    );
  }

  void _onConfirm(Loan loan) {
    if (!_validateAmount()) return;

    _initializeDayStateIfNeeded();
    final entry = _createPaymentEntry(loan);
    ref.read(dayPaymentStateProvider.notifier).addPayment(entry);

    _showSuccessAndNavigateBack();
  }

  bool _validateAmount() {
    if (_isNoPayment) return true;

    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido')),
      );
      return false;
    }
    return true;
  }

  void _initializeDayStateIfNeeded() {
    final dayState = ref.read(dayPaymentStateProvider);
    if (dayState != null) return;

    final selectedLead = ref.read(selectedLeadProvider);
    if (selectedLead == null) return;

    ref.read(dayPaymentStateProvider.notifier).initialize(
          leadId: selectedLead.id,
          localityId: selectedLead.locationId ?? '',
          date: DateTime.now(),
        );
  }

  PaymentEntry _createPaymentEntry(Loan loan) {
    final baseCommission = loan.loanPaymentComission ?? 0;
    return PaymentEntry(
      loanId: loan.id,
      borrowerName: loan.borrowerName ?? 'Sin nombre',
      cashAmount: _isNoPayment ? 0 : _cashAmount,
      bankAmount: _isNoPayment ? 0 : _bankAmount,
      comission: _isNoPayment
          ? 0
          : _calculateCommission(_totalAmount, loan.expectedWeeklyPayment, baseCommission),
      isNoPayment: _isNoPayment,
      expectedWeeklyPayment: loan.expectedWeeklyPayment,
    );
  }

  void _showSuccessAndNavigateBack() {
    setState(() => _showSuccess = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loanId = widget.loanId;
    if (loanId == null) {
      return const _ErrorScreen(message: 'ID de préstamo no proporcionado');
    }

    final loanAsync = ref.watch(loanByIdProvider(loanId));

    return loanAsync.when(
      data: (loan) => _buildDataState(loan),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _ErrorScreen(message: error.toString()),
    );
  }

  Widget _buildDataState(Loan? loan) {
    if (loan == null) {
      return const _ErrorScreen(message: 'Préstamo no encontrado');
    }

    if (_showSuccess) {
      return _SuccessScreen(amount: _totalAmount, isNoPayment: _isNoPayment);
    }

    return _buildPaymentForm(loan);
  }

  Widget _buildPaymentForm(Loan loan) {
    final baseCommission = loan.loanPaymentComission ?? 0;
    final commission = _calculateCommission(_totalAmount, loan.expectedWeeklyPayment, baseCommission);
    final primaryAmt = double.tryParse(_primaryAmount) ?? 0;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final canPop = await _onWillPop();
        if (canPop && mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(_hasExistingPayment ? 'Editar Pago' : 'Registrar Pago'),
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: () async {
              final canPop = await _onWillPop();
              if (canPop && mounted) {
                context.pop();
              }
            },
          ),
          actions: [
            // No payment toggle
            TextButton.icon(
              onPressed: _toggleNoPayment,
              icon: Icon(
                _isNoPayment ? LucideIcons.checkSquare : LucideIcons.square,
                size: 18,
                color: _isNoPayment ? AppColors.error : AppColors.textMuted,
              ),
              label: Text(
                'Sin pago',
                style: TextStyle(
                  color: _isNoPayment ? AppColors.error : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Client info header
                    _ClientHeader(loan: loan),

                    // Progress bar
                    _ProgressBar(loan: loan),

                    const SizedBox(height: 16),

                    // Expected payment
                    Text(
                      'Pago esperado',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(loan.expectedWeeklyPayment),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick amount buttons
                    if (!_isNoPayment) _QuickAmountButtons(
                      expectedAmount: loan.expectedWeeklyPayment,
                      onSelect: _onQuickAmount,
                      selectedAmount: primaryAmt,
                    ),

                    const SizedBox(height: 16),

                    // Main payment input
                    if (!_isNoPayment) ...[
                      // Primary amount display
                      _PrimaryAmountDisplay(
                        amount: _primaryAmount,
                        isCash: _isPrimaryCash,
                        onToggleType: _togglePaymentType,
                      ),

                      const SizedBox(height: 12),

                      // Secondary payment (optional - for mixed)
                      if (_showSecondaryPayment)
                        _SecondaryAmountInput(
                          amount: _secondaryAmount,
                          isCash: !_isPrimaryCash,
                          onRemove: _toggleSecondaryPayment,
                          onDigit: _onSecondaryDigit,
                          onDelete: _onSecondaryDelete,
                        )
                      else
                        _AddSecondaryButton(onAdd: _toggleSecondaryPayment),

                      const SizedBox(height: 12),

                      // Commission display
                      if (_totalAmount > 0)
                        Text(
                          'Comisión: ${formatCurrency(commission)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ] else
                      _NoPaymentDisplay(),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Fixed bottom: Numpad or Confirm Button
            if (_hasChanges || _isNoPayment)
              _ConfirmButton(
                onConfirm: () => _onConfirm(loan),
                isNoPayment: _isNoPayment,
                cashAmount: _cashAmount,
                bankAmount: _bankAmount,
                commission: commission,
              )
            else
              _Numpad(
                onDigit: _onDigit,
                onDelete: _onDelete,
                onConfirm: () => _onConfirm(loan),
                isDisabled: _isNoPayment,
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CONFIRM BUTTON
// =============================================================================

class _ConfirmButton extends StatelessWidget {
  final VoidCallback onConfirm;
  final bool isNoPayment;
  final double cashAmount;
  final double bankAmount;
  final double commission;

  const _ConfirmButton({
    required this.onConfirm,
    required this.isNoPayment,
    required this.cashAmount,
    required this.bankAmount,
    required this.commission,
  });

  double get totalAmount => cashAmount + bankAmount;

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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary
            if (!isNoPayment) ...[
              // Cash amount
              if (cashAmount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.banknote, size: 16, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text(
                          'Efectivo:',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Text(
                      formatCurrency(cashAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              // Bank amount
              if (bankAmount > 0) ...[
                if (cashAmount > 0) const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.creditCard, size: 16, color: AppColors.info),
                        const SizedBox(width: 6),
                        Text(
                          'Transferencia:',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Text(
                      formatCurrency(bankAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ],
              // Total (only if mixed)
              if (cashAmount > 0 && bankAmount > 0) ...[
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    Text(
                      formatCurrency(totalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
              // Commission
              if (commission > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comisión:',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    Text(
                      '+${formatCurrency(commission)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gradientPurple,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onConfirm,
                icon: Icon(
                  isNoPayment ? LucideIcons.ban : LucideIcons.check,
                  size: 20,
                ),
                label: Text(
                  isNoPayment ? 'Confirmar Sin Pago' : 'Confirmar Pago',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isNoPayment ? AppColors.warning : AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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

class _ClientHeader extends StatelessWidget {
  final Loan loan;

  const _ClientHeader({required this.loan});

  String get _initials {
    return (loan.borrowerName ?? 'NN')
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
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
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
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
                Text(
                  loan.borrowerName ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Semana ${loan.weeksSinceSign + 1} · Debe ${formatCurrency(loan.pendingAmountStored)}',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Loan loan;

  const _ProgressBar({required this.loan});

  @override
  Widget build(BuildContext context) {
    final progress = loan.paymentProgress / 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.background,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso del préstamo',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                '${loan.paymentProgress.toStringAsFixed(0)}%',
                style: const TextStyle(
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
              value: progress,
              backgroundColor: AppColors.border.withOpacity(0.5),
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAmountButtons extends StatelessWidget {
  final double expectedAmount;
  final Function(double) onSelect;
  final double selectedAmount;

  const _QuickAmountButtons({
    required this.expectedAmount,
    required this.onSelect,
    required this.selectedAmount,
  });

  List<double> get _amounts => [
        expectedAmount,
        expectedAmount * 2,
        expectedAmount * 0.5,
      ];

  bool _isSelected(double amount) => (selectedAmount - amount).abs() < 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _amounts.map((amount) {
          final isSelected = _isSelected(amount);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              label: Text(formatCurrency(amount)),
              onPressed: () => onSelect(amount),
              backgroundColor: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surface,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// PRIMARY AMOUNT DISPLAY (Single payment focus)
// =============================================================================

class _PrimaryAmountDisplay extends StatelessWidget {
  final String amount;
  final bool isCash;
  final VoidCallback onToggleType;

  const _PrimaryAmountDisplay({
    required this.amount,
    required this.isCash,
    required this.onToggleType,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCash ? AppColors.success : AppColors.info;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '\$',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                amount == '0' ? '0' : amount,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Payment type toggle
          GestureDetector(
            onTap: onToggleType,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCash ? LucideIcons.banknote : LucideIcons.creditCard,
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCash ? 'Efectivo' : 'Transferencia',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECONDARY AMOUNT INPUT (For mixed payments - edge case)
// =============================================================================

class _SecondaryAmountInput extends StatelessWidget {
  final String amount;
  final bool isCash;
  final VoidCallback onRemove;
  final Function(String) onDigit;
  final VoidCallback onDelete;

  const _SecondaryAmountInput({
    required this.amount,
    required this.isCash,
    required this.onRemove,
    required this.onDigit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCash ? AppColors.success : AppColors.info;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Header with label and remove button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isCash ? LucideIcons.banknote : LucideIcons.creditCard,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCash ? '+ Efectivo' : '+ Transferencia',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Amount and mini numpad
          Row(
            children: [
              // Amount display
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '\$',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      amount == '0' ? '0' : amount,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Mini controls
              Row(
                children: [
                  _MiniNumButton(label: '1', onTap: () => onDigit('1')),
                  _MiniNumButton(label: '0', onTap: () => onDigit('0')),
                  _MiniNumButton(
                    icon: LucideIcons.delete,
                    onTap: onDelete,
                    isDelete: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniNumButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDelete;

  const _MiniNumButton({
    this.label,
    this.icon,
    required this.onTap,
    this.isDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: isDelete ? AppColors.error.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 16, color: isDelete ? AppColors.error : AppColors.textMuted)
              : Text(
                  label!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
        ),
      ),
    );
  }
}

// =============================================================================
// ADD SECONDARY BUTTON
// =============================================================================

class _AddSecondaryButton extends StatelessWidget {
  final VoidCallback onAdd;

  const _AddSecondaryButton({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.plus,
              size: 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              'Agregar pago mixto',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// NO PAYMENT DISPLAY
// =============================================================================

class _NoPaymentDisplay extends StatelessWidget {
  const _NoPaymentDisplay();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppColors.error,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.xCircle, color: AppColors.error, size: 32),
          const SizedBox(width: 12),
          Text(
            'Sin Pago',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
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
  final bool isDisabled;

  const _Numpad({
    required this.onDigit,
    required this.onDelete,
    required this.onConfirm,
    this.isDisabled = false,
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
                _NumpadButton(label: '1', onTap: () => onDigit('1'), isDisabled: isDisabled),
                _NumpadButton(label: '2', onTap: () => onDigit('2'), isDisabled: isDisabled),
                _NumpadButton(label: '3', onTap: () => onDigit('3'), isDisabled: isDisabled),
              ],
            ),
            Row(
              children: [
                _NumpadButton(label: '4', onTap: () => onDigit('4'), isDisabled: isDisabled),
                _NumpadButton(label: '5', onTap: () => onDigit('5'), isDisabled: isDisabled),
                _NumpadButton(label: '6', onTap: () => onDigit('6'), isDisabled: isDisabled),
              ],
            ),
            Row(
              children: [
                _NumpadButton(label: '7', onTap: () => onDigit('7'), isDisabled: isDisabled),
                _NumpadButton(label: '8', onTap: () => onDigit('8'), isDisabled: isDisabled),
                _NumpadButton(label: '9', onTap: () => onDigit('9'), isDisabled: isDisabled),
              ],
            ),
            Row(
              children: [
                _NumpadButton(
                  icon: LucideIcons.delete,
                  onTap: onDelete,
                  color: AppColors.error,
                  isDisabled: isDisabled,
                ),
                _NumpadButton(label: '0', onTap: () => onDigit('0'), isDisabled: isDisabled),
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
  final bool isDisabled;

  const _NumpadButton({
    this.label,
    this.icon,
    required this.onTap,
    this.color,
    this.bgColor,
    this.iconColor,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: isDisabled
              ? AppColors.surface.withOpacity(0.5)
              : (bgColor ?? AppColors.surface),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: icon != null
                  ? Icon(
                      icon,
                      size: 24,
                      color: isDisabled
                          ? AppColors.textMuted
                          : (iconColor ?? color),
                    )
                  : Text(
                      label!,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDisabled
                            ? AppColors.textMuted
                            : (color ?? AppColors.secondary),
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
  final double amount;
  final bool isNoPayment;

  const _SuccessScreen({
    required this.amount,
    required this.isNoPayment,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isNoPayment ? AppColors.warning : AppColors.success;
    final message = isNoPayment ? 'Falta Registrada' : '¡Pago Registrado!';
    final subtitle = isNoPayment
        ? 'Se marcó como sin pago'
        : '${formatCurrency(amount)} agregado';

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNoPayment ? LucideIcons.alertCircle : LucideIcons.check,
                size: 50,
                color: bgColor,
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
            Text(
              message,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ).animate().fade(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
