import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/loan.dart';
import '../../../data/models/payment_input.dart';
import '../../../providers/collection_provider.dart';
import '../../../providers/collector_dashboard_provider.dart';
import '../../widgets/distribution_sheet.dart';

class ClientListPage extends ConsumerStatefulWidget {
  final String? locationId;

  const ClientListPage({super.key, this.locationId});

  @override
  ConsumerState<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends ConsumerState<ClientListPage> {
  bool _isApplyingAll = false;
  final TextEditingController _globalCommissionController = TextEditingController();
  String _searchQuery = '';
  bool _showExtraCobranzas = false;

  @override
  void dispose() {
    _globalCommissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLead = ref.watch(selectedLeadProvider);
    final leadId = selectedLead?.id ?? '';
    final locationName = selectedLead?.locationName ?? 'Localidad';

    final loansAsync = ref.watch(activeLoansForLocalityProvider(leadId));
    final extraLoansAsync = ref.watch(extraLoansForLocalityProvider(leadId));
    final summary = ref.watch(localityDaySummaryProvider(leadId));
    final dayState = ref.watch(dayPaymentStateProvider);

    // Calculate commission from pending payments
    final totalCommission = _calculateTotalCommission(dayState);

    // Filter loans by search query
    final filteredLoansAsync = loansAsync.whenData((loans) {
      if (_searchQuery.isEmpty) return loans;
      final query = _searchQuery.toLowerCase();
      return loans.where((loan) =>
        loan.borrowerName.toLowerCase().contains(query) ||
        (loan.clientCode?.toLowerCase().contains(query) ?? false)
      ).toList();
    });

    // Filter extra loans by search query
    final filteredExtraLoansAsync = extraLoansAsync.whenData((loans) {
      if (_searchQuery.isEmpty) return loans;
      final query = _searchQuery.toLowerCase();
      return loans.where((loan) =>
        loan.borrowerName.toLowerCase().contains(query) ||
        (loan.clientCode?.toLowerCase().contains(query) ?? false)
      ).toList();
    });

    // Count payments for button state
    final paymentCount = dayState?.payments.where((p) => !p.isNoPayment).length ?? 0;
    final noPaymentCount = dayState?.payments.where((p) => p.isNoPayment).length ?? 0;
    final hasPayments = dayState != null && dayState.payments.isNotEmpty;

    // Check if there are extra loans
    final extraLoansCount = extraLoansAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(locationName),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () {
              ref.invalidate(activeLoansForLocalityProvider(leadId));
              ref.invalidate(extraLoansForLocalityProvider(leadId));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary header with KPIs
          _SummaryHeader(
            summary: summary,
            totalCommission: totalCommission,
          ),

          // Search bar
          _SearchBar(
            searchQuery: _searchQuery,
            onSearchChanged: (value) => setState(() => _searchQuery = value),
          ),

          // Quick actions bar with global commission
          loansAsync.whenData(
            (loans) => _QuickActionsBar(
              loans: loans,
              dayState: dayState,
              onApplyAllWeekly: () => _applyAllWeekly(loans),
              onApplyAllNoPayment: () => _applyAllNoPayment(loans),
              onClearAll: _clearAll,
              isLoading: _isApplyingAll,
              globalCommissionController: _globalCommissionController,
              onApplyGlobalCommission: () => _applyGlobalCommission(loans),
            ),
          ).value ?? const SizedBox.shrink(),

          // Client list (combined active + extra)
          Expanded(
            child: filteredLoansAsync.when(
              data: (loans) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Active loans section
                    if (loans.isEmpty && extraLoansCount == 0)
                      const _EmptyState()
                    else ...[
                      // Active loans
                      ...loans.map((loan) {
                        final pendingPayment = dayState?.payments
                            .where((p) => p.loanId == loan.loanId)
                            .firstOrNull;

                        return _ClientCard(
                          loan: loan,
                          pendingPayment: pendingPayment,
                          onTap: () => _navigateToPayment(loan),
                          onQuickNoPayment: () => _quickNoPayment(loan),
                          onRemovePayment: () => _removePayment(loan.loanId),
                        );
                      }),

                      // Extra Cobranzas section (collapsible)
                      if (extraLoansCount > 0) ...[
                        const SizedBox(height: 16),
                        _ExtraCobranzasHeader(
                          count: extraLoansCount,
                          isExpanded: _showExtraCobranzas,
                          onToggle: () => setState(() {
                            _showExtraCobranzas = !_showExtraCobranzas;
                          }),
                        ),
                        if (_showExtraCobranzas)
                          filteredExtraLoansAsync.when(
                            data: (extraLoans) => Column(
                              children: extraLoans.map((loan) {
                                final pendingPayment = dayState?.payments
                                    .where((p) => p.loanId == loan.loanId)
                                    .firstOrNull;

                                return _ClientCard(
                                  loan: loan,
                                  pendingPayment: pendingPayment,
                                  onTap: () => _navigateToPayment(loan),
                                  onQuickNoPayment: () => _quickNoPayment(loan),
                                  onRemovePayment: () => _removePayment(loan.loanId),
                                  isExtra: true,
                                );
                              }).toList(),
                            ),
                            loading: () => const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                      ],
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                onRetry: () {
                  ref.invalidate(activeLoansForLocalityProvider(leadId));
                  ref.invalidate(extraLoansForLocalityProvider(leadId));
                },
              ),
            ),
          ),

          // Bottom action bar with Recibir Pagos button
          if (hasPayments)
            _BottomActionBar(
              paymentCount: paymentCount,
              noPaymentCount: noPaymentCount,
              totalCommission: totalCommission,
              totalCash: summary.totalCash,
              totalBank: summary.totalBank,
              onRecibir: () => showDistributionSheet(context),
            ),
        ],
      ),
    );
  }

