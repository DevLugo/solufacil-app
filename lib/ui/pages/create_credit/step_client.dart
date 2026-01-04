import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../providers/create_credit_provider.dart';
import '../../../providers/client_search_provider.dart';
import '../../../providers/collector_dashboard_provider.dart';
import '../../../data/repositories/borrower_repository.dart';
import 'create_credit_page.dart';

/// Step 1: Select or create client
class StepClient extends ConsumerStatefulWidget {
  final CreateCreditState state;
  final CreateCreditNotifier notifier;

  const StepClient({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  ConsumerState<StepClient> createState() => _StepClientState();
}

class _StepClientState extends ConsumerState<StepClient> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _showNewClientForm = false;
  bool _isScanning = false;
  final _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLead = ref.watch(selectedLeadProvider);
    final searchConfig = ClientSearchConfig(
      leadId: selectedLead?.id,
      locationId: selectedLead?.locationId,
    );
    final searchState = ref.watch(clientSearchProvider(searchConfig));

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
                  'Selecciona el cliente',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Identifica con huella o busca manualmente',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Fingerprint identification option (for renewals - quick flow)
                if (widget.state.selectedClient == null) ...[
                  _buildFingerprintIdentificationCard(),
                  const SizedBox(height: 16),
                ],

                // Selected client card
                if (widget.state.selectedClient != null && !_showNewClientForm) ...[
                  _buildSelectedClientCard(widget.state.selectedClient!),
                  const SizedBox(height: 16),
                ],

                // Search or New Client toggle
                if (widget.state.selectedClient == null) ...[
                  // Toggle buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ToggleButton(
                          icon: LucideIcons.search,
                          label: 'Buscar',
                          isSelected: !_showNewClientForm,
                          onTap: () {
                            setState(() {
                              _showNewClientForm = false;
                            });
                            widget.notifier.setNewClientMode(false);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ToggleButton(
                          icon: LucideIcons.userPlus,
                          label: 'Nuevo',
                          isSelected: _showNewClientForm,
                          onTap: () {
                            setState(() {
                              _showNewClientForm = true;
                            });
                            widget.notifier.setNewClientMode(true);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search field or new client form
                  if (!_showNewClientForm) ...[
                    _buildSearchField(searchState, searchConfig),
                    const SizedBox(height: 16),
                    _buildSearchResults(searchState, searchConfig),
                  ] else ...[
                    _buildNewClientForm(),
                  ],
                ],
              ],
            ),
          ),
        ),

