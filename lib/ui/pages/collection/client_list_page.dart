import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';

class ClientListPage extends StatelessWidget {
  final String? locationId;

  const ClientListPage({super.key, this.locationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Col. Centro'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.background,
            child: Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Total',
                    value: '\$4,200',
                    color: AppColors.secondary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.border,
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Cobrado',
                    value: '\$1,680',
                    color: AppColors.success,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.border,
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Pendiente',
                    value: '\$2,520',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),

          // Client list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mockClients.length,
              itemBuilder: (context, index) {
                final client = _mockClients[index];
                return _ClientCard(
                  name: client['name']!,
                  weeklyPayment: client['payment']!,
                  status: client['status']!,
                  loanInfo: client['loanInfo']!,
                  onTap: () {
                    context.push('${AppRoutes.registerPayment}?loanId=$index');
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

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

final _mockClients = [
  {
    'name': 'María García López',
    'payment': '\$350',
    'status': 'pending',
    'loanInfo': 'Semana 4 de 10',
  },
  {
    'name': 'Juan Pérez Hernández',
    'payment': '\$280',
    'status': 'pending',
    'loanInfo': 'Semana 6 de 12',
  },
  {
    'name': 'Ana Martínez Ruiz',
    'payment': '\$420',
    'status': 'paid',
    'loanInfo': 'Semana 8 de 10',
  },
  {
    'name': 'Carlos Sánchez Luna',
    'payment': '\$300',
    'status': 'late',
    'loanInfo': 'Semana 3 de 10 (1 atrasado)',
  },
  {
    'name': 'Rosa Hernández Vega',
    'payment': '\$250',
    'status': 'pending',
    'loanInfo': 'Semana 5 de 12',
  },
];

class _ClientCard extends StatelessWidget {
  final String name;
  final String weeklyPayment;
  final String status;
  final String loanInfo;
  final VoidCallback onTap;

  const _ClientCard({
    required this.name,
    required this.weeklyPayment,
    required this.status,
    required this.loanInfo,
    required this.onTap,
  });

  Color get _statusColor {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'late':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'paid':
        return LucideIcons.checkCircle2;
      case 'late':
        return LucideIcons.alertTriangle;
      default:
        return LucideIcons.clock;
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'paid':
        return 'Pagado';
      case 'late':
        return 'Atrasado';
      default:
        return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: status == 'paid' ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.split(' ').map((n) => n[0]).take(2).join(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _statusColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Client info
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
                      loanInfo,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(_statusIcon, size: 14, color: _statusColor),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Payment amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    weeklyPayment,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (status != 'paid')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: const Text(
                        'Cobrar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
