import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart' show SyncStatus;
import '../../core/theme/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/powersync_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success =
        await ref.read(authProvider.notifier).login(email, password);

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/client-history');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final lastSync = ref.watch(lastSyncTimeProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Gradient Background
          _buildBackground(size),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: size.height * 0.08),

                          // Premium Logo
                          _buildLogo(),

                          const SizedBox(height: 48),

                          // Glass Card with Form
                          _buildFormCard(authState),

                          const SizedBox(height: 24),

                          // Sync Status
                          _buildSyncStatus(syncStatus, lastSync),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return Stack(
      children: [
        // Base dark background
        Container(
          width: double.infinity,
          height: double.infinity,
          color: AppColors.darkBackground,
        ),

        // Top gradient accent
        Positioned(
          top: -size.height * 0.3,
          left: -size.width * 0.5,
          child: Container(
            width: size.width * 1.5,
            height: size.height * 0.6,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom right accent
        Positioned(
          bottom: -size.height * 0.2,
          right: -size.width * 0.3,
          child: Container(
            width: size.width * 0.8,
            height: size.height * 0.4,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Subtle grid pattern overlay
        Opacity(
          opacity: 0.02,
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="60" height="60"><path d="M0 0h60v60H0z" fill="none" stroke="white" stroke-width="0.5"/></svg>',
                ),
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Animated Logo Container
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.glowPrimary,
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 24),

        // Brand Name with gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.textPrimaryDark, AppColors.textSecondaryDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            'SoluFácil',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
          ),
        ),

        const SizedBox(height: 8),

        // Tagline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceElevated,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppColors.darkBorder.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Gestión Financiera Inteligente',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondaryDark,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(AuthState authState) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceElevated.withOpacity(0.8),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Iniciar Sesión',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimaryDark,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa tus credenciales para continuar',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
              ),

              const SizedBox(height: 32),

              // Email field
              _buildInputLabel('Correo electrónico'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                style: const TextStyle(color: AppColors.textPrimaryDark),
                decoration: InputDecoration(
                  hintText: 'tu@email.com',
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.textSecondaryDark,
                      size: 22,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu correo electrónico';
                  }
                  if (!value.contains('@')) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Password field
              _buildInputLabel('Contraseña'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleLogin(),
                style: const TextStyle(color: AppColors.textPrimaryDark),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.textSecondaryDark,
                      size: 22,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondaryDark,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contraseña';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Error message
              if (authState.error != null) ...[
                _buildErrorMessage(authState.error!),
                const SizedBox(height: 16),
              ],

              // Login button
              _buildLoginButton(authState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondaryDark,
          ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.errorLight,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(AuthState authState) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: authState.isLoading ? null : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: authState.isLoading ? null : AppTheme.glowPrimary,
      ),
      child: ElevatedButton(
        onPressed: authState.isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
        child: authState.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Iniciar Sesión',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSyncStatus(
    AsyncValue<SyncStatus> syncStatus,
    DateTime? lastSync,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceElevated.withOpacity(0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppColors.darkBorder.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              // Status Icon
              syncStatus.when(
                data: (status) {
                  if (status.connected) {
                    return _buildStatusIcon(
                      Icons.cloud_done_rounded,
                      AppColors.success,
                    );
                  } else if (status.connecting) {
                    return _buildSyncingIndicator();
                  } else {
                    return _buildStatusIcon(
                      Icons.cloud_off_rounded,
                      AppColors.textMutedDark,
                    );
                  }
                },
                loading: () => _buildSyncingIndicator(),
                error: (_, __) => _buildStatusIcon(
                  Icons.cloud_off_rounded,
                  AppColors.textMutedDark,
                ),
              ),

              const SizedBox(width: 16),

              // Status Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Sincronización',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.textPrimaryDark,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        syncStatus.when(
                          data: (status) => _buildStatusBadge(status),
                          loading: () => _buildStatusBadge(
                              const SyncStatus(connecting: true)),
                          error: (_, __) =>
                              _buildStatusBadge(const SyncStatus()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (lastSync != null)
                      Text(
                        'Última: ${Formatters.relativeTime(lastSync)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMutedDark,
                            ),
                      )
                    else
                      Text(
                        'Sin sincronizar aún',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMutedDark,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 22,
      ),
    );
  }

  Widget _buildSyncingIndicator() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SyncStatus status) {
    Color color;
    String text;

    if (status.connected) {
      color = AppColors.success;
      text = 'Conectado';
    } else if (status.connecting) {
      color = AppColors.primary;
      text = 'Conectando...';
    } else {
      color = AppColors.textMutedDark;
      text = 'Offline';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
