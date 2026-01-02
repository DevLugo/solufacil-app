import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../providers/collector_dashboard_provider.dart';

/// Week filter options
enum WeekFilter {
  week4(4, '4 sem'),
  week5(5, '5 sem'),
  week6Plus(6, '6+ sem');

  final int value;
  final String label;
  const WeekFilter(this.value, this.label);

  bool matches(int weeks) {
    if (this == week6Plus) return weeks >= 6;
    return weeks == value;
  }
}

/// Filter state for critical clients
class CriticalClientsFilter {
  final String? selectedLocality;
  final String? selectedRoute;
  final WeekFilter? selectedWeekFilter;

  const CriticalClientsFilter({
    this.selectedLocality,
    this.selectedRoute,
    this.selectedWeekFilter,
  });

  CriticalClientsFilter copyWith({
    String? selectedLocality,
    String? selectedRoute,
    WeekFilter? selectedWeekFilter,
    bool clearLocality = false,
    bool clearRoute = false,
    bool clearWeeks = false,
  }) {
    return CriticalClientsFilter(
      selectedLocality: clearLocality ? null : (selectedLocality ?? this.selectedLocality),
      selectedRoute: clearRoute ? null : (selectedRoute ?? this.selectedRoute),
      selectedWeekFilter: clearWeeks ? null : (selectedWeekFilter ?? this.selectedWeekFilter),
    );
  }

  bool get hasFilters => selectedLocality != null || selectedRoute != null || selectedWeekFilter != null;
  int get filterCount => (selectedLocality != null ? 1 : 0) + (selectedRoute != null ? 1 : 0) + (selectedWeekFilter != null ? 1 : 0);
}

/// Filter state provider
final criticalClientsFilterProvider = StateProvider<CriticalClientsFilter>((ref) {
  return const CriticalClientsFilter();
});

