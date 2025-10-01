import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'lib/core/constants/app_constants.dart';
import 'lib/core/theme/app_theme.dart';
import 'lib/core/services/storage_service.dart';
import 'lib/core/services/api_service.dart';
import 'lib/core/services/auth_service.dart';
import 'lib/features/onboarding/screens/enhanced_splash_screen.dart';
import 'lib/features/auth/screens/login_screen.dart';
import 'lib/features/dashboard/screens/home_screen.dart';
import 'lib/features/auth/controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  await _initServices();

  runApp(const SingleClinApp());
}

Future<void> _initServices() async {
  // Initialize storage service first
  await Get.putAsync(() => StorageService().init());

  // Initialize other services
  Get.put(ApiService(), permanent: true);
  Get.put(AuthService(), permanent: true);

  // Initialize auth controller
  Get.put(AuthController(), permanent: true);
}

class SingleClinApp extends StatelessWidget {
  const SingleClinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // Localization
      locale: const Locale('pt', 'BR'),
      fallbackLocale: const Locale('pt', 'BR'),

      // Routes
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const EnhancedSplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
      ],

      // Global configuration
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),

      // Error handling
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },

      // Enable log in debug mode
      enableLog: false,
    );
  }
}

extension StorageServiceInitialization on StorageService {
  Future<StorageService> init() async {
    await onInit();
    return this;
  }
}
