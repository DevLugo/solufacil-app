import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';

class SelectLocationPage extends StatelessWidget {
  const SelectLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Cobrar Ruta'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () {
              // Sync data
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with date
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.background,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoy, 15 Enero 2024',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '12 cobros pendientes',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Row(
                    children: const [
                      Icon(LucideIcons.checkCircle2, size: 14, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        'Sincronizado',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar localidad...',
                prefixIcon: const Icon(LucideIcons.search),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          // Location list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return _LocationCard(
                  name: _mockLocations[index]['name']!,
                  clientCount: _mockLocations[index]['clients']!,
                  pendingAmount: _mockLocations[index]['pending']!,
                  progress: double.parse(_mockLocations[index]['progress']!),
                  onTap: () {
                    context.push('${AppRoutes.clientList}?locationId=$index');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final _mockLocations = [
  {'name': 'Col. Centro', 'clients': '8', 'pending': '\$4,200', 'progress': '0.6'},
  {'name': 'Col. Reforma', 'clients': '5', 'pending': '\$2,500', 'progress': '0.4'},
  {'name': 'Col. Industrial', 'clients': '3', 'pending': '\$1,800', 'progress': '0.75'},
  {'name': 'Col. Jardines', 'clients': '4', 'pending': '\$2,100', 'progress': '0.5'},
  {'name': 'Col. Altavista', 'clients': '2', 'pending': '\$900', 'progress': '0.8'},
];

class _LocationCard extends StatelessWidget {
  final String name;
  final String clientCount;
  final String pendingAmount;
  final double progress;
  final VoidCallback onTap;

  const _LocationCard({
    required this.name,
    required this.clientCount,
    required this.pendingAmount,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Icon(LucideIcons.mapPin, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$clientCount clientes pendientes',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pendingAmount,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(
                        LucideIcons.chevronRight,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.border.withOpacity(0.5),
                  valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
