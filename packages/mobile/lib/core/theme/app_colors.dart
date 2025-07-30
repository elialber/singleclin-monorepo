import 'package:flutter/material.dart';

/// Application color palette for light and dark themes
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Colors - Medical/Healthcare theme
  static const Color primaryLight = Color(0xFF4A90E2); // Professional blue
  static const Color primaryDark = Color(
    0xFF5BA0F2,
  ); // Slightly lighter for dark mode

  // Secondary Colors
  static const Color secondaryLight = Color(0xFF50C878); // Emerald green
  static const Color secondaryDark = Color(
    0xFF60D888,
  ); // Lighter green for dark mode

  // Background Colors
  static const Color backgroundLight = Color(0xFFFAFAFA); // Off-white
  static const Color backgroundDark = Color(0xFF121212); // Material dark

  // Surface Colors (cards, dialogs, etc.)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);

  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Status Colors (same for both themes)
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color error = Color(0xFFF44336); // Red
  static const Color info = Color(0xFF2196F3); // Blue

  // Special Colors
  static const Color qrCodeColor = Color(0xFF673AB7); // Deep purple
  static const Color clinicColor = Color(0xFF009688); // Teal

  // Neutral Colors
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Gradient Colors
  static const List<Color> primaryGradientLight = [
    Color(0xFF4A90E2),
    Color(0xFF357ABD),
  ];

  static const List<Color> primaryGradientDark = [
    Color(0xFF5BA0F2),
    Color(0xFF4690E2),
  ];

  static const List<Color> successGradient = [
    Color(0xFF4CAF50),
    Color(0xFF45A049),
  ];

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000); // 10% black
  static const Color shadowDark = Color(0x1AFFFFFF); // 10% white

  // Divider Colors
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);

  // Icon Colors
  static const Color iconLight = Color(0xFF757575);
  static const Color iconDark = Color(0xFFBDBDBD);
  static const Color iconActiveLight = primaryLight;
  static const Color iconActiveDark = primaryDark;

  // Button Colors
  static const Color buttonDisabledLight = Color(0xFFE0E0E0);
  static const Color buttonDisabledDark = Color(0xFF424242);

  // Input Colors
  static const Color inputBorderLight = Color(0xFFE0E0E0);
  static const Color inputBorderDark = Color(0xFF424242);
  static const Color inputFillLight = Color(0xFFF5F5F5);
  static const Color inputFillDark = Color(0xFF2C2C2C);

  // Clinic-specific Colors
  static const Color clinicPrimary = Color(0xFF00796B);
  static const Color clinicSecondary = Color(0xFF004D40);
  static const Color clinicAccent = Color(0xFF1DE9B6);

  // Plan Colors
  static const Color planBasic = Color(0xFF607D8B); // Blue Grey
  static const Color planPremium = Color(0xFFFFB300); // Amber
  static const Color planEnterprise = Color(0xFF7B1FA2); // Purple

  // Helper method to get colors based on theme
  static Color primary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? primaryLight
        : primaryDark;
  }

  static Color secondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? secondaryLight
        : secondaryDark;
  }

  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? backgroundLight
        : backgroundDark;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? surfaceLight
        : surfaceDark;
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? textPrimaryLight
        : textPrimaryDark;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? textSecondaryLight
        : textSecondaryDark;
  }

  static List<Color> primaryGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? primaryGradientLight
        : primaryGradientDark;
  }
}
