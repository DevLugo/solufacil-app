import 'package:flutter/material.dart';

/// SoluFácil Design System
/// Based on design-example/tailwind.config.js
/// Light theme as base, with dark variant
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // BRAND COLORS - From design-example
  // ═══════════════════════════════════════════════════════════════════════════

  // Primary - Vibrant Orange
  static const Color primary = Color(0xFFF15A29);
  static const Color primaryLight = Color(0xFFFF8A5B);
  static const Color primaryDark = Color(0xFFC94820);
  static const Color primaryMuted = Color(0xFFF15A29);

  // Secondary - Deep Navy
  static const Color secondary = Color(0xFF1B1B3A);
  static const Color secondaryLight = Color(0xFF2D2D4A);
  static const Color secondaryDark = Color(0xFF121228);

  // Premium gradient colors for onboarding
  static const Color gradientOrange = Color(0xFFF15A29);
  static const Color gradientBlue = Color(0xFF2563EB);
  static const Color gradientGreen = Color(0xFF059669);
  static const Color gradientPurple = Color(0xFF7C3AED);

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME (BASE) - From design-example
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color surface = Color(0xFFF9FAFB);
  static const Color background = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Text colors for light theme
  static const Color textPrimary = Color(0xFF1B1B3A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME VARIANT
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color darkBackground = Color(0xFF0F0F23);
  static const Color darkSurface = Color(0xFF1B1B3A);
  static const Color darkSurfaceElevated = Color(0xFF2D2D4A);
  static const Color darkSurfaceHighlight = Color(0xFF3D3D5C);
  static const Color darkBorder = Color(0xFF3D3D5C);
  static const Color darkDivider = Color(0xFF2D2D4A);

  // Text colors for dark theme
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textMutedDark = Color(0xFF6B7280);
  static const Color textDisabledDark = Color(0xFF4B5563);

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY ALIASES (for backward compatibility)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color lightBackground = surface;
  static const Color lightSurface = background;
  static const Color lightSurfaceElevated = background;
  static const Color lightBorder = border;
  static const Color lightDivider = divider;

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS - Status & Feedback
  // ═══════════════════════════════════════════════════════════════════════════

  // Success - Emerald
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);
  static const Color successSurface = Color(0xFF0D3D2E);
  static const Color successSurfaceLight = Color(0xFFD1FAE5);

  // Warning - Amber
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFFFCD34D);
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFF3D3214);
  static const Color warningSurfaceLight = Color(0xFFFEF3C7);

  // Error - Rose
  static const Color error = Color(0xFFF43F5E);
  static const Color errorLight = Color(0xFFFB7185);
  static const Color errorDark = Color(0xFFE11D48);
  static const Color errorSurface = Color(0xFF3D1420);
  static const Color errorSurfaceLight = Color(0xFFFFE4E6);

  // Info - Blue
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);
  static const Color infoSurface = Color(0xFF142544);
  static const Color infoSurfaceLight = Color(0xFFDBEAFE);

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT COLORS - Additional
  // ═══════════════════════════════════════════════════════════════════════════

  // Light theme text (aliases)
  static const Color textPrimaryLight = textPrimary;
  static const Color textSecondaryLight = textSecondary;
  static const Color textMutedLight = textMuted;
  static const Color textDisabledLight = textDisabled;

  // On primary (always white for contrast)
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // Surface variant
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Accent - For special highlights
  static const Color accent = primary;
  static const Color accentLight = primaryLight;
  static const Color accentDark = primaryDark;

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAN STATUS COLORS - Premium indicators
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color loanActive = success;
  static const Color loanActiveSurface = successSurface;
  static const Color loanFinished = Color(0xFF64748B);
  static const Color loanFinishedSurface = Color(0xFF1E293B);
  static const Color loanRenewed = info;
  static const Color loanRenewedSurface = infoSurface;
  static const Color loanCancelled = error;
  static const Color loanCancelledSurface = errorSurface;

  // ═══════════════════════════════════════════════════════════════════════════
  // PAYMENT STATUS COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color paymentFull = success;
  static const Color paymentPartial = warning;
  static const Color paymentMissed = error;
  static const Color paymentCovered = info;

  // ═══════════════════════════════════════════════════════════════════════════
  // GRADIENTS - From design-example onboarding
  // ═══════════════════════════════════════════════════════════════════════════

  // Onboarding gradients (from Onboarding.tsx)
  static const LinearGradient onboardingOrange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xE6F97316), Color(0xE6EA580C)], // orange-500/90 to orange-600/90
  );

  static const LinearGradient onboardingBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xE62563EB), Color(0xE61D4ED8)], // blue-600/90 to blue-700/90
  );

  static const LinearGradient onboardingGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xE6059669), Color(0xE6047857)], // green-600/90 to green-700/90
  );

  static const LinearGradient onboardingPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xE69333EA), Color(0xE67C3AED)], // purple-600/90 to purple-700/90
  );

  static const LinearGradient onboardingNavy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xE61B1B3A), Color(0xE62D2D4A)], // secondary/90 to secondary-light/90
  );

  // Dashboard welcome card gradient
  static const LinearGradient welcomeCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );

  // Primary gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  // Success gradient
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, successLight],
  );

  // Dark theme gradient
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkSurfaceElevated, darkBackground],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // GLASS MORPHISM - Premium card effects
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassHighlight = Color(0x0DFFFFFF);

  // ═══════════════════════════════════════════════════════════════════════════
  // CHART COLORS - Data visualization
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<Color> chartColors = [
    Color(0xFFFF6B35),
    Color(0xFF00D4AA),
    Color(0xFF3B82F6),
    Color(0xFFFBBF24),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
  ];
}