  double _calculateTotalCommission(DayPaymentState? dayState) {
    if (dayState == null) return 0;
    return dayState.payments
        .where((p) => !p.isNoPayment)
        .fold(0.0, (sum, p) => sum + p.comission);
  }

  void _navigateToPayment(CollectionLoan loan) {
    context.push('${AppRoutes.registerPayment}?loanId=${loan.loanId}');
  }

  void _quickPayWeekly(CollectionLoan loan) {
    final notifier = ref.read(dayPaymentStateProvider.notifier);
    final selectedLead = ref.read(selectedLeadProvider);

    // Initialize if needed
    if (ref.read(dayPaymentStateProvider) == null) {
      notifier.initialize(
        leadId: selectedLead?.id ?? '',
        localityId: widget.locationId ?? '',
        date: DateTime.now(),
      );
    }

    // Calculate commission
    final commission = calculateCommission(
      amount: loan.expectedWeeklyPayment,
      expectedWeeklyPayment: loan.expectedWeeklyPayment,
      baseCommission: loan.loanPaymentComission,
    );

    notifier.addPayment(PaymentEntry(
      loanId: loan.loanId,
      borrowerName: loan.borrowerName,
      cashAmount: loan.expectedWeeklyPayment,
      bankAmount: 0,
      comission: commission,
      isNoPayment: false,
      expectedWeeklyPayment: loan.expectedWeeklyPayment,
    ));
  }

  void _quickNoPayment(CollectionLoan loan) {
    final notifier = ref.read(dayPaymentStateProvider.notifier);
    final selectedLead = ref.read(selectedLeadProvider);

    if (ref.read(dayPaymentStateProvider) == null) {
      notifier.initialize(
        leadId: selectedLead?.id ?? '',
        localityId: widget.locationId ?? '',
        date: DateTime.now(),
      );
    }

    notifier.addPayment(PaymentEntry(
      loanId: loan.loanId,
      borrowerName: loan.borrowerName,
      cashAmount: 0,
      bankAmount: 0,
      comission: 0,
      isNoPayment: true,
      expectedWeeklyPayment: loan.expectedWeeklyPayment,
    ));
  }

  Future<void> _applyAllWeekly(List<CollectionLoan> loans) async {
    setState(() => _isApplyingAll = true);

    final notifier = ref.read(dayPaymentStateProvider.notifier);
    final selectedLead = ref.read(selectedLeadProvider);

    if (ref.read(dayPaymentStateProvider) == null) {
      notifier.initialize(
        leadId: selectedLead?.id ?? '',
        localityId: widget.locationId ?? '',
        date: DateTime.now(),
      );
    }

    for (final loan in loans) {
      // Skip already paid loans
      if (loan.paidThisWeek) continue;

      final commission = calculateCommission(
        amount: loan.expectedWeeklyPayment,
        expectedWeeklyPayment: loan.expectedWeeklyPayment,
        baseCommission: loan.loanPaymentComission,
      );

      notifier.addPayment(PaymentEntry(
        loanId: loan.loanId,
        borrowerName: loan.borrowerName,
        cashAmount: loan.expectedWeeklyPayment,
        bankAmount: 0,
        comission: commission,
        isNoPayment: false,
        expectedWeeklyPayment: loan.expectedWeeklyPayment,
      ));
    }

    setState(() => _isApplyingAll = false);
  }

