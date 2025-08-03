import 'package:flutter/material.dart';

/// Application color palette for SingleClin - Healthcare Management System
/// Implementing the official SingleClin brand color palette
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // === SINGLECLIN BRAND COLORS ===
  
  // Primary Colors - SingleClin Brand
  static const Color singleclinPrimary = Color(0xFF005156); // Azul-Esverdeado (Pantone 7476 C)
  static const Color singleclinBlack = Color(0xFF000000); // Preto
  static const Color singleclinWhite = Color(0xFFFFFFFF); // Branco
  static const Color singleclinLightGrey = Color(0xFFE6E6E6); // Cinza Claro

  // Primary Colors for Light/Dark Themes
  static const Color primaryLight = singleclinPrimary; // #005156
  static const Color primaryDark = Color(0xFF006B71); // Slightly lighter for dark mode visibility

  // Secondary Colors
  static const Color secondaryLight = singleclinLightGrey; // #E6E6E6
  static const Color secondaryDark = Color(0xFF424242); // Darker grey for contrast in dark mode

  // Background Colors
  static const Color backgroundLight = singleclinWhite; // #FFFFFF
  static const Color backgroundDark = singleclinBlack; // #000000

  // Surface Colors (cards, dialogs, etc.)
  static const Color surfaceLight = singleclinWhite; // #FFFFFF
  static const Color surfaceDark = Color(0xFF1A1A1A); // Very dark grey, not pure black

  // Text Colors
  static const Color textPrimaryLight = singleclinBlack; // #000000
  static const Color textPrimaryDark = singleclinWhite; // #FFFFFF

  static const Color textSecondaryLight = Color(0xFF666666); // Dark grey
  static const Color textSecondaryDark = singleclinLightGrey; // #E6E6E6

  // Status Colors - maintaining accessibility
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color error = Color(0xFFF44336); // Red
  static const Color info = singleclinPrimary; // Using brand color for info

  // Special Colors
  static const Color qrCodeColor = singleclinPrimary; // Using brand color
  static const Color clinicColor = singleclinPrimary; // Consistent branding

  // Neutral Colors (updated to align with brand)
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = singleclinLightGrey; // #E6E6E6
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = singleclinBlack; // #000000

  // SingleClin Brand Gradients
  static const List<Color> singleclinPrimaryGradient = [
    singleclinPrimary, // #005156
    singleclinBlack,   // #000000
  ];

  static const List<Color> singleclinSecondaryGradient = [
    singleclinWhite,     // #FFFFFF
    singleclinLightGrey, // #E6E6E6
  ];

  // Gradient Colors (updated for brand consistency)
  static const List<Color> primaryGradientLight = singleclinPrimaryGradient;
  static const List<Color> primaryGradientDark = [
    Color(0xFF006B71), // Lighter version for dark mode
    Color(0xFF333333), // Dark grey instead of pure black
  ];

  static const List<Color> successGradient = [
    Color(0xFF4CAF50),
    Color(0xFF45A049),
  ];

  // Shadow Colors
  static const Color shadowLight = Color(0x1A005156); // 10% primary color
  static const Color shadowDark = Color(0x1AFFFFFF); // 10% white

  // Divider Colors
  static const Color dividerLight = singleclinLightGrey; // #E6E6E6
  static const Color dividerDark = Color(0xFF424242);

  // Icon Colors
  static const Color iconLight = Color(0xFF666666);
  static const Color iconDark = singleclinLightGrey;
  static const Color iconActiveLight = singleclinPrimary;
  static const Color iconActiveDark = Color(0xFF006B71);

  // Button Colors
  static const Color buttonDisabledLight = singleclinLightGrey; // #E6E6E6
  static const Color buttonDisabledDark = Color(0xFF424242);

  // Input Colors
  static const Color inputBorderLight = singleclinLightGrey; // #E6E6E6
  static const Color inputBorderDark = Color(0xFF424242);
  static const Color inputFillLight = Color(0xFFF9F9F9);
  static const Color inputFillDark = Color(0xFF2C2C2C);

  // Clinic-specific Colors (updated to brand colors)
  static const Color clinicPrimary = singleclinPrimary; // #005156
  static const Color clinicSecondary = singleclinBlack; // #000000
  static const Color clinicAccent = Color(0xFF006B71); // Lighter teal

  // Plan Colors (maintaining distinction while using brand-aligned colors)
  static const Color planBasic = Color(0xFF607D8B); // Blue Grey
  static const Color planPremium = Color(0xFFFFB300); // Amber
  static const Color planEnterprise = singleclinPrimary; // Using brand color

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
