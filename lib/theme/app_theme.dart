import 'package:flutter/material.dart';

/// KashAndaz App Theme - Flipkart Style Design System
/// SINGLE SOURCE OF TRUTH for all colors, spacing, shadows
class AppTheme {
  // ═══════════════════════════════════════════════════════════════════════════
  // BRAND COLORS (Flipkart Style)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// PRIMARY: Flipkart Blue - Trust, navigation, AppBar, active states
  static const Color primaryBlue = Color(0xFF2874F0);
  
  /// SECONDARY: Cashback Orange - ONLY for cashback amounts, CTAs, offer badges
  static const Color cashbackOrange = Color(0xFFFF9F00);
  
  /// Light orange for backgrounds and subtle highlights
  static const Color primaryOrangeLight = Color(0xFFFFF1E6);
  
  /// LEGACY: Keep for backward compatibility (use primaryBlue/cashbackOrange instead)
  static const Color primaryOrange = Color(0xFFFF9F00);
  static const Color trustBlue = Color(0xFF0A66C2);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // BACKGROUNDS (Flipkart Style)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Screen background: Light grey (Flipkart style)
  static const Color scaffoldBg = Color(0xFFF1F3F6);
  
  /// Card backgrounds: Pure white
  static const Color cardWhite = Color(0xFFFFFFFF);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Primary text: Dark grey (not pure black)
  static const Color textPrimary = Color(0xFF212121);
  
  /// Secondary text: Medium grey
  static const Color textSecondary = Color(0xFF757575);
  
  /// Light/muted text
  static const Color textLight = Color(0xFF9E9E9E);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS COLORS (Muted, not bright)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Success: Muted green (not bright)
  static const Color successGreen = Color(0xFF388E3C);
  
  /// Pending: Muted yellow
  static const Color warningAmber = Color(0xFBFBC02D);
  
  /// Error: Muted red (not bright)
  static const Color errorRed = Color(0xFFD32F2F);
  
  // Border & Dividers
  static const Color borderLight = Color(0xFFE5E7EB);
  
  // Border Radius (16 default, 20 large)
  static const double defaultRadius = 16.0;
  static const double largeRadius = 20.0;
  static const double smallRadius = 12.0;
  static const double pillRadius = 100.0;
  
  // Spacing System
  static const double spacingXs = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXl = 32.0;
  static const double screenPadding = 16.0;
  
  // Backward compatibility aliases
  static const Color background = scaffoldBg;
  static const Color backgroundGrey = scaffoldBg;
  static const Color borderGrey = borderLight;
  static const Color textTertiary = textLight;
  static const Color chipBackground = primaryOrangeLight;
  static const double radiusMedium = defaultRadius;
  static const double radiusLarge = largeRadius;
  static const double radiusSmall = smallRadius;
  static const double radiusPill = pillRadius;
  
  // Shadows (soft, opacity < 0.08 for cards)
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get heroShadow => [
    BoxShadow(
      color: primaryOrange.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Theme Data
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryOrange,
      primary: primaryOrange,
      secondary: trustBlue,
      surface: cardWhite,
    ),
    scaffoldBackgroundColor: scaffoldBg,
    fontFamily: 'SF Pro Display',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
  );
}