  Future<void> _applyAllNoPayment(List<CollectionLoan> loans) async {
    setState(() => _isApplyingAll = true);

    final notifier = ref.read(dayPaymentStateProvider.notifier);
    final selectedLead = ref.read(selectedLeadProvider);

    if (ref.read(dayPaymentStateProvider) == null) {
      notifier.initialize(
        leadId: selectedLead?.id ?? '',
        localityId: widget.locationId ?? '',
        date: DateTime.now(),
      );
    }

    for (final loan in loans) {
      if (loan.paidThisWeek) continue;

      notifier.addPayment(PaymentEntry(
        loanId: loan.loanId,
        borrowerName: loan.borrowerName,
        cashAmount: 0,
        bankAmount: 0,
        comission: 0,
        isNoPayment: true,
        expectedWeeklyPayment: loan.expectedWeeklyPayment,
      ));
    }

    setState(() => _isApplyingAll = false);
  }

  void _clearAll() {
    ref.read(dayPaymentStateProvider.notifier).clear();
  }

  void _removePayment(String loanId) {
    ref.read(dayPaymentStateProvider.notifier).removePayment(loanId);
  }

  void _applyGlobalCommission(List<CollectionLoan> loans) {
    final commissionText = _globalCommissionController.text.trim();
    if (commissionText.isEmpty) return;

    final commission = double.tryParse(commissionText);
    if (commission == null || commission < 0) return;

    final notifier = ref.read(dayPaymentStateProvider.notifier);
    final dayState = ref.read(dayPaymentStateProvider);
    if (dayState == null) return;

    // Update commission for all existing payments
    for (final payment in dayState.payments) {
      if (payment.isNoPayment) continue;

      notifier.addPayment(PaymentEntry(
        loanId: payment.loanId,
        borrowerName: payment.borrowerName,
        cashAmount: payment.cashAmount,
        bankAmount: payment.bankAmount,
        comission: commission,
        isNoPayment: false,
        expectedWeeklyPayment: payment.expectedWeeklyPayment,
      ));
    }
  }

}

// =============================================================================
// SEARCH BAR
// =============================================================================