class CriticalClientsPage extends ConsumerWidget {
  const CriticalClientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(collectorDashboardStatsProvider);
    final filter = ref.watch(criticalClientsFilterProvider);
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: statsAsync.when(
        data: (stats) {
          if (stats.criticalClientsList.isEmpty) {
            return _buildScaffold(context, ref, 0, 0, false, child: _EmptyState());
          }

          final localities = stats.criticalClientsList
              .where((c) => c.leadLocality != null && c.leadLocality!.isNotEmpty)
              .map((c) => c.leadLocality!)
              .toSet()
              .toList()
            ..sort();

          final routes = stats.criticalClientsList
              .where((c) => c.routeName != null && c.routeName!.isNotEmpty)
              .map((c) => c.routeName!)
              .toSet()
              .toList()
            ..sort();

          // Get counts per week category for display
          final week4Count = stats.criticalClientsList.where((c) => c.weeksWithoutPayment == 4).length;
          final week5Count = stats.criticalClientsList.where((c) => c.weeksWithoutPayment == 5).length;
          final week6PlusCount = stats.criticalClientsList.where((c) => c.weeksWithoutPayment >= 6).length;

          var filteredClients = stats.criticalClientsList;
          if (filter.selectedLocality != null) {
            filteredClients = filteredClients
                .where((c) => c.leadLocality == filter.selectedLocality)
                .toList();
          }
          if (filter.selectedRoute != null) {
            filteredClients = filteredClients
                .where((c) => c.routeName == filter.selectedRoute)
                .toList();
          }
          if (filter.selectedWeekFilter != null) {
            filteredClients = filteredClients
                .where((c) => filter.selectedWeekFilter!.matches(c.weeksWithoutPayment))
                .toList();
          }

          return _buildScaffold(
            context,
            ref,
            stats.criticalClientsList.length,
            filteredClients.length,
            filter.hasFilters,
            localities: localities,
            routes: routes,
            weekCounts: {
              WeekFilter.week4: week4Count,
              WeekFilter.week5: week5Count,
              WeekFilter.week6Plus: week6PlusCount,
            },
            child: filteredClients.isEmpty
                ? _NoResultsState()
                : _ClientsList(clients: filteredClients, currencyFormat: currencyFormat),
          );
        },
        loading: () => _buildScaffold(context, ref, 0, 0, false, child: const Center(child: CircularProgressIndicator())),
        error: (_, __) => _buildScaffold(context, ref, 0, 0, false, child: _ErrorState()),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    WidgetRef ref,
    int totalCount,
    int filteredCount,
    bool hasFilters, {
    required Widget child,
    List<String>? localities,
    List<String>? routes,
    Map<WeekFilter, int>? weekCounts,
  }) {
    final filter = ref.watch(criticalClientsFilterProvider);

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.secondary,
          pinned: true,
          floating: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.alertTriangle, size: 18, color: Color(0xFFDC2626)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Clientes Criticos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (totalCount > 0)
                    Text(
                      hasFilters ? '$filteredCount de $totalCount' : '$totalCount clientes',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.normal),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            if (localities != null && localities.isNotEmpty)
              _FilterButton(
                filterCount: filter.filterCount,
                onTap: () => _showFilterSheet(context, ref, localities, routes ?? [], weekCounts ?? {}, filter),
              ),
            const SizedBox(width: 8),
          ],
        ),
        // Active filters chips
        if (hasFilters)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.background,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (filter.selectedLocality != null)
                    _ActiveFilterChip(
                      icon: LucideIcons.mapPin,
                      label: filter.selectedLocality!,
                      onRemove: () => ref.read(criticalClientsFilterProvider.notifier).state =
                          filter.copyWith(clearLocality: true),
                    ),
                  if (filter.selectedRoute != null)
                    _ActiveFilterChip(
                      icon: LucideIcons.navigation,
                      label: filter.selectedRoute!,
                      onRemove: () => ref.read(criticalClientsFilterProvider.notifier).state =
                          filter.copyWith(clearRoute: true),
                    ),
                  if (filter.selectedWeekFilter != null)
                    _ActiveFilterChip(
                      icon: LucideIcons.calendar,
                      label: filter.selectedWeekFilter!.label,
                      onRemove: () => ref.read(criticalClientsFilterProvider.notifier).state =
                          filter.copyWith(clearWeeks: true),
                    ),
                ],
              ),
            ),
          ),
      ],
      body: child,
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref, List<String> localities, List<String> routes, Map<WeekFilter, int> weekCounts, CriticalClientsFilter filter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _FilterSheet(
        localities: localities,
        routes: routes,
        weekCounts: weekCounts,
        filter: filter,
        onApply: (newFilter) {
          ref.read(criticalClientsFilterProvider.notifier).state = newFilter;
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int filterCount;
  final VoidCallback onTap;

  const _FilterButton({required this.filterCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasFilters = filterCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasFilters ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasFilters ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.slidersHorizontal,
              size: 16,
              color: hasFilters ? AppColors.primary : AppColors.textSecondary,
            ),
            if (hasFilters) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$filterCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({required this.icon, required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.secondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.x, size: 12, color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List<String> localities;
  final List<String> routes;
  final Map<WeekFilter, int> weekCounts;
  final CriticalClientsFilter filter;
  final ValueChanged<CriticalClientsFilter> onApply;

  const _FilterSheet({
    required this.localities,
    required this.routes,
    required this.weekCounts,
    required this.filter,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _selectedLocality;
  late String? _selectedRoute;
  late WeekFilter? _selectedWeekFilter;
  String _localitySearch = '';
  String _routeSearch = '';

  @override
  void initState() {
    super.initState();
    _selectedLocality = widget.filter.selectedLocality;
    _selectedRoute = widget.filter.selectedRoute;
    _selectedWeekFilter = widget.filter.selectedWeekFilter;
  }

  List<String> get _filteredLocalities {
    if (_localitySearch.isEmpty) return widget.localities;
    return widget.localities
        .where((l) => l.toLowerCase().contains(_localitySearch.toLowerCase()))
        .toList();
  }

  List<String> get _filteredRoutes {
    if (_routeSearch.isEmpty) return widget.routes;
    return widget.routes
        .where((r) => r.toLowerCase().contains(_routeSearch.toLowerCase()))
        .toList();
  }

  bool get _hasSelection => _selectedLocality != null || _selectedRoute != null || _selectedWeekFilter != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                Icon(LucideIcons.slidersHorizontal, size: 20, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  'Filtros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
                const Spacer(),
                if (_hasSelection)
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedLocality = null;
                      _selectedRoute = null;
                      _selectedWeekFilter = null;
                    }),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Limpiar todo'),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weeks filter - 3 buttons
                  _buildSectionHeader('Semanas sin pagar', LucideIcons.calendar),
                  const SizedBox(height: 10),
                  Row(
                    children: WeekFilter.values.map((wf) {
                      final isSelected = _selectedWeekFilter == wf;
                      final count = widget.weekCounts[wf] ?? 0;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: wf != WeekFilter.values.last ? 8 : 0),
                          child: GestureDetector(
                            onTap: count > 0 ? () => setState(() => _selectedWeekFilter = isSelected ? null : wf) : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? _getWeekFilterColor(wf) : (count > 0 ? AppColors.surface : AppColors.surface.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? _getWeekFilterColor(wf) : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    wf.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : (count > 0 ? AppColors.textPrimary : AppColors.textMuted),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.white70 : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Route filter with search
                  if (widget.routes.isNotEmpty) ...[
                    _buildSectionHeader('Ruta', LucideIcons.navigation),
                    const SizedBox(height: 10),
                    _buildSearchableFilter(
                      searchValue: _routeSearch,
                      onSearchChanged: (v) => setState(() => _routeSearch = v),
                      placeholder: 'Buscar ruta...',
                      items: _filteredRoutes,
                      selectedItem: _selectedRoute,
                      onItemSelected: (r) => setState(() => _selectedRoute = _selectedRoute == r ? null : r),
                      showSearch: widget.routes.length > 5,
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Locality filter with search
                  _buildSectionHeader('Localidad', LucideIcons.mapPin),
                  const SizedBox(height: 10),
                  _buildSearchableFilter(
                    searchValue: _localitySearch,
                    onSearchChanged: (v) => setState(() => _localitySearch = v),
                    placeholder: 'Buscar localidad...',
                    items: _filteredLocalities,
                    selectedItem: _selectedLocality,
                    onItemSelected: (l) => setState(() => _selectedLocality = _selectedLocality == l ? null : l),
                    showSearch: widget.localities.length > 5,
                  ),
                ],
              ),
            ),
          ),
          // Apply button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onApply(CriticalClientsFilter(
                  selectedLocality: _selectedLocality,
                  selectedRoute: _selectedRoute,
                  selectedWeekFilter: _selectedWeekFilter,
                )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Aplicar filtros', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSearchableFilter({
    required String searchValue,
    required ValueChanged<String> onSearchChanged,
    required String placeholder,
    required List<String> items,
    required String? selectedItem,
    required ValueChanged<String> onItemSelected,
    required bool showSearch,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSearch) ...[
          TextField(
            onChanged: onSearchChanged,
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        // Show selected item first if not in filtered list
        if (selectedItem != null && !items.contains(selectedItem))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildFilterChip(selectedItem, true, () => onItemSelected(selectedItem)),
          ),
        // Items - limit display to avoid too many
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin resultados',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.take(showSearch ? 15 : 30).map((item) {
              final isSelected = selectedItem == item;
              return _buildFilterChip(item, isSelected, () => onItemSelected(item));
            }).toList(),
          ),
        if (items.length > (showSearch ? 15 : 30))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${items.length - (showSearch ? 15 : 30)} mas - usa el buscador',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Color _getWeekFilterColor(WeekFilter wf) {
    switch (wf) {
      case WeekFilter.week4:
        return const Color(0xFFEA580C);
      case WeekFilter.week5:
        return const Color(0xFFDC2626);
      case WeekFilter.week6Plus:
        return const Color(0xFF991B1B);
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.checkCircle2, size: 48, color: AppColors.success),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin clientes criticos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Todos los clientes tienen menos de 4 semanas sin pagar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.searchX, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Sin resultados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.secondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Ajusta los filtros para ver clientes',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          const Text('Error al cargar los datos'),
        ],
      ),
    );
  }
}

