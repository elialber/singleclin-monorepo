import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/themes/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'data/services/api_client.dart';
import 'data/services/auth_service.dart';
import 'data/services/token_refresh_service.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'features/clinic_discovery/screens/clinic_discovery_screen.dart';
import 'features/clinic_discovery/screens/clinic_details_screen.dart';
import 'features/appointment_booking/screens/appointment_booking_screen.dart';
import 'temp_dashboard.dart';
import 'presentation/controllers/auth_controller.dart';
import 'shared/controllers/bottom_nav_controller.dart';
import 'core/utils/app_bindings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue without Firebase for now
  }
  
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
  await _initServices();
  
  runApp(const SingleClinApp());
}

Future<void> _initServices() async {
  try {
    print('🚀 Initializing services...');
    
    // Initialize storage service first
    await Get.putAsync(() => StorageService().init()).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        print('⚠️ Storage service initialization timeout');
        return StorageService(); // Return default instance
      },
    );
    
    // Initialize API client (singleton instance)
    Get.put(ApiClient.instance, permanent: true);
    
    // Initialize API service
    Get.put(ApiService(), permanent: true);
    
    // Initialize auth service
    Get.put(AuthService(), permanent: true);
    
    // Initialize token refresh service
    Get.put(TokenRefreshService(), permanent: true);
    
    // Initialize auth controller
    Get.put(AuthController(), permanent: true);

    // Initialize bottom navigation controller
    Get.put(BottomNavController(), permanent: true);
    
    print('✅ All services initialized successfully');
  } catch (e) {
    print('❌ Error initializing services: $e');
    // Continue with app launch even if some services fail
  }
}

class SingleClinApp extends StatelessWidget {
  const SingleClinApp({Key? key}) : super(key: key);

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
      
      // Navigation - Start directly on discovery (clinic list) to show menu
      initialRoute: '/discovery',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/home', page: () => const ClinicDiscoveryScreen()),
        GetPage(name: '/dashboard', page: () => const TempDashboardScreen()),
        GetPage(name: '/discovery', page: () => const ClinicDiscoveryWithNavScreen()),
        GetPage(name: '/credit-history', page: () => const TempTransactionsScreen()),
        GetPage(name: '/subscription-plans', page: () => const TempPlansScreen()),
        GetPage(name: '/profile', page: () => const TempProfileScreen()),
        GetPage(name: '/old-home', page: () => const HomeScreen()),
        GetPage(name: '/clinic-details', page: () => ClinicDetailsScreen(clinic: Get.arguments)),
        GetPage(name: '/appointment-booking', page: () => AppointmentBookingScreen(clinic: Get.arguments)),
      ],
      
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
      
      // Smart management
      smartManagement: SmartManagement.full,
      
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