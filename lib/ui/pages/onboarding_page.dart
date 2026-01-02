import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';

/// Onboarding slide data
class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}

/// Onboarding slides from design-example/Onboarding.tsx
final _slides = [
  OnboardingSlide(
    title: 'Bienvenido a Solufacil',
    description:
        'La forma más rápida y sencilla de gestionar tus créditos en campo.',
    icon: LucideIcons.sparkles,
    gradient: AppColors.onboardingOrange,
  ),
  const OnboardingSlide(
    title: 'Créditos Rápidos',
    description:
        'Escanea la credencial de elector y registra clientes automáticamente en minutos.',
    icon: LucideIcons.zap,
    gradient: AppColors.onboardingBlue,
  ),
  const OnboardingSlide(
    title: 'Cobranza Semanal',
    description:
        'Organiza tu ruta y cobra eficientemente semana tras semana por localidad.',
    icon: LucideIcons.map,
    gradient: AppColors.onboardingGreen,
  ),
  const OnboardingSlide(
    title: 'Todo bajo control',
    description:
        'Consulta historial de pagos, clientes y el estado de tu cartera en tiempo real.',
    icon: LucideIcons.barChart3,
    gradient: AppColors.onboardingPurple,
  ),
  const OnboardingSlide(
    title: 'Seguro y confiable',
    description: 'Tus datos están protegidos con cifrado de nivel bancario.',
    icon: LucideIcons.shield,
    gradient: AppColors.onboardingNavy,
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentSlide = 0;

  bool get _isLastSlide => _currentSlide == _slides.length - 1;

  void _nextSlide() {
    if (_isLastSlide) {
      context.go(AppRoutes.login);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient (animated)
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: _slides[_currentSlide].gradient,
            ),
          ),

          // Decorative blur circles
          Positioned(
            top: size.height * 0.2,
            left: size.width * 0.1,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.2),
              ),
            ).animate().blur(
                  begin: const Offset(80, 80),
                  end: const Offset(100, 100),
                  duration: 2.seconds,
                ),
          ),
          Positioned(
            bottom: size.height * 0.3,
            right: size.width * 0.1,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.15),
              ),
            ).animate().blur(
                  begin: const Offset(60, 60),
                  end: const Offset(80, 80),
                  duration: 2.seconds,
                ),
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: TextButton(
              onPressed: _skip,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
              child: Text(
                'Saltar',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // PageView for slides
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentSlide = index;
                      });
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return _SlideContent(slide: slide, isActive: index == _currentSlide);
                    },
                  ),
                ),

                // Progress dots
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentSlide == index ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentSlide == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Navigation button (circular)
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: GestureDetector(
                    onTap: _nextSlide,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isLastSlide
                            ? LucideIcons.check
                            : LucideIcons.arrowRight,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    )
                        .animate(
                          onPlay: (controller) => controller.repeat(),
                        )
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.05, 1.05),
                          duration: 1.seconds,
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .scale(
                          begin: const Offset(1.05, 1.05),
                          end: const Offset(1, 1),
                          duration: 1.seconds,
                          curve: Curves.easeInOut,
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
}

class _SlideContent extends StatelessWidget {
  final OnboardingSlide slide;
  final bool isActive;

  const _SlideContent({
    required this.slide,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon in circular border
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              color: Colors.white.withOpacity(0.1),
            ),
            child: Icon(
              slide.icon,
              size: 40,
              color: Colors.white,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 500.ms,
              )
              .fade(duration: 500.ms),

          const SizedBox(height: 32),

          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .slideY(begin: 0.3, end: 0, duration: 500.ms)
              .fade(duration: 500.ms),

          const SizedBox(height: 16),

          // Description
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 100.ms)
              .fade(duration: 500.ms, delay: 100.ms),
        ],
      ),
    );
  }
}
