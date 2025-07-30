import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/presentation/controllers/base_controller.dart';

/// Controller for managing app theme
class ThemeController extends BaseController {
  // Storage key
  static const String _themeKey = 'theme_mode';
  
  // Observable theme mode
  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  ThemeMode get themeMode => _themeMode.value;
  
  // Check if dark mode is active
  bool get isDarkMode {
    if (_themeMode.value == ThemeMode.system) {
      // Check system theme
      return Get.isPlatformDarkMode;
    }
    return _themeMode.value == ThemeMode.dark;
  }
  
  // Check if using system theme
  bool get isSystemTheme => _themeMode.value == ThemeMode.system;
  
  @override
  void onInit() {
    super.onInit();
    _loadThemeFromStorage();
  }
  
  /// Load saved theme preference from storage
  Future<void> _loadThemeFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            _themeMode.value = ThemeMode.light;
            break;
          case 'dark':
            _themeMode.value = ThemeMode.dark;
            break;
          default:
            _themeMode.value = ThemeMode.system;
        }
        
        // Apply the loaded theme
        Get.changeThemeMode(_themeMode.value);
      }
    } catch (e) {
      // If loading fails, default to system theme
      _themeMode.value = ThemeMode.system;
    }
  }
  
  /// Save theme preference to storage
  Future<void> _saveThemeToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String themeString;
      switch (_themeMode.value) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        default:
          themeString = 'system';
      }
      
      await prefs.setString(_themeKey, themeString);
    } catch (e) {
      // Handle save error silently
    }
  }
  
  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode.value = mode;
    Get.changeThemeMode(mode);
    await _saveThemeToStorage();
    
    // Show confirmation
    String themeName;
    switch (mode) {
      case ThemeMode.light:
        themeName = 'Claro';
        break;
      case ThemeMode.dark:
        themeName = 'Escuro';
        break;
      default:
        themeName = 'Sistema';
    }
    
    showSuccessSnackbar('Tema alterado para: $themeName');
  }
  
  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (isDarkMode) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
  
  /// Set light theme
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }
  
  /// Set dark theme
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }
  
  /// Set system theme
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }
  
  /// Get theme icon based on current mode
  IconData getThemeIcon() {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      default:
        return Icons.brightness_auto;
    }
  }
  
  /// Get theme name for display
  String getThemeName() {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return 'Tema Claro';
      case ThemeMode.dark:
        return 'Tema Escuro';
      default:
        return 'Tema do Sistema';
    }
  }
  
  /// Get available theme options
  List<ThemeOption> getThemeOptions() {
    return [
      ThemeOption(
        mode: ThemeMode.light,
        title: 'Claro',
        subtitle: 'Tema claro com cores vibrantes',
        icon: Icons.light_mode,
        isSelected: _themeMode.value == ThemeMode.light,
      ),
      ThemeOption(
        mode: ThemeMode.dark,
        title: 'Escuro',
        subtitle: 'Tema escuro para reduzir cansaço visual',
        icon: Icons.dark_mode,
        isSelected: _themeMode.value == ThemeMode.dark,
      ),
      ThemeOption(
        mode: ThemeMode.system,
        title: 'Sistema',
        subtitle: 'Seguir configuração do dispositivo',
        icon: Icons.brightness_auto,
        isSelected: _themeMode.value == ThemeMode.system,
      ),
    ];
  }
}

/// Theme option model
class ThemeOption {
  final ThemeMode mode;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  
  ThemeOption({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
  });
}