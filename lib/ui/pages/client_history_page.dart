import 'dart:ui';
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
      duration: const Duration(milliseconds: 600),
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

    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(size),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(authState, isSyncing),

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
                      backgroundColor: AppColors.darkSurfaceElevated,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          // Search Section
                          SliverToBoxAdapter(
                            child: _buildSearchSection(),
                          ),

                          // Client Profile
                          if (selectedClientState.selectedClient != null) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: ClientProfileCard(
                                  client: selectedClientState.selectedClient!,
                                  history: selectedClientState.history,
                                  isLoading: selectedClientState.isLoading,
                                  onClear: () {
                                    ref.read(selectedClientProvider.notifier).clear();
                                  },
                                ),
                              ),
                            ),
                          ],

                          // Loans Sections
                          if (selectedClientState.history != null) ...[
                            // Loans as Client
                            if (selectedClientState.history!.loansAsClient.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: _buildSectionHeader(
                                  icon: Icons.account_circle_outlined,
                                  title: 'Préstamos como Cliente',
                                  count: selectedClientState.history!.loansAsClient.length,
                                  color: AppColors.primary,
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: LoansList(
                                  loans: selectedClientState.history!.loansAsClient,
                                  isCollateral: false,
                                ),
                              ),
                            ],

                            // Loans as Collateral
                            if (selectedClientState.history!.loansAsCollateral.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: _buildSectionHeader(
                                  icon: Icons.verified_user_outlined,
                                  title: 'Préstamos como Aval',
                                  count: selectedClientState.history!.loansAsCollateral.length,
                                  color: AppColors.accent,
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: LoansList(
                                  loans: selectedClientState.history!.loansAsCollateral,
                                  isCollateral: true,
                                ),
                              ),
                            ],

                            // No loans empty state
                            if (selectedClientState.history!.loansAsClient.isEmpty &&
                                selectedClientState.history!.loansAsCollateral.isEmpty)
                              SliverToBoxAdapter(
                                child: _buildEmptyLoansState(),
                              ),
                          ],

                          // No client selected empty state
                          if (selectedClientState.selectedClient == null)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildNoClientState(),
                            ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 32),
                          ),
                        ],
                      ),
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
        color: AppColors.darkBackground,
      ),
      child: Stack(
        children: [
          // Subtle gradient accent
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

  Widget _buildAppBar(AuthState authState, bool isSyncing) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.darkSurface.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: AppColors.darkBorder.withOpacity(0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              // Menu / Logout Button
              _buildIconButton(
                icon: Icons.logout_rounded,
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
              ),

              const SizedBox(width: 8),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSyncing ? AppColors.warning : AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSyncing ? 'Sincronizando...' : 'Conectado',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondaryDark,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Sync Button
              _buildIconButton(
                icon: Icons.sync_rounded,
                isLoading: isSyncing,
                onPressed: isSyncing ? null : () => triggerSync(ref),
              ),

              const SizedBox(width: 4),

              // User Menu
              _buildUserMenu(authState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.darkBorder.withOpacity(0.5),
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
                    color: AppColors.textSecondaryDark,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserMenu(AuthState authState) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColors.darkSurfaceElevated,
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          (authState.user?.fullName ?? 'U').substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      onSelected: (value) async {
        if (value == 'logout') {
          await ref.read(authProvider.notifier).logout();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authState.user?.fullName ?? 'Usuario',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimaryDark,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                authState.user?.email ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
              const SizedBox(width: 12),
              Text(
                'Cerrar sesión',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buscar Cliente',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ingresa el nombre o código del cliente',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
          ),
          const SizedBox(height: 16),
          ClientSearchBar(
            onClientSelected: (client) {
              ref.read(selectedClientProvider.notifier).selectClient(client);
              ref.read(clientSearchProvider.notifier).clear();
            },
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
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
                    color: AppColors.textPrimaryDark,
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
              color: AppColors.darkSurfaceElevated,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 48,
              color: AppColors.textMutedDark.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin historial de préstamos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este cliente no tiene préstamos registrados',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMutedDark,
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
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon Container
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceElevated,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.darkBorder.withOpacity(0.3),
                ),
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 64,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Selecciona un Cliente',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Usa la barra de búsqueda para encontrar\nun cliente y ver su historial completo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Quick Tips
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceElevated.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.darkBorder.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  _buildTip(Icons.search, 'Busca por nombre o código'),
                  const SizedBox(height: 12),
                  _buildTip(Icons.offline_bolt_outlined, 'Funciona sin conexión'),
                  const SizedBox(height: 12),
                  _buildTip(Icons.sync, 'Datos sincronizados automáticamente'),
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
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryDark,
              ),
        ),
      ],
    );
  }
}
