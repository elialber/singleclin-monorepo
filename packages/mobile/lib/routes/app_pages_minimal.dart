import 'package:get/get.dart';

// Only core working screens
import '../features/onboarding/screens/splash_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';

// Dashboard screens
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/dashboard/screens/home_screen.dart';

// Only working appointment screens
import '../features/appointments/screens/appointments_screen.dart';
import '../features/appointments/screens/appointment_details_screen.dart';

// Working bindings only
import '../features/onboarding/controllers/onboarding_binding.dart';
import '../features/auth/controllers/auth_binding.dart';
import '../features/dashboard/controllers/dashboard_binding.dart';
import '../features/appointments/bindings/appointments_binding.dart';

import 'app_routes.dart';

class AppPagesMinimal {
  static final routes = [
    // Auth Routes
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      binding: AuthBinding(),
    ),

    // Dashboard Routes
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: DashboardBinding(),
    ),

    // Appointment Routes
    GetPage(
      name: AppRoutes.appointments,
      page: () => const AppointmentsScreen(),
      binding: AppointmentsBinding(),
    ),
    GetPage(
      name: AppRoutes.appointmentDetails,
      page: () => const AppointmentDetailsScreen(),
      binding: AppointmentsBinding(),
    ),
  ];
}