class _SearchBar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _SearchBar({
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.background,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar cliente...',
          prefixIcon: const Icon(LucideIcons.search, size: 18),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  onPressed: () => onSearchChanged(''),
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          isDense: true,
        ),
        onChanged: onSearchChanged,
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

// =============================================================================
// QUICK ACTIONS BAR
// =============================================================================

class _QuickActionsBar extends StatelessWidget {
  final List<CollectionLoan> loans;
  final DayPaymentState? dayState;
  final VoidCallback onApplyAllWeekly;
  final VoidCallback onApplyAllNoPayment;
  final VoidCallback onClearAll;
  final bool isLoading;
  final TextEditingController globalCommissionController;
  final VoidCallback onApplyGlobalCommission;

  const _QuickActionsBar({
    required this.loans,
    required this.dayState,
    required this.onApplyAllWeekly,
    required this.onApplyAllNoPayment,
    required this.onClearAll,
    required this.isLoading,
    required this.globalCommissionController,
    required this.onApplyGlobalCommission,
  });

  int get _pendingCount => loans.where((l) => !l.paidThisWeek).length;
  int get _paymentCount =>
      dayState?.payments.where((p) => !p.isNoPayment).length ?? 0;
  bool get _hasPayments => dayState != null && dayState!.payments.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Global commission row
          Row(
            children: [
              Text(
                'Comisión:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Container(
                width: 70,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: globalCommissionController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    prefixText: '\$ ',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _hasPayments ? onApplyGlobalCommission : null,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _hasPayments
                        ? AppColors.secondary.withOpacity(0.1)
                        : AppColors.border.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    'Aplicar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _hasPayments ? AppColors.secondary : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Pending badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  '$_pendingCount pend.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Quick action buttons row
          Row(
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                // Apply all weekly
                Expanded(
                  child: _ActionButton(
                    icon: LucideIcons.checkSquare,
                    label: 'Todos',
                    color: AppColors.success,
                    onTap: _pendingCount > 0 ? onApplyAllWeekly : null,
                  ),
                ),
                const SizedBox(width: 8),

                // Apply all no payment
                Expanded(
                  child: _ActionButton(
                    icon: LucideIcons.xSquare,
                    label: 'Faltas',
                    color: AppColors.error,
                    onTap: _pendingCount > 0 ? onApplyAllNoPayment : null,
                  ),
                ),
                const SizedBox(width: 8),

                // Clear all
                Expanded(
                  child: _ActionButton(
                    icon: LucideIcons.rotateCcw,
                    label: 'Limpiar',
                    color: AppColors.textSecondary,
                    onTap: _hasPayments ? onClearAll : null,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final effectiveColor = isEnabled ? color : color.withOpacity(0.3);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: effectiveColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// BOTTOM ACTION BAR (Recibir Pagos)
// =============================================================================

class _BottomActionBar extends StatelessWidget {
  final int paymentCount;
  final int noPaymentCount;
  final double totalCommission;
  final double totalCash;
  final double totalBank;
  final VoidCallback onRecibir;

  const _BottomActionBar({
    required this.paymentCount,
    required this.noPaymentCount,
    required this.totalCommission,
    required this.totalCash,
    required this.totalBank,
    required this.onRecibir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Payments count
                Row(
                  children: [
                    _CountBadge(
                      icon: LucideIcons.checkCircle2,
                      count: paymentCount,
                      label: 'pagos',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    if (noPaymentCount > 0)
                      _CountBadge(
                        icon: LucideIcons.ban,
                        count: noPaymentCount,
                        label: 'faltas',
                        color: AppColors.error,
                      ),
                  ],
                ),
                // Cash/Bank breakdown
                Row(
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.wallet, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          formatCurrency(totalCash),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Icon(LucideIcons.building2, size: 14, color: AppColors.info),
                        const SizedBox(width: 4),
                        Text(
                          formatCurrency(totalBank),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRecibir,
                icon: const Icon(LucideIcons.save, size: 18),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Recibir Pagos',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (totalCommission > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Text(
                          '+${formatCurrency(totalCommission)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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

class _CountBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _CountBadge({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SUMMARY HEADER
// =============================================================================

class _SummaryHeader extends StatelessWidget {
  final LocalityCollectionSummary summary;
  final double totalCommission;

  const _SummaryHeader({
    required this.summary,
    required this.totalCommission,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.background,
      child: Column(
        children: [
          // Main KPIs row
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Esperado',
                  value: formatCurrency(summary.expectedAmount),
                  color: AppColors.secondary,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _SummaryItem(
                  label: 'Cobrado',
                  value: formatCurrency(summary.collectedAmount),
                  color: AppColors.success,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _SummaryItem(
                  label: 'Comisión',
                  value: formatCurrency(totalCommission),
                  color: AppColors.gradientPurple,
                  icon: LucideIcons.dollarSign,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            child: LinearProgressIndicator(
              value: summary.progressPercent / 100,
              backgroundColor: AppColors.border.withOpacity(0.5),
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),

          // Bottom stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _StatBadge(
                    icon: LucideIcons.users,
                    value: '${summary.paidCount}/${summary.totalLoans}',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  if (summary.noPaymentCount > 0)
                    _StatBadge(
                      icon: LucideIcons.ban,
                      value: '${summary.noPaymentCount}',
                      color: AppColors.error,
                    ),
                ],
              ),
              Row(
                children: [
                  _StatBadge(
                    icon: LucideIcons.wallet,
                    value: formatCurrency(summary.totalCash),
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _StatBadge(
                    icon: LucideIcons.building2,
                    value: formatCurrency(summary.totalBank),
                    color: AppColors.info,
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

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CLIENT CARD
// =============================================================================

class _ClientCard extends StatelessWidget {
  final CollectionLoan loan;
  final PaymentEntry? pendingPayment;
  final VoidCallback onTap;
  final VoidCallback onQuickNoPayment;
  final VoidCallback onRemovePayment;
  final bool isExtra;

  const _ClientCard({
    required this.loan,
    this.pendingPayment,
    required this.onTap,
    required this.onQuickNoPayment,
    required this.onRemovePayment,
    this.isExtra = false,
  });

  bool get _hasPendingPayment => pendingPayment != null;
  bool get _isPendingNoPayment => pendingPayment?.isNoPayment ?? false;
  bool get _isPaid => loan.paidThisWeek;
  bool get _canTap => !_isPaid;

  Color get _statusColor {
    if (isExtra) return AppColors.gradientPurple;
    if (_isPaid) return AppColors.success;
    if (_hasPendingPayment && !_isPendingNoPayment) return AppColors.success;
    if (_isPendingNoPayment) return AppColors.error;
    if (loan.weeksWithoutPayment >= 4) return AppColors.error;
    if (loan.weeksWithoutPayment >= 2) return AppColors.warning;
    return AppColors.primary;
  }

  IconData get _statusIcon {
    if (_isPaid || (_hasPendingPayment && !_isPendingNoPayment)) {
      return LucideIcons.checkCircle2;
    }
    if (_isPendingNoPayment) return LucideIcons.ban;
    if (loan.weeksWithoutPayment >= 4) return LucideIcons.alertTriangle;
    if (loan.weeksWithoutPayment >= 1) return LucideIcons.alertCircle;
    return LucideIcons.clock;
  }

  String get _statusLabel {
    if (_isPendingNoPayment) return 'Sin pago';
    if (_hasPendingPayment) return 'Por guardar';
    if (_isPaid) return 'Pagado';
    if (isExtra) return loan.isBadDebt ? 'Cartera Muerta' : 'Limpieza';
    return loan.statusLabel;
  }

  String get _initials {
    return loan.borrowerName
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _canTap ? onTap : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(),
              const SizedBox(width: 12),

              // Client info
              Expanded(child: _buildClientInfo()),

              // Quick action buttons or payment info
              if (_canTap && !_hasPendingPayment)
                _buildQuickActions()
              else
                _buildPaymentInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: _hasPendingPayment || _isPaid
            ? Icon(_statusIcon, size: 20, color: _statusColor)
            : Text(
                _initials,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _statusColor,
                ),
              ),
      ),
    );
  }

  Widget _buildClientInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loan.borrowerName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'Sem ${loan.weeksSinceSign + 1} · ${formatCurrency(loan.expectedWeeklyPayment)}',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(_statusIcon, size: 12, color: _statusColor),
            const SizedBox(width: 4),
            Text(
              _statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _statusColor,
              ),
            ),
            if (loan.isInCV && !_isPaid && !_hasPendingPayment) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  'CV',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    // Only show X button for marking no payment
    // Clients are included via "Todos" bulk action by default
    return _QuickActionButton(
      icon: LucideIcons.ban,
      color: AppColors.error,
      onTap: onQuickNoPayment,
      tooltip: 'Marcar sin pago',
    );
  }

  Widget _buildPaymentInfo() {
    if (_hasPendingPayment) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_isPendingNoPayment)
                // No payment indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.ban, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      const Text(
                        'Sin pago',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // Payment type badge with amount
                _PaymentTypeBadge(payment: pendingPayment!),
                // Commission indicator
                if (pendingPayment!.comission > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gradientPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppColors.gradientPurple.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.sparkles, size: 10, color: AppColors.gradientPurple),
                          const SizedBox(width: 3),
                          Text(
                            '+${formatCurrency(pendingPayment!.comission)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gradientPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(width: 8),
          // Remove payment button
          InkWell(
            onTap: onRemovePayment,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.x,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      formatCurrency(loan.expectedWeeklyPayment),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.secondary,
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _QuickActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// =============================================================================
// EMPTY AND ERROR STATES
// =============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'No hay clientes activos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta localidad no tiene préstamos activos',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error al cargar clientes',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

// =============================================================================
// EXTRA COBRANZAS HEADER
// =============================================================================

class _ExtraCobranzasHeader extends StatelessWidget {
  final int count;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ExtraCobranzasHeader({
    required this.count,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.gradientPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.gradientPurple.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.gradientPurple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.archive,
                size: 20,
                color: AppColors.gradientPurple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Extra Cobranzas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gradientPurple,
                    ),
                  ),
                  Text(
                    '$count clientes en limpieza/cartera muerta',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 20,
              color: AppColors.gradientPurple,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PAYMENT TYPE BADGE
// =============================================================================

class _PaymentTypeBadge extends StatelessWidget {
  final PaymentEntry payment;

  const _PaymentTypeBadge({required this.payment});

  @override
  Widget build(BuildContext context) {
    // Mixed payment - show both with gradient
    if (payment.isMixed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.success, AppColors.info],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cash part
            const Icon(LucideIcons.banknote, size: 12, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              formatCurrency(payment.cashAmount),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Separator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 1,
              height: 12,
              color: Colors.white.withOpacity(0.5),
            ),
            // Bank part
            const Icon(LucideIcons.creditCard, size: 12, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              formatCurrency(payment.bankAmount),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Cash only
    if (payment.isCashOnly) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.banknote, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              formatCurrency(payment.cashAmount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Bank only
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.info,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.creditCard, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            formatCurrency(payment.bankAmount),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
