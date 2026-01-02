import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_history_provider.dart';
import '../../providers/powersync_provider.dart';
import '../widgets/client_search_bar.dart';
import '../widgets/client_profile_card.dart';
import '../widgets/loans_list.dart';

class ClientHistoryPage extends ConsumerStatefulWidget {
  const ClientHistoryPage({super.key});

  @override
  ConsumerState<ClientHistoryPage> createState() => _ClientHistoryPageState();
}

class _ClientHistoryPageState extends ConsumerState<ClientHistoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final selectedClientState = ref.watch(selectedClientProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    final size = MediaQuery.of(context).size;
    final hasSelectedClient = selectedClientState.selectedClient != null;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(size),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Dynamic App Bar based on selection state
                hasSelectedClient
                    ? _buildClientAppBar(selectedClientState, isSyncing)
                    : _buildSearchAppBar(isSyncing),

                // Main Content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await triggerSync(ref);
                        if (selectedClientState.selectedClient != null) {
                          await ref.read(selectedClientProvider.notifier).refresh();
                        }
                      },
                      color: AppColors.primary,
                      backgroundColor: AppColors.background,
                      child: hasSelectedClient
                          ? _buildClientContent(selectedClientState)
                          : _buildSearchContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH MODE (No client selected)
  // ============================================================

  Widget _buildSearchAppBar(bool isSyncing) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          // Top row with back button and sync status
          Row(
            children: [
              _buildIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Buscar Cliente',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              // Sync indicator
              if (isSyncing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sync',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Search bar integrated in app bar
          ClientSearchBar(
            onClientSelected: (client) {
              ref.read(selectedClientProvider.notifier).selectClient(client);
              ref.read(clientSearchProvider.notifier).clear();
              // Reset animation for client content
              _animationController.reset();
              _animationController.forward();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildNoClientState(),
        ),
      ],
    );
  }

  // ============================================================
  // CLIENT MODE (Client selected)
  // ============================================================

  Widget _buildClientAppBar(SelectedClientState state, bool isSyncing) {
    final client = state.selectedClient!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back/Clear button
          _buildIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () {
              ref.read(selectedClientProvider.notifier).clear();
              // Reset animation for search content
              _animationController.reset();
              _animationController.forward();
            },
          ),
          const SizedBox(width: 12),

          // Client name as title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (client.clientCode != null || client.locationName != null)
                  Row(
                    children: [
                      Icon(
                        client.clientCode != null ? Icons.badge_outlined : Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        client.clientCode ?? client.locationName ?? '',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Sync button
          _buildIconButton(
            icon: Icons.sync_rounded,
            isLoading: isSyncing,
            onPressed: isSyncing
                ? null
                : () async {
                    await triggerSync(ref);
                    await ref.read(selectedClientProvider.notifier).refresh();
                  },
          ),

          const SizedBox(width: 4),

          // New search button
          _buildIconButton(
            icon: Icons.search_rounded,
            onPressed: () {
              ref.read(selectedClientProvider.notifier).clear();
              _animationController.reset();
              _animationController.forward();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClientContent(SelectedClientState state) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // Client Profile Card (compact version without name since it's in app bar)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClientProfileCard(
              client: state.selectedClient!,
              history: state.history,
              isLoading: state.isLoading,
              showHeader: false, // New prop to hide redundant header
              onClear: () {
                ref.read(selectedClientProvider.notifier).clear();
              },
            ),
          ),
        ),

        // Loans Sections
        if (state.history != null) ...[
          // Loans as Client
          if (state.history!.loansAsClient.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                icon: Icons.account_circle_outlined,
                title: 'Préstamos como Cliente',
                count: state.history!.loansAsClient.length,
                color: AppColors.primary,
              ),
            ),
            SliverToBoxAdapter(
              child: LoansList(
                loans: state.history!.loansAsClient,
                isCollateral: false,
              ),
            ),
          ],

          // Loans as Collateral
          if (state.history!.loansAsCollateral.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                icon: Icons.verified_user_outlined,
                title: 'Préstamos como Aval',
                count: state.history!.loansAsCollateral.length,
                color: AppColors.accent,
              ),
            ),
            SliverToBoxAdapter(
              child: LoansList(
                loans: state.history!.loansAsCollateral,
                isCollateral: true,
              ),
            ),
          ],

          // No loans empty state
          if (state.history!.loansAsClient.isEmpty &&
              state.history!.loansAsCollateral.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyLoansState(),
            ),
        ],

        // Loading state
        if (state.isLoading && state.history == null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : Icon(
                    icon,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLoansState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 48,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin historial de préstamos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este cliente no tiene préstamos registrados',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoClientState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon Container
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 56,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Busca un cliente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa nombre o código para ver\nel historial completo de préstamos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Quick Tips - more compact
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border.withOpacity(0.5),
                ),
              ),
              child: Column(
                children: [
                  _buildTip(Icons.offline_bolt_outlined, 'Funciona sin conexión'),
                  const SizedBox(height: 10),
                  _buildTip(Icons.sync, 'Sincronización automática'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