class _ClientsList extends StatelessWidget {
  final List<CriticalClient> clients;
  final NumberFormat currencyFormat;

  const _ClientsList({required this.clients, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final grouped = <int, List<CriticalClient>>{};
    for (final client in clients) {
      grouped.putIfAbsent(client.weeksWithoutPayment, () => []);
      grouped[client.weeksWithoutPayment]!.add(client);
    }
    final sortedWeeks = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: sortedWeeks.length,
      itemBuilder: (context, groupIndex) {
        final weeks = sortedWeeks[groupIndex];
        final groupClients = grouped[weeks]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (groupIndex > 0) const SizedBox(height: 20),
            // Group header - minimal
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getWeekColor(weeks),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$weeks semanas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _getWeekColor(weeks),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${groupClients.length} cliente${groupClients.length > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            ...groupClients.map((client) => _ClientCard(
              client: client,
              currencyFormat: currencyFormat,
              weekColor: _getWeekColor(weeks),
            )),
          ],
        );
      },
    );
  }

  Color _getWeekColor(int weeks) {
    if (weeks >= 6) return const Color(0xFF991B1B);
    if (weeks >= 5) return const Color(0xFFDC2626);
    return const Color(0xFFEA580C);
  }
}

class _ClientCard extends StatelessWidget {
  final CriticalClient client;
  final NumberFormat currencyFormat;
  final Color weekColor;

