import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_app/core/bindings/initial_binding.dart';
import 'package:singleclin_app/core/constants/app_constants.dart';
import 'package:singleclin_app/core/routes/routes.dart';
import 'package:singleclin_app/core/theme/theme.dart';

void main() {
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
      themeMode: ThemeMode.system,
      locale: const Locale('pt', 'BR'),
      fallbackLocale: const Locale('en', 'US'),
      // GoRouter configuration
      routerConfig: AppRouter.router,
      // GetX default transition (used with Get.to)
      defaultTransition: Transition.fadeIn,
      transitionDuration: AppConstants.normalAnimation,
    );
  }
}
