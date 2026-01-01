import 'package:flutter/material.dart';

/// Premium Fintech Color System 2025
/// SoluFácil - Modern, bold, trustworthy
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // BRAND COLORS - Premium Orange with depth
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8F66);
  static const Color primaryDark = Color(0xFFE55A2B);
  static const Color primaryMuted = Color(0xFFFF6B35);

  // Premium gradient colors
  static const Color gradientStart = Color(0xFFFF6B35);
  static const Color gradientMiddle = Color(0xFFFF8547);
  static const Color gradientEnd = Color(0xFFFFAB76);

  // Accent - Modern Teal for contrast
  static const Color accent = Color(0xFF00D4AA);
  static const Color accentLight = Color(0xFF5FFFDA);
  static const Color accentDark = Color(0xFF00B894);

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME - Premium Dark Mode
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color darkBackground = Color(0xFF0A0E17);
  static const Color darkSurface = Color(0xFF141B2D);
  static const Color darkSurfaceElevated = Color(0xFF1C2438);
  static const Color darkSurfaceHighlight = Color(0xFF252D44);
  static const Color darkBorder = Color(0xFF2A3347);
  static const Color darkDivider = Color(0xFF1E2636);

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME - Clean & Professional
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color lightBackground = Color(0xFFF7F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8ECF4);
  static const Color lightDivider = Color(0xFFF0F3F8);

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
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  // Dark theme text
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
  static const Color textDisabledDark = Color(0xFF475569);

  // Light theme text
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);
  static const Color textDisabledLight = Color(0xFFCBD5E1);

  // On primary (always white for contrast)
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF0A0E17);

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY ALIASES (for backward compatibility)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color secondary = darkSurface;
  static const Color secondaryLight = darkSurfaceElevated;
  static const Color secondaryDark = darkBackground;
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = lightBorder;
  static const Color divider = lightDivider;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textMuted = textMutedLight;

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
  // GRADIENTS - Premium visual effects
  // ═══════════════════════════════════════════════════════════════════════════

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientMiddle, gradientEnd],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentLight],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkSurfaceElevated, darkBackground],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, successLight],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1C2438),
      Color(0xFF141B2D),
    ],
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
