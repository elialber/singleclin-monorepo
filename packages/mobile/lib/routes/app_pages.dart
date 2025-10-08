import 'package:get/get.dart';
// TEMP: Comentado para permitir compilação
// import 'package:singleclin_mobile/features/appointment_booking/screens/appointment_booking_screen.dart';
// Module 3 - Bindings
// import 'package:singleclin_mobile/features/appointments/bindings/appointments_binding.dart';
// import 'package:singleclin_mobile/features/appointments/screens/appointment_details_screen.dart';
// Module 3 - Appointments screens
// import 'package:singleclin_mobile/features/appointments/screens/appointments_screen.dart';
// import 'package:singleclin_mobile/features/appointments/screens/cancellation_policy_screen.dart';
import 'package:singleclin_mobile/features/auth/controllers/auth_binding.dart';
import 'package:singleclin_mobile/features/auth/screens/forgot_password_screen.dart';
import 'package:singleclin_mobile/features/auth/screens/login_screen.dart';
import 'package:singleclin_mobile/features/auth/screens/register_screen.dart';
// Clinic services
import 'package:singleclin_mobile/features/clinic_services/screens/clinic_services_screen.dart';
import 'package:singleclin_mobile/features/credits/bindings/credits_binding.dart';
// Credits screens
import 'package:singleclin_mobile/features/credits/screens/credit_history_screen.dart';
import 'package:singleclin_mobile/features/credits/screens/subscription_plans_screen.dart';
// Home screen
import 'package:singleclin_mobile/features/home/screens/home_screen.dart';
// TEMP: Comentado - Dashboard tem erros
// import 'package:singleclin_mobile/features/dashboard/controllers/dashboard_binding.dart';
// Dashboard screens
// import 'package:singleclin_mobile/features/dashboard/screens/dashboard_screen.dart';
// import 'package:singleclin_mobile/features/dashboard/screens/home_screen.dart';
// TEMP: Comentado - Discovery tem erros
// import 'package:singleclin_mobile/features/discovery/controllers/discovery_binding.dart';
// import 'package:singleclin_mobile/features/discovery/screens/booking_screen.dart';
// import 'package:singleclin_mobile/features/discovery/screens/clinic_details_screen.dart';
// import 'package:singleclin_mobile/features/discovery/screens/discovery_screen.dart';
// import 'package:singleclin_mobile/features/discovery/screens/filters_screen.dart';
// import 'package:singleclin_mobile/features/discovery/screens/map_view_screen.dart';
// TEMP: Comentado - Engagement tem muitos erros
// import 'package:singleclin_mobile/features/engagement/bindings/engagement_binding.dart';
// import 'package:singleclin_mobile/features/engagement/screens/community_screen.dart';
// import 'package:singleclin_mobile/features/engagement/screens/faq_screen.dart';
// import 'package:singleclin_mobile/features/engagement/screens/feedback_screen.dart';
// Module 5 - Engagement screens and bindings
// import 'package:singleclin_mobile/features/engagement/screens/reviews_screen.dart';
// import 'package:singleclin_mobile/features/engagement/screens/support_screen.dart';
// import 'package:singleclin_mobile/features/engagement/screens/trust_center_screen.dart';
// import 'package:singleclin_mobile/features/engagement/screens/write_review_screen.dart';
// Bindings
import 'package:singleclin_mobile/features/onboarding/controllers/onboarding_binding.dart';
import 'package:singleclin_mobile/features/onboarding/screens/onboarding_screen.dart';
// Onboarding and Auth screens
import 'package:singleclin_mobile/features/onboarding/screens/splash_screen.dart';
// TEMP: Comentado - Profile tem erros
// import 'package:singleclin_mobile/features/profile/bindings/profile_binding.dart';
// import 'package:singleclin_mobile/features/profile/screens/documents_screen.dart';
// import 'package:singleclin_mobile/features/profile/screens/health_history_screen.dart';
// Module 3 - Profile screens
// import 'package:singleclin_mobile/features/profile/screens/profile_screen.dart';
// import 'package:singleclin_mobile/presentation/screens/clinic/scan_history_screen.dart';
import 'package:singleclin_mobile/routes/app_routes.dart';

