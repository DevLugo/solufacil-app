import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/client_history.dart';
import '../../providers/client_history_provider.dart';

class ClientSearchBar extends ConsumerStatefulWidget {
  final Function(ClientSearchResult) onClientSelected;

  const ClientSearchBar({
    super.key,
    required this.onClientSelected,
  });

  @override
  ConsumerState<ClientSearchBar> createState() => _ClientSearchBarState();
}

class _ClientSearchBarState extends ConsumerState<ClientSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showResults = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(clientSearchProvider);

    return Column(
      children: [
        // Premium Search Input
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? AppColors.primary
                  : AppColors.darkBorder.withOpacity(0.5),
              width: _focusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: _focusNode.hasFocus ? AppTheme.glowPrimary : null,
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(
                  Icons.search_rounded,
                  color: _focusNode.hasFocus
                      ? AppColors.primary
                      : AppColors.textSecondaryDark,
                  size: 22,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente por nombre o código...',
                    hintStyle: TextStyle(
                      color: AppColors.textMutedDark,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(clientSearchProvider.notifier).search(value);
                    setState(() {});
                  },
                ),
              ),
              if (_controller.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceHighlight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          _controller.clear();
                          ref.read(clientSearchProvider.notifier).clear();
                          setState(() {});
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Search results dropdown
        if (_showResults && searchState.query.length >= 2) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceElevated.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppColors.darkBorder.withOpacity(0.5),
                  ),
                  boxShadow: AppTheme.shadowLg,
                ),
                child: _buildResultsList(searchState),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultsList(SearchState searchState) {
    if (searchState.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Buscando...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (searchState.error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                searchState.error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.errorLight,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    if (searchState.results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceHighlight,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                Icons.person_search_rounded,
                color: AppColors.textMutedDark.withOpacity(0.5),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron clientes',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Intenta con otro nombre o código',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMutedDark,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: searchState.results.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: AppColors.darkDivider,
        indent: 68,
      ),
      itemBuilder: (context, index) {
        final client = searchState.results[index];
        return _ClientResultItem(
          client: client,
          onTap: () {
            widget.onClientSelected(client);
            _controller.clear();
            _focusNode.unfocus();
          },
        );
      },
    );
  }
}

class _ClientResultItem extends StatelessWidget {
  final ClientSearchResult client;
  final VoidCallback onTap;

  const _ClientResultItem({
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Client info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (client.displayCode != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurfaceHighlight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              client.displayCode!,
                              style:
                                  Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppColors.textSecondaryDark,
                                        fontWeight: FontWeight.w500,
                                      ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (client.locationName != null)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: AppColors.textMutedDark,
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    client.locationName!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textMutedDark,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (client.hasLoans)
                    _RoleBadge(
                      label: 'Cliente',
                      count: client.totalLoans,
                      color: AppColors.primary,
                    ),
                  if (client.hasLoans && client.hasBeenCollateral)
                    const SizedBox(height: 4),
                  if (client.hasBeenCollateral)
                    _RoleBadge(
                      label: 'Aval',
                      count: client.collateralLoans,
                      color: AppColors.accent,
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

class _RoleBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _RoleBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Cliente' ? Icons.person_rounded : Icons.verified_user_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
