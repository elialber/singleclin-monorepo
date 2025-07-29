/// Route names constants
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  // Main routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  
  // QR Code routes
  static const String qrScan = '/qr-scan';
  static const String qrGenerate = '/qr-generate';
  static const String qrValidation = '/qr-validation';
  
  // Transaction routes
  static const String transactionHistory = '/transactions';
  static const String transactionDetails = '/transactions/:id';
  
  // Clinic routes
  static const String clinicDashboard = '/clinic-dashboard';
  static const String clinicQrScan = '/clinic/qr-scan';
  static const String clinicTransactions = '/clinic/transactions';
  
  // Settings routes
  static const String settings = '/settings';
  static const String changePassword = '/settings/change-password';
  static const String themeSettings = '/settings/theme';
  static const String about = '/settings/about';
  
  // Error routes
  static const String notFound = '/404';
  static const String error = '/error';
  
  // Protected routes (require authentication)
  static const List<String> protectedRoutes = [
    home,
    profile,
    qrScan,
    qrGenerate,
    qrValidation,
    transactionHistory,
    transactionDetails,
    clinicDashboard,
    clinicQrScan,
    clinicTransactions,
    settings,
    changePassword,
  ];
  
  // Public routes (no authentication required)
  static const List<String> publicRoutes = [
    splash,
    login,
    register,
    forgotPassword,
    about,
    notFound,
    error,
  ];
  
  // Clinic-only routes
  static const List<String> clinicRoutes = [
    clinicDashboard,
    clinicQrScan,
    clinicTransactions,
  ];
  
  // Helper methods
  static bool isProtectedRoute(String route) {
    return protectedRoutes.any((r) => route.startsWith(r));
  }
  
  static bool isPublicRoute(String route) {
    return publicRoutes.any((r) => route.startsWith(r));
  }
  
  static bool isClinicRoute(String route) {
    return clinicRoutes.any((r) => route.startsWith(r));
  }
}