        // Bottom bar
        WizardBottomBar(
          nextLabel: 'Siguiente',
          showBackButton: false,
          onNext: widget.state.canProceed ? () => widget.notifier.nextStep() : null,
        ),
      ],
    );
  }

  Widget _buildSelectedClientCard(ClientForLoan client) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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
                      client.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (client.clientCode != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          client.clientCode!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  widget.notifier.clearClient();
                  _searchController.clear();
                },
                icon: const Icon(LucideIcons.x, color: AppColors.textMuted),
              ),
            ],
          ),

          // Renewal info
          if (client.hasActiveLoan && client.activeLoan != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningSurfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.alertTriangle, size: 18, color: AppColors.warningDark),
                      const SizedBox(width: 8),
                      const Text(
                        'Cliente con crédito activo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.warningDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Deuda pendiente:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(client.activeLoan!.pendingAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.warningDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tipo:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        client.activeLoan!.loantypeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.refreshCw, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        const Text(
                          'Se renovará este crédito',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (client.loanFinishedCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successSurfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.checkCircle, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    '${client.loanFinishedCount} crédito(s) terminado(s)',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Fingerprint identification card - primary option for quick renewal flow
  Widget _buildFingerprintIdentificationCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isScanning ? null : _showFingerprintScanner,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Fingerprint icon with animation
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _isScanning
                      ? const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : const Icon(
                          LucideIcons.fingerprint,
                          size: 36,
                          color: Colors.white,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Identificar con Huella',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Rápido',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isScanning
                            ? 'Escaneando huella...'
                            : 'Toca para identificar cliente automáticamente',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: Colors.white.withOpacity(0.7),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show fingerprint scanner bottom sheet
  Future<void> _showFingerprintScanner() async {
    setState(() => _isScanning = true);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FingerprintScannerSheet(
        onCancel: () {
          Navigator.pop(context);
        },
        onClientIdentified: (client) {
          Navigator.pop(context);
          // In a real implementation, this would select the identified client
          // widget.notifier.selectClient(client);
        },
      ),
    );

    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  Widget _buildSearchField(ClientSearchState searchState, ClientSearchConfig config) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _searchFocusNode.hasFocus ? AppColors.primary : AppColors.border,
          width: _searchFocusNode.hasFocus ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(LucideIcons.search, color: AppColors.textMuted, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              onChanged: (value) {
                ref.read(clientSearchProvider(config).notifier).search(value);
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.x, size: 18, color: AppColors.textMuted),
              onPressed: () {
                _searchController.clear();
                ref.read(clientSearchProvider(config).notifier).clear();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ClientSearchState searchState, ClientSearchConfig config) {
    if (searchState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (searchState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            searchState.error!,
            style: TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    // Show default clients (with active loans) when no search query
    if (searchState.query.length < 2) {
      // Show loading state for defaults
      if (searchState.isLoadingDefaults) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Show default clients with active loans
      if (searchState.defaultClients.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Icon(LucideIcons.refreshCw, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    'Clientes con crédito activo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: searchState.defaultClients.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final client = searchState.defaultClients[index];
                return _ClientResultTile(
                  client: client,
                  onTap: () {
                    widget.notifier.selectClient(client);
                    _searchController.clear();
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Hint to search for more
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.search, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Escribe para buscar más clientes...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      // No defaults, show search hint
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(LucideIcons.search, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'Ingresa al menos 2 caracteres para buscar',
                style: TextStyle(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (searchState.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(LucideIcons.userX, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
              const SizedBox(height: 16),
              const Text(
                'No se encontraron clientes',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showNewClientForm = true;
                    _nameController.text = searchState.query;
                  });
                  widget.notifier.setNewClientMode(true);
                },
                icon: const Icon(LucideIcons.userPlus, size: 18),
                label: const Text('Crear nuevo cliente'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: searchState.results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final client = searchState.results[index];
        return _ClientResultTile(
          client: client,
          onTap: () {
            widget.notifier.selectClient(client);
            _searchController.clear();
            ref.read(clientSearchProvider(config).notifier).clear();
          },
        );
      },
    );
  }

  Widget _buildNewClientForm() {
    final selectedLead = ref.watch(selectedLeadProvider);
    final locationId = selectedLead?.locationId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field
        const Text(
          'Nombre completo *',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Ej: Juan Pérez García',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => _updateNewClientInput(locationId),
        ),
        const SizedBox(height: 16),

        // Phone field
        const Text(
          'Teléfono',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            hintText: 'Ej: 555 123 4567',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            prefixIcon: const Icon(LucideIcons.phone, size: 18),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (_) => _updateNewClientInput(locationId),
        ),
        const SizedBox(height: 16),

        // Street field
        const Text(
          'Calle / Dirección',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _streetController,
          decoration: InputDecoration(
            hintText: 'Ej: Av. Principal #123',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
          ),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => _updateNewClientInput(locationId),
        ),

        // Location info
        if (selectedLead != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoSurfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.mapPin, size: 18, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Localidad: ${selectedLead.locationName ?? selectedLead.name}',
                    style: TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _updateNewClientInput(String? locationId) {
    if (_nameController.text.isNotEmpty) {
      widget.notifier.setNewClientInput(CreateBorrowerInput(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        street: _streetController.text.trim().isEmpty ? null : _streetController.text.trim(),
        locationId: locationId,
      ));
    }
  }
}

/// Toggle button for search/new client
class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Client result tile
class _ClientResultTile extends StatelessWidget {
  final ClientForLoan client;
  final VoidCallback onTap;

  const _ClientResultTile({
    required this.client,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (client.clientCode != null || client.phone != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (client.clientCode != null) ...[
                            Text(
                              client.clientCode!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (client.phone != null)
                              Text(
                                ' | ',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                          ],
                          if (client.phone != null)
                            Text(
                              client.phone!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Badges
              if (client.hasActiveLoan)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.refreshCw, size: 12, color: AppColors.warningDark),
                      const SizedBox(width: 4),
                      Text(
                        'Renovar',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.warningDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (client.loanFinishedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successSurfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${client.loanFinishedCount}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fingerprint scanner bottom sheet for client identification
class _FingerprintScannerSheet extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(ClientForLoan) onClientIdentified;

  const _FingerprintScannerSheet({
    required this.onCancel,
    required this.onClientIdentified,
  });

  @override
  State<_FingerprintScannerSheet> createState() => _FingerprintScannerSheetState();
}

class _FingerprintScannerSheetState extends State<_FingerprintScannerSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  _ScanState _scanState = _ScanState.ready;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startScanning() async {
    setState(() => _scanState = _ScanState.scanning);

    // Simulate scanning delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // For mockup, always show "not found" since we don't have SDK
    setState(() => _scanState = _ScanState.notFound);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Title
                  const Text(
                    'Identificación por Huella',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getSubtitle(),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Fingerprint scanner area
                  GestureDetector(
                    onTap: _scanState == _ScanState.ready ? _startScanning : null,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scanState == _ScanState.scanning
                              ? _pulseAnimation.value
                              : 1.0,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: _getScannerColor().withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getScannerColor().withOpacity(0.3),
                                width: 3,
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _getScannerColor().withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIcon(),
                                size: 72,
                                color: _getScannerColor(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status text
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getScannerColor(),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Not found info
                  if (_scanState == _ScanState.notFound) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warningSurfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.info, size: 20, color: AppColors.warningDark),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'El SDK de huellas no está configurado.\nBusca al cliente manualmente.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.warningDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  if (_scanState == _ScanState.ready) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startScanning,
                        icon: const Icon(LucideIcons.fingerprint),
                        label: const Text('Iniciar Escaneo'),
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
                  ] else if (_scanState == _ScanState.notFound) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onCancel,
                        icon: const Icon(LucideIcons.search),
                        label: const Text('Buscar Manualmente'),
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
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() => _scanState = _ScanState.ready);
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],

                  if (_scanState != _ScanState.scanning) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: widget.onCancel,
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (_scanState) {
      case _ScanState.ready:
        return 'Coloca el dedo del cliente en el sensor para identificarlo automáticamente';
      case _ScanState.scanning:
        return 'Mantenga el dedo quieto mientras se escanea...';
      case _ScanState.notFound:
        return 'No se pudo identificar la huella';
    }
  }

  String _getStatusText() {
    switch (_scanState) {
      case _ScanState.ready:
        return 'Toca para escanear';
      case _ScanState.scanning:
        return 'Escaneando...';
      case _ScanState.notFound:
        return 'Cliente no encontrado';
    }
  }

  IconData _getIcon() {
    switch (_scanState) {
      case _ScanState.ready:
      case _ScanState.scanning:
        return LucideIcons.fingerprint;
      case _ScanState.notFound:
        return LucideIcons.userX;
    }
  }

  Color _getScannerColor() {
    switch (_scanState) {
      case _ScanState.ready:
        return AppColors.primary;
      case _ScanState.scanning:
        return AppColors.info;
      case _ScanState.notFound:
        return AppColors.warning;
    }
  }
}

enum _ScanState { ready, scanning, notFound }
