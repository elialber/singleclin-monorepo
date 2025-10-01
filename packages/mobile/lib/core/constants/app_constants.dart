/// Application constants
class AppConstants {
  AppConstants._();

  // API Configuration
  static String get baseUrl => _getBaseUrl();
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration timeoutDuration = Duration(seconds: 30);

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_preference';
  static const String languageKey = 'language_preference';

  // App Information
  static const String appName = 'SingleClin';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Duration
  static const Duration defaultCacheDuration = Duration(hours: 1);
  static const Duration userCacheDuration = Duration(days: 7);

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int phoneNumberLength = 11; // Brazilian phone format

  // QR Code
  static const Duration qrCodeExpiration = Duration(minutes: 5);
  static const int qrCodeSize = 280;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const double defaultElevation = 4.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Regex Patterns
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp phoneRegex = RegExp(
    r'^\(?[1-9]{2}\)?\s?9?[0-9]{4}-?[0-9]{4}$',
  );

  static final RegExp cpfRegex = RegExp(r'^\d{3}\.\d{3}\.\d{3}-\d{2}$');

  static final RegExp cnpjRegex = RegExp(r'^\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}$');

  // Error Messages
  static const String genericError = 'Ocorreu um erro inesperado';
  static const String networkError = 'Erro de conexão';
  static const String timeoutError = 'Tempo esgotado';
  static const String unauthorizedError = 'Não autorizado';

  // Additional Keys
  static const String creditsKey = 'user_credits';
  static const String onboardingKey = 'onboarding_completed';

  // Default location (São Paulo)
  static const double defaultLatitude = -23.5505;
  static const double defaultLongitude = -46.6333;

  /// Get base URL based on environment
  static String _getBaseUrl() {
    // Temporarily use production API for testing authentication fixes
    // TODO: Switch back to localhost when .NET 9.0 is available
    // if (kDebugMode) {
    //   return 'http://localhost:5010/api';
    // }
    return 'https://api.singleclin.com.br/api';
  }
}