class AppPages {
  static final routes = [
    // Auth Routes
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: OnboardingBinding(),
    ),
    // TEMP: Onboarding removido do fluxo
    // GetPage(
    //   name: AppRoutes.onboarding,
    //   page: () => const OnboardingScreen(),
    //   binding: OnboardingBinding(),
    // ),
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

    // Dashboard Routes - TEMP: Comentado
    // GetPage(
    //   name: AppRoutes.dashboard,
    //   page: () => const DashboardScreen(),
    //   binding: DashboardBinding(),
    // ),

    // Home Route - Tela inicial simples
    GetPage(name: AppRoutes.home, page: () => const HomeScreen()),

    // Discovery Routes
    // TEMPORARIAMENTE COMENTADO - DiscoveryScreen tem erros
    // GetPage(
    //   name: AppRoutes.discovery,
    //   page: () => const DiscoveryScreen(),
    //   binding: DiscoveryBinding(),
    // ),
    // TEMPORARIAMENTE COMENTADO - Discovery avançado tem erros
    // GetPage(
    //   name: AppRoutes.clinicDetails,
    //   page: () => ClinicDetailsScreen(clinic: Get.arguments),
    //   binding: DiscoveryBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.mapView,
    //   page: () => MapViewScreen(
    //     clinics: Get.arguments['clinics'],
    //     onClinicTap: Get.arguments['onClinicTap'],
    //   ),
    //   binding: DiscoveryBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.filters,
    //   page: () => const FiltersScreen(),
    //   binding: DiscoveryBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.booking,
    //   page: () => const BookingScreen(),
    //   binding: DiscoveryBinding(),
    // ),
    // TEMP: Comentado - AppointmentBooking e ScanHistory têm erros
    // GetPage(
    //   name: AppRoutes.appointmentBooking,
    //   page: () => AppointmentBookingScreen(clinic: Get.arguments),
    // ),
    GetPage(name: AppRoutes.clinicServices, page: ClinicServicesScreen.new),
    // GetPage(
    //   name: AppRoutes.clinicScanHistory,
    //   page: () => const ScanHistoryScreen(),
    // ),

    // Module 3 - Appointment Routes - TEMP: Comentado
    // GetPage(
    //   name: AppRoutes.appointments,
    //   page: () => const AppointmentsScreen(),
    //   binding: AppointmentsBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.appointmentDetails,
    //   page: () => const AppointmentDetailsScreen(),
    //   binding: AppointmentsBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.cancelAppointment,
    //   page: () => const CancellationPolicyScreen(),
    //   binding: AppointmentsBinding(),
    // ),

    // Module 3 - Profile Routes - TEMPORARIAMENTE COMENTADO
    // GetPage(
    //   name: AppRoutes.profile,
    //   page: () => const ProfileScreen(),
    //   binding: ProfileBinding(),
    // ),
    // TEMPORARIAMENTE COMENTADO - Health History e Documents têm erros
    // GetPage(
    //   name: AppRoutes.healthHistory,
    //   page: () => const HealthHistoryScreen(),
    //   binding: ProfileBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.documents,
    //   page: () => const DocumentsScreen(),
    //   binding: ProfileBinding(),
    // ),

    // Module 5 - Engagement Routes - TEMPORARIAMENTE COMENTADO
    // GetPage(
    //   name: AppRoutes.reviews,
    //   page: () => const ReviewsScreen(),
    //   binding: ReviewsBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.writeReview,
    //   page: () => const WriteReviewScreen(),
    //   binding: WriteReviewBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.support,
    //   page: () => const SupportScreen(),
    //   binding: SupportBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.faq,
    //   page: () => const FaqScreen(),
    //   binding: FaqBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.community,
    //   page: () => const CommunityScreen(),
    //   binding: CommunityBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.feedback,
    //   page: () => const FeedbackScreen(),
    //   binding: FeedbackBinding(),
    // ),
    // GetPage(
    //   name: AppRoutes.trustCenter,
    //   page: () => const TrustCenterScreen(),
    //   binding: TrustCenterBinding(),
    // ),

    // Credits Routes
    GetPage(
      name: AppRoutes.creditHistory,
      page: () => const CreditHistoryScreen(),
      binding: CreditsBinding(),
    ),
    GetPage(
      name: AppRoutes.subscriptionPlans,
      page: () => const SubscriptionPlansScreen(),
    ),
  ];
}
