import 'package:flutter/material.dart';

/// SingleClin Official Brand Colors
/// Based on web-admin theme specification
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ==========================================
  // SINGLECLIN OFFICIAL BRAND COLORS
  // ==========================================

  /// Primary Brand Color - Azul-Esverdeado (Pantone 7476 C)
  static const Color primary = Color(0xFF005156);

  /// Primary Light - Lighter version for hover states
  static const Color primaryLight = Color(0xFF006B71);

  /// Primary Dark - Darker version for pressed states
  static const Color primaryDark = Color(0xFF003A3D);

  /// Brand Black
  static const Color black = Color(0xFF000000);

  /// Brand White
  static const Color white = Color(0xFFFFFFFF);

  /// Light Grey for backgrounds and dividers
  static const Color lightGrey = Color(0xFFE6E6E6);

  /// Medium Grey for secondary text
  static const Color mediumGrey = Color(0xFF666666);

  /// Dark Grey for primary text
  static const Color darkGrey = Color(0xFF333333);

  // ==========================================
  // GRADIENT COLLECTIONS
  // ==========================================

  /// Primary gradient for buttons and highlights
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// Light gradient for cards and surfaces
  static const Gradient lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [white, Color(0xFFF8F9FA)],
  );

  /// Success gradient
  static const Gradient successGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
  );

  // ==========================================
  // SEMANTIC COLORS
  // ==========================================

  /// Success color for positive actions
  static const Color success = Color(0xFF2E7D32);

  /// Success light
  static const Color successLight = Color(0xFF4CAF50);

  /// Warning color for caution states
  static const Color warning = Color(0xFFED6C02);

  /// Warning light
  static const Color warningLight = Color(0xFFFF9800);

  /// Error color for negative actions
  static const Color error = Color(0xFFD32F2F);

  /// Error light
  static const Color errorLight = Color(0xFFEF5350);

  /// Info color using brand primary
  static const Color info = primary;

  /// Info light
  static const Color infoLight = primaryLight;

  // ==========================================
  // SG CREDITS SPECIFIC COLORS
  // ==========================================

  /// SG Credit primary color - Golden accent
  static const Color sgPrimary = Color(0xFFFFB000);

  /// SG Credit secondary
  static const Color sgSecondary = Color(0xFFFFC107);

  /// SG Credit gradient
  static const Gradient sgGradient = LinearGradient(
    colors: [Color(0xFFFFB000), Color(0xFFFFC107)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================
  // UI COMPONENT COLORS
  // ==========================================

  /// Surface color for cards and containers
  static const Color surface = white;

  /// Surface variant color
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  /// Background color for screens
  static const Color background = Color(0xFFFAFAFA);

  /// On surface color for text on surfaces
  static const Color onSurface = darkGrey;

  /// On surface variant color
  static const Color onSurfaceVariant = mediumGrey;

  /// On primary color for text on primary surfaces
  static const Color onPrimary = white;

  /// Divider color
  static const Color divider = lightGrey;

  /// Shadow color
  static const Color shadow = Color(0x1A000000);

  /// Disabled color
  static const Color disabled = Color(0xFFBDBDBD);

  /// Disabled text
  static const Color disabledText = Color(0xFF9E9E9E);

  // ==========================================
  // TEXT COLORS
  // ==========================================

  /// Primary text color
  static const Color textPrimary = black;

  /// Secondary text color
  static const Color textSecondary = mediumGrey;

  /// Hint text color
  static const Color textHint = Color(0xFF9E9E9E);

  /// Text on primary color
  static const Color textOnPrimary = white;

  // ==========================================
  // CATEGORY COLORS FOR SERVICES
  // ==========================================

  /// Aesthetic Facial category
  static const Color categoryAesthetic = Color(0xFFE91E63);

  /// Injectable Therapies category
  static const Color categoryInjectable = Color(0xFF9C27B0);

  /// Diagnostics category
  static const Color categoryDiagnostic = Color(0xFF2196F3);

  /// Performance & Health category
  static const Color categoryPerformance = Color(0xFF4CAF50);

  /// General category
  static const Color categoryGeneral = mediumGrey;

  // ==========================================
  // HELPER METHODS
  // ==========================================

  /// Get category color by name
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'estetica':
      case 'estética facial':
      case 'aesthetic':
        return categoryAesthetic;
      case 'injetavel':
      case 'terapias injetáveis':
      case 'injectable':
        return categoryInjectable;
      case 'diagnostico':
      case 'diagnósticos':
      case 'diagnostic':
        return categoryDiagnostic;
      case 'performance':
      case 'saude':
      case 'performance e saúde':
      case 'health':
        return categoryPerformance;
      default:
        return categoryGeneral;
    }
  }

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get lighter version of color
  static Color lighter(Color color, [double amount = 0.1]) {
    return Color.alphaBlend(white.withOpacity(amount), color);
  }

  /// Get darker version of color
  static Color darker(Color color, [double amount = 0.1]) {
    return Color.alphaBlend(black.withOpacity(amount), color);
  }
}
