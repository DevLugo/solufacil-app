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

/// Filter state for critical clients
class CriticalClientsFilter {
  final String? selectedRoute;
  final int? selectedWeeks;

  const CriticalClientsFilter({
    this.selectedRoute,
    this.selectedWeeks,
  });

  CriticalClientsFilter copyWith({
    String? selectedRoute,
    int? selectedWeeks,
    bool clearRoute = false,
    bool clearWeeks = false,
  }) {
    return CriticalClientsFilter(
      selectedRoute: clearRoute ? null : (selectedRoute ?? this.selectedRoute),
      selectedWeeks: clearWeeks ? null : (selectedWeeks ?? this.selectedWeeks),
    );
  }
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
      appBar: AppBar(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(LucideIcons.alertTriangle, size: 20),
            const SizedBox(width: 8),
            const Text('Clientes Criticos'),
          ],
        ),
        elevation: 0,
      ),
      body: statsAsync.when(
        data: (stats) {
          if (stats.criticalClientsList.isEmpty) {
            return _EmptyState();
          }

          // Get unique localities and weeks for filter options
          final localities = stats.criticalClientsList
              .where((c) => c.leadLocality != null && c.leadLocality!.isNotEmpty)
              .map((c) => c.leadLocality!)
              .toSet()
              .toList()
            ..sort();

          final weeks = stats.criticalClientsList
              .map((c) => c.weeksWithoutPayment)
              .toSet()
              .toList()
            ..sort();

          // Apply filters
          var filteredClients = stats.criticalClientsList;
          if (filter.selectedRoute != null) {
            // Filter by locality (using selectedRoute field for locality)
            filteredClients = filteredClients
                .where((c) => c.leadLocality == filter.selectedRoute)
                .toList();
          }
          if (filter.selectedWeeks != null) {
            filteredClients = filteredClients
                .where((c) => c.weeksWithoutPayment == filter.selectedWeeks)
                .toList();
          }

          return Column(
            children: [
              // Filter section
              _FilterSection(
                localities: localities,
                weeks: weeks,
                filter: filter,
                totalCount: stats.criticalClientsList.length,
                filteredCount: filteredClients.length,
              ),
              // Clients list
              Expanded(
                child: filteredClients.isEmpty
                    ? _NoResultsState()
                    : _ClientsList(
                        clients: filteredClients,
                        currencyFormat: currencyFormat,
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorState(),
      ),
    );
  }
}

class _FilterSection extends ConsumerWidget {
  final List<String> localities;
  final List<int> weeks;
  final CriticalClientsFilter filter;
  final int totalCount;
  final int filteredCount;

  const _FilterSection({
    required this.localities,
    required this.weeks,
    required this.filter,
    required this.totalCount,
    required this.filteredCount,
  });

  void _showLocalitySelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet(
        title: 'Seleccionar Localidad',
        selectedValue: filter.selectedRoute,
        options: localities,
        onSelect: (value) {
          ref.read(criticalClientsFilterProvider.notifier).state =
              filter.copyWith(selectedRoute: value, clearRoute: value == null);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showWeeksSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet(
        title: 'Seleccionar Semanas',
        selectedValue: filter.selectedWeeks,
        options: weeks,
        labelBuilder: (w) => '$w semanas sin pagar',
        onSelect: (value) {
          ref.read(criticalClientsFilterProvider.notifier).state =
              filter.copyWith(selectedWeeks: value as int?, clearWeeks: value == null);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFilters = filter.selectedRoute != null || filter.selectedWeeks != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter row
          Row(
            children: [
              Icon(LucideIcons.filter, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Filtrar por:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (hasFilters)
                TextButton.icon(
                  onPressed: () {
                    ref.read(criticalClientsFilterProvider.notifier).state =
                        const CriticalClientsFilter();
                  },
                  icon: Icon(LucideIcons.x, size: 14),
                  label: const Text('Limpiar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Locality filter chip
              _FilterChip(
                icon: LucideIcons.mapPin,
                label: filter.selectedRoute ?? 'Localidad',
                isSelected: filter.selectedRoute != null,
                onTap: () => _showLocalitySelector(context, ref),
              ),
              // Weeks filter chip
              _FilterChip(
                icon: LucideIcons.clock,
                label: filter.selectedWeeks != null
                    ? '${filter.selectedWeeks} sem'
                    : 'Semanas',
                isSelected: filter.selectedWeeks != null,
                onTap: () => _showWeeksSelector(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Results count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.users, size: 14, color: AppColors.error),
                const SizedBox(width: 6),
                Text(
                  hasFilters
                      ? '$filteredCount de $totalCount clientes'
                      : '$totalCount clientes criticos',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet<T> extends StatelessWidget {
  final String title;
  final T? selectedValue;
  final List<T> options;
  final String Function(T)? labelBuilder;
  final ValueChanged<T?> onSelect;

  const _FilterBottomSheet({
    required this.title,
    required this.selectedValue,
    required this.options,
    this.labelBuilder,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const Spacer(),
                if (selectedValue != null)
                  TextButton(
                    onPressed: () => onSelect(null),
                    child: Text(
                      'Quitar filtro',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: AppColors.border, height: 1),
          // Options list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == selectedValue;
                final label = labelBuilder?.call(option) ?? option.toString();

                return ListTile(
                  onTap: () => onSelect(option),
                  leading: Icon(
                    isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                    size: 20,
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.secondary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(LucideIcons.check, color: AppColors.primary, size: 18)
                      : null,
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronDown,
              size: 12,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.checkCircle2,
              size: 64,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin clientes criticos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Todos los clientes estan al corriente o tienen menos de 4 semanas sin pagar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.searchX,
              size: 48,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin resultados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay clientes que coincidan con los filtros seleccionados',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
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

  const _ClientsList({
    required this.clients,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    // Group by weeks without payment
    final grouped = <int, List<CriticalClient>>{};
    for (final client in clients) {
      final weeks = client.weeksWithoutPayment;
      grouped.putIfAbsent(weeks, () => []);
      grouped[weeks]!.add(client);
    }

    // Sort groups by weeks (lowest first - 4 weeks before 5+)
    final sortedWeeks = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedWeeks.length,
      itemBuilder: (context, groupIndex) {
        final weeks = sortedWeeks[groupIndex];
        final groupClients = grouped[weeks]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header
            Container(
              margin: EdgeInsets.only(bottom: 12, top: groupIndex > 0 ? 16.0 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getWeeksColor(weeks).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getWeeksColor(weeks).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 16,
                    color: _getWeeksColor(weeks),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$weeks semanas sin pagar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getWeeksColor(weeks),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getWeeksColor(weeks),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${groupClients.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Clients in this group
            ...groupClients.map((client) => _ClientCard(
              client: client,
              currencyFormat: currencyFormat,
            )),
          ],
        );
      },
    );
  }

  Color _getWeeksColor(int weeks) {
    if (weeks >= 8) return const Color(0xFF7C2D12); // Very dark red
    if (weeks >= 6) return const Color(0xFFDC2626); // Red
    if (weeks >= 5) return const Color(0xFFEA580C); // Orange
    return const Color(0xFFF59E0B); // Amber for 4 weeks
  }
}

class _ClientCard extends StatelessWidget {
  final CriticalClient client;
  final NumberFormat currencyFormat;

  const _ClientCard({
    required this.client,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowCard,
        border: Border.all(
          color: AppColors.error.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Main Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(client.clientName),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and code
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.clientName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (client.clientCode != null)
                            Text(
                              'Codigo: ${client.clientCode}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Weeks badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${client.weeksWithoutPayment}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'sem',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Location info row - Route and Lead Locality
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Lead Locality badge (primary)
                    if (client.leadLocality != null && client.leadLocality!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.mapPin, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                client.leadLocality!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Route badge (secondary)
                    if (client.routeName != null && client.routeName!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.navigation, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                client.routeName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stats row
                Row(
                  children: [
                    _StatItem(
                      icon: LucideIcons.dollarSign,
                      label: 'Pendiente',
                      value: currencyFormat.format(client.pendingAmount),
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 16),
                    _StatItem(
                      icon: LucideIcons.calendar,
                      label: 'Pago semanal',
                      value: currencyFormat.format(client.expectedWeeklyPayment),
                      color: AppColors.info,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action Buttons
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.radiusLg),
                bottomRight: Radius.circular(AppTheme.radiusLg),
              ),
            ),
            child: Row(
              children: [
                // Call button
                Expanded(
                  child: _ActionButton(
                    icon: LucideIcons.phone,
                    label: 'Llamar',
                    color: AppColors.success,
                    onTap: client.phone != null
                        ? () => _makePhoneCall(client.phone!)
                        : null,
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                // Collect button
                Expanded(
                  child: _ActionButton(
                    icon: LucideIcons.dollarSign,
                    label: 'Cobrar',
                    color: AppColors.primary,
                    onTap: () {
                      context.push(
                        '${AppRoutes.registerPayment}?loanId=${client.loanId}',
                      );
                    },
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                // WhatsApp button
                Expanded(
                  child: _ActionButton(
                    icon: LucideIcons.messageCircle,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: client.phone != null
                        ? () => _openWhatsApp(client.phone!)
                        : null,
                  ),
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
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/52$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isEnabled ? color : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isEnabled ? color : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
