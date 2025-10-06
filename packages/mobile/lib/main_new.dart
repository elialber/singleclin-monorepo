import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/constants/app_constants.dart';
import 'package:singleclin_mobile/core/themes/app_theme.dart';
import 'package:singleclin_mobile/core/utils/app_bindings.dart';
import 'package:singleclin_mobile/firebase_options.dart';
import 'package:singleclin_mobile/routes/app_pages.dart';
import 'package:singleclin_mobile/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  runApp(const SingleClinApp());
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

      // Navigation
      initialRoute: AppRoutes.dashboard,
      getPages: AppPages.routes,

      // Initialize bindings
      initialBinding: AppBindings(),

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
    );
  }
}
