import 'package:flutter/material.dart';

/// App color palette for KashAndaz
/// Fintech-focused colors for trust and clarity
class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF6C63FF); // Modern purple
  static const Color primaryDark = Color(0xFF5548E0);
  static const Color primaryLight = Color(0xFF8B84FF);

  // Accent Colors
  static const Color accent = Color(0xFF00D9B1); // Teal green for CTA
  static const Color accentDark = Color(0xFF00B894);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1D1F);
  static const Color textSecondary = Color(0xFF6F767E);
  static const Color textTertiary = Color(0xFF9A9FA5);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors - Transaction States
  static const Color success = Color(0xFF12B76A); // Confirmed
  static const Color successLight = Color(0xFFD1FADF);
  
  static const Color warning = Color(0xFFF79009); // Pending
  static const Color warningLight = Color(0xFFFEF0C7);
  
  static const Color error = Color(0xFFF04438); // Cancelled
  static const Color errorLight = Color(0xFFFEE4E2);
  
  static const Color info = Color(0xFF0BA5EC); // Paid
  static const Color infoLight = Color(0xFFD1E9FF);

  // Functional Colors
  static const Color divider = Color(0xFFEAECF0);
  static const Color border = Color(0xFFD0D5DD);
  static const Color disabled = Color(0xFFE4E7EC);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);

  // Shimmer Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
