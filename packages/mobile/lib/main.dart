import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:singleclin_mobile/core/constants/app_constants.dart';
import 'package:singleclin_mobile/core/services/api_service.dart';
import 'package:singleclin_mobile/core/services/session_manager.dart';
import 'package:singleclin_mobile/core/services/storage_service.dart';
import 'package:singleclin_mobile/core/themes/app_theme.dart';
import 'package:singleclin_mobile/data/services/api_client.dart';
import 'package:singleclin_mobile/data/services/app_lifecycle_observer.dart';
import 'package:singleclin_mobile/data/services/auth_service.dart';
import 'package:singleclin_mobile/data/services/firebase_initialization_service.dart';
import 'package:singleclin_mobile/data/services/session_revocation_service.dart';
import 'package:singleclin_mobile/data/services/token_refresh_service.dart';
import 'package:singleclin_mobile/features/appointment_booking/screens/appointment_booking_screen.dart';
import 'package:singleclin_mobile/features/clinic_discovery/screens/clinic_details_screen.dart';
import 'package:singleclin_mobile/features/clinic_discovery/screens/clinic_discovery_screen.dart';
import 'package:singleclin_mobile/firebase_options.dart';
import 'package:singleclin_mobile/presentation/controllers/auth_controller.dart';
import 'package:singleclin_mobile/presentation/screens/auth/login_screen.dart';
import 'package:singleclin_mobile/presentation/screens/auth/register_screen.dart';
import 'package:singleclin_mobile/presentation/screens/firebase_unavailable_screen.dart';
import 'package:singleclin_mobile/presentation/screens/home_screen.dart';
import 'package:singleclin_mobile/presentation/screens/profile_screen.dart';
import 'package:singleclin_mobile/presentation/screens/splash_screen.dart';
import 'package:singleclin_mobile/shared/controllers/bottom_nav_controller.dart';
import 'package:singleclin_mobile/temp_dashboard.dart';
import 'package:singleclin_mobile/routes/app_pages.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final firebaseInitializationService = Get.put(
    FirebaseInitializationService(),
    permanent: true,
  );
  await firebaseInitializationService.initialize();

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Initialize Hive
  await Hive.initFlutter();

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
  await _initServices(firebaseInitializationService);

  runApp(const SingleClinApp());
}

Future<void> _initServices(
  FirebaseInitializationService firebaseInitializationService,
) async {
  try {
    print('🚀 Initializing services...');

    // Initialize storage service first
    final storageService =
        await Get.putAsync<StorageService>(
          () => StorageService().init(),
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () =>
              throw TimeoutException('Storage service initialization timeout'),
        );
    storageService.ensureEncrypted();

    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }

    Future<void> initializeFirebaseDependentServices() async {
      final authService = Get.put(AuthService(), permanent: true);

      // Initialize SessionManager with required dependencies
      if (!Get.isRegistered<SessionManager>()) {
        Get.put(
          SessionManager(
            authService: authService,
            storageService: storageService,
          ),
          permanent: true,
        );
      }

      final tokenRefreshService = TokenRefreshService(
        authService: authService,
        storageService: storageService,
      );
      Get.put<TokenRefreshService>(tokenRefreshService, permanent: true);
      await tokenRefreshService.initialize();

      Get.put(ApiClient.instance, permanent: true);
      Get.put(ApiService(), permanent: true);

      final lifecycleObserver = AppLifecycleObserver(tokenRefreshService)
        ..initialize();
      Get.put<AppLifecycleObserver>(lifecycleObserver, permanent: true);

      final revocationService = SessionRevocationService(
        tokenRefreshService: tokenRefreshService,
        storageService: storageService,
        authService: authService,
      );
      await revocationService.initialize();
      Get.put<SessionRevocationService>(revocationService, permanent: true);
    }

    if (firebaseInitializationService.firebaseReady) {
      await initializeFirebaseDependentServices();
    } else {
      firebaseInitializationService.addOnReadyCallback(
        initializeFirebaseDependentServices,
      );
      print(
        '⚠️ Firebase not ready. Deferred auth-dependent service initialization.',
      );
    }

    // Initialize bottom navigation controller
    if (!Get.isRegistered<BottomNavController>()) {
      Get.put(BottomNavController(), permanent: true);
    }

    print('✅ All services initialized successfully');
  } catch (e) {
    print('❌ Error initializing services: $e');
    // Continue with app launch even if some services fail
  }
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

      // Navigation - Start with splash to check authentication
      initialRoute: '/splash',
      getPages: AppPages.routes,
      // Legacy routes for backward compatibility
      unknownRoute: GetPage(
        name: '/notfound',
        page: () => const SplashScreen(),
      ),

      // Global configuration
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),

      // Error handling
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Force text scale to 1.0
          ),
          child: child!,
        );
      },

      // Enable log in debug mode
      enableLog: false,
    );
  }
}
