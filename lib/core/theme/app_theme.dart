import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Premium Fintech Theme 2025
/// Dark-first design with glass morphism and modern aesthetics
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════

  static const double spacingXxs = 4;
  static const double spacingXs = 8;
  static const double spacingSm = 12;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════════════════

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 28;
  static const double radiusFull = 100;

  // ═══════════════════════════════════════════════════════════════════════════
  // SHADOWS - Premium depth effects
  // ═══════════════════════════════════════════════════════════════════════════

  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withOpacity(0.16),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glowPrimary => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get glowSuccess => [
        BoxShadow(
          color: AppColors.success.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME - Premium Default
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.accent,
        secondaryContainer: AppColors.accentDark,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        errorContainer: AppColors.errorSurface,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnAccent,
        onSurface: AppColors.textPrimaryDark,
        onError: AppColors.textOnPrimary,
        outline: AppColors.darkBorder,
      ),

      // Premium Typography
      textTheme: _buildTextTheme(isDark: true),

      // AppBar - Transparent with blur effect
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryDark,
          size: 24,
        ),
      ),

      // Cards - Glass morphism style
      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.darkSurfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: AppColors.darkBorder.withOpacity(0.5)),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button - Premium gradient style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.darkSurfaceHighlight,
          disabledForegroundColor: AppColors.textMutedDark,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration - Modern floating label
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: AppColors.darkBorder.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textMutedDark,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textSecondaryDark,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
        prefixIconColor: AppColors.textSecondaryDark,
        suffixIconColor: AppColors.textSecondaryDark,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),

      // Bottom Sheet - Premium glass effect
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.darkSurfaceHighlight,
        circularTrackColor: AppColors.darkSurfaceHighlight,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceHighlight,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDark,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: BorderSide.none,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textPrimaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: spacingMd),
        minLeadingWidth: 24,
        iconColor: AppColors.textSecondaryDark,
        textColor: AppColors.textPrimaryDark,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryDark,
        size: 24,
      ),

      // TabBar
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondaryDark,
        indicatorColor: AppColors.primary,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME - Clean alternative
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBackground,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.accent,
        secondaryContainer: AppColors.accentLight,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        errorContainer: AppColors.errorSurfaceLight,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnAccent,
        onSurface: AppColors.textPrimaryLight,
        onError: AppColors.textOnPrimary,
        outline: AppColors.lightBorder,
      ),

      textTheme: _buildTextTheme(isDark: false),

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.textPrimaryLight,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.5,
        ),
      ),

      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.lightBorder.withOpacity(0.5),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY
  // ═══════════════════════════════════════════════════════════════════════════

  static TextTheme _buildTextTheme({required bool isDark}) {
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return TextTheme(
      // Display - Hero text
      displayLarge: GoogleFonts.inter(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -1.5,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -1,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
        height: 1.2,
      ),

      // Headlines - Section titles
      headlineLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),

      // Titles - Card headers
      titleLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
        letterSpacing: 0.2,
      ),

      // Body - Content text
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        height: 1.4,
      ),

      // Labels - Buttons, chips, tags
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.3,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: mutedColor,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXTENSION - Easy access to theme properties
// ═══════════════════════════════════════════════════════════════════════════

extension ThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
