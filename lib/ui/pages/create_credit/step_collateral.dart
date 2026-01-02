import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/colors.dart';
import '../../../providers/create_credit_provider.dart';
import '../../../providers/client_search_provider.dart';
import '../../../providers/collector_dashboard_provider.dart';
import '../../../data/repositories/borrower_repository.dart';
import 'create_credit_page.dart';

/// Step 3: Optional collateral/aval selection
class StepCollateral extends ConsumerStatefulWidget {
  final CreateCreditState state;
  final CreateCreditNotifier notifier;

  const StepCollateral({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  ConsumerState<StepCollateral> createState() => _StepCollateralState();
}

class _StepCollateralState extends ConsumerState<StepCollateral> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _showNewCollateralForm = false;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
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
    final searchState = ref.watch(collateralSearchProvider(searchConfig));

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
                  'Aval (Opcional)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Puedes agregar un aval para este crédito o continuar sin uno',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Toggle collateral
                _buildCollateralToggle(),

                // Collateral content
                if (widget.state.hasCollateral) ...[
                  const SizedBox(height: 24),

                  // Selected collateral card
                  if (widget.state.selectedCollateral != null && !_showNewCollateralForm) ...[
                    _buildSelectedCollateralCard(widget.state.selectedCollateral!),
                  ] else ...[
                    // Toggle buttons
                    Row(
                      children: [
                        Expanded(
                          child: _ToggleButton(
                            icon: LucideIcons.search,
                            label: 'Buscar',
                            isSelected: !_showNewCollateralForm,
                            onTap: () {
                              setState(() {
                                _showNewCollateralForm = false;
                              });
                              widget.notifier.setNewCollateralMode(false);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ToggleButton(
                            icon: LucideIcons.userPlus,
                            label: 'Nuevo',
                            isSelected: _showNewCollateralForm,
                            onTap: () {
                              setState(() {
                                _showNewCollateralForm = true;
                              });
                              widget.notifier.setNewCollateralMode(true);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Search or form
                    if (!_showNewCollateralForm) ...[
                      _buildSearchField(searchState, searchConfig),
                      const SizedBox(height: 16),
                      _buildSearchResults(searchState, searchConfig),
                    ] else ...[
                      _buildNewCollateralForm(),
                    ],
                  ],
                ],
              ],
            ),
          ),
        ),

        // Bottom bar
        WizardBottomBar(
          backLabel: 'Atrás',
          nextLabel: widget.state.hasCollateral ? 'Siguiente' : 'Omitir',
          onBack: () => widget.notifier.previousStep(),
          onNext: () => widget.notifier.nextStep(),
        ),
      ],
    );
  }

  Widget _buildCollateralToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.state.hasCollateral
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.shield,
              color: widget.state.hasCollateral ? AppColors.primary : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Agregar aval?',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'El aval responde por el crédito',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.state.hasCollateral,
            onChanged: (value) {
              widget.notifier.toggleCollateral(value);
              if (!value) {
                setState(() {
                  _showNewCollateralForm = false;
                });
              }
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCollateralCard(ClientForLoan collateral) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.successSurfaceLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                LucideIcons.shield,
                color: AppColors.success,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successSurfaceLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AVAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  collateral.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (collateral.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    collateral.phone!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              widget.notifier.selectCollateral(ClientForLoan(
                id: '',
                fullName: '',
              ));
              widget.notifier.toggleCollateral(true);
              _searchController.clear();
            },
            icon: const Icon(LucideIcons.x, color: AppColors.textMuted),
          ),
        ],
      ),
    );
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
                hintText: 'Buscar aval por nombre...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              onChanged: (value) {
                ref.read(collateralSearchProvider(config).notifier).search(value);
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.x, size: 18, color: AppColors.textMuted),
              onPressed: () {
                _searchController.clear();
                ref.read(collateralSearchProvider(config).notifier).clear();
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

    if (searchState.query.length < 2) {
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
                'No se encontraron personas',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showNewCollateralForm = true;
                    _nameController.text = searchState.query;
                  });
                  widget.notifier.setNewCollateralMode(true);
                },
                icon: const Icon(LucideIcons.userPlus, size: 18),
                label: const Text('Crear nuevo aval'),
              ),
            ],
          ),
        ),
      );
    }

    // Filter out the borrower from results
    final filteredResults = searchState.results.where((c) {
      return c.id != widget.state.selectedClient?.id;
    }).toList();

    if (filteredResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(LucideIcons.userX, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
              const SizedBox(height: 16),
              const Text(
                'No hay otras personas disponibles',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'El aval debe ser diferente al cliente',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final person = filteredResults[index];
        return _PersonResultTile(
          person: person,
          onTap: () {
            widget.notifier.selectCollateral(person);
            _searchController.clear();
            ref.read(collateralSearchProvider(config).notifier).clear();
          },
        );
      },
    );
  }

  Widget _buildNewCollateralForm() {
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
            hintText: 'Ej: María López García',
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
          onChanged: (_) => _updateNewCollateralInput(),
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
          onChanged: (_) => _updateNewCollateralInput(),
        ),

        // Info
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.infoSurfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.info, size: 18, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'El aval será responsable del crédito si el cliente no paga',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _updateNewCollateralInput() {
    if (_nameController.text.isNotEmpty) {
      widget.notifier.setNewCollateralInput(CreateBorrowerInput(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      ));
    }
  }
}

/// Toggle button
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
          padding: const EdgeInsets.symmetric(vertical: 14),
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
                size: 18,
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

/// Person result tile
class _PersonResultTile extends StatelessWidget {
  final ClientForLoan person;
  final VoidCallback onTap;

  const _PersonResultTile({
    required this.person,
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
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    person.fullName.isNotEmpty ? person.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
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
                      person.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (person.phone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        person.phone!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
