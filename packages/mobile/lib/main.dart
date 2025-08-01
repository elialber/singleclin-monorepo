import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:mobile/core/bindings/initial_binding.dart';
import 'package:mobile/core/constants/app_constants.dart';
import 'package:mobile/core/routes/routes.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/data/services/app_lifecycle_observer.dart';
import 'package:mobile/data/services/cache_service.dart';
import 'package:mobile/data/services/token_refresh_service.dart';
import 'package:mobile/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize cache service first
  final cacheService = CacheService.instance;
  await cacheService.init();

  // Initialize token refresh service and lifecycle observer
  final tokenRefreshService = TokenRefreshService();
  final lifecycleObserver = AppLifecycleObserver(tokenRefreshService);

  // Initialize services
  await tokenRefreshService.initialize();
  lifecycleObserver.initialize();

  // Register services for dependency injection
  Get
    ..put<CacheService>(cacheService, permanent: true)
    ..put<TokenRefreshService>(tokenRefreshService, permanent: true)
    ..put<AppLifecycleObserver>(lifecycleObserver, permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use GetMaterialApp.router for go_router integration
    return GetMaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: const Locale('pt', 'BR'),
      fallbackLocale: const Locale('en', 'US'),
      // GoRouter configuration
      routerDelegate: AppRouter.router.routerDelegate,
      routeInformationParser: AppRouter.router.routeInformationParser,
      routeInformationProvider: AppRouter.router.routeInformationProvider,
      // GetX default transition (used with Get.to)
      defaultTransition: Transition.fadeIn,
      transitionDuration: AppConstants.normalAnimation,
    );
  }
}