  const _ClientCard({
    required this.client,
    required this.currencyFormat,
    required this.weekColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Top row: Name + Weeks badge
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: weekColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(client.clientName),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: weekColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.clientName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (client.routeName != null && client.routeName!.isNotEmpty) ...[
                                Icon(LucideIcons.navigation, size: 11, color: AppColors.textMuted),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    client.routeName!,
                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              if (client.routeName != null && client.leadLocality != null) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text('•', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                ),
                              ],
                              if (client.leadLocality != null && client.leadLocality!.isNotEmpty) ...[
                                Icon(LucideIcons.mapPin, size: 11, color: AppColors.textMuted),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    client.leadLocality!,
                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Weeks badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: weekColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${client.weeksWithoutPayment}s',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stats row
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatColumn(
                          label: 'Pendiente',
                          value: currencyFormat.format(client.pendingAmount),
                          valueColor: const Color(0xFFDC2626),
                        ),
                      ),
                      Container(width: 1, height: 30, color: AppColors.border),
                      Expanded(
                        child: _StatColumn(
                          label: 'Semanal',
                          value: currencyFormat.format(client.expectedWeeklyPayment),
                          valueColor: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _ActionBtn(
                  icon: LucideIcons.phone,
                  label: 'Llamar',
                  onTap: client.phone != null ? () => _makeCall(client.phone!) : null,
                ),
                _ActionBtn(
                  icon: LucideIcons.dollarSign,
                  label: 'Cobrar',
                  isPrimary: true,
                  onTap: () => context.push('${AppRoutes.registerPayment}?loanId=${client.loanId}'),
                ),
                _ActionBtn(
                  icon: LucideIcons.messageCircle,
                  label: 'WhatsApp',
                  onTap: client.phone != null ? () => _openWhatsApp(client.phone!) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/52$cleanPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatColumn({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final color = !isEnabled
        ? AppColors.textMuted
        : isPrimary
            ? AppColors.primary
            : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
