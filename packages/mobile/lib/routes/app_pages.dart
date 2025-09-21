import 'package:get/get.dart';

// Onboarding and Auth screens
import '../features/onboarding/screens/splash_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';

// Dashboard screens  
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/dashboard/screens/home_screen.dart';

import '../features/discovery/screens/discovery_screen.dart';
import '../features/discovery/screens/clinic_details_screen.dart';
import '../features/discovery/screens/map_view_screen.dart';
import '../features/discovery/screens/filters_screen.dart';
import '../features/discovery/screens/booking_screen.dart';

// Module 3 - Appointments screens
import '../features/appointments/screens/appointments_screen.dart';
import '../features/appointments/screens/appointment_details_screen.dart';
import '../features/appointments/screens/cancellation_policy_screen.dart';

// Module 3 - Profile screens
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/health_history_screen.dart';
import '../features/profile/screens/documents_screen.dart';

// Credits screens
import '../features/credits/screens/credit_history_screen.dart';
import '../features/credits/screens/subscription_plans_screen.dart';
import '../features/credits/bindings/credits_binding.dart';

// Bindings
import '../features/onboarding/controllers/onboarding_binding.dart';
import '../features/auth/controllers/auth_binding.dart';
import '../features/dashboard/controllers/dashboard_binding.dart';
import '../features/discovery/controllers/discovery_binding.dart';

// Module 3 - Bindings
import '../features/appointments/bindings/appointments_binding.dart';
import '../features/profile/bindings/profile_binding.dart';

// Module 5 - Engagement screens and bindings
import '../features/engagement/screens/reviews_screen.dart';
import '../features/engagement/screens/write_review_screen.dart';
import '../features/engagement/screens/support_screen.dart';
import '../features/engagement/screens/faq_screen.dart';
import '../features/engagement/screens/community_screen.dart';
import '../features/engagement/screens/feedback_screen.dart';
import '../features/engagement/screens/trust_center_screen.dart';
import '../features/engagement/bindings/engagement_binding.dart';

// Clinic services
import '../features/clinic_services/screens/clinic_services_screen.dart';
import '../features/appointment_booking/screens/appointment_booking_screen.dart';

import 'app_routes.dart';

class AppPages {
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
    
    // Discovery Routes
    GetPage(
      name: AppRoutes.discovery,
      page: () => const DiscoveryScreen(),
      binding: DiscoveryBinding(),
    ),
    GetPage(
      name: AppRoutes.clinicDetails,
      page: () => ClinicDetailsScreen(clinic: Get.arguments),
      binding: DiscoveryBinding(),
    ),
    GetPage(
      name: AppRoutes.mapView,
      page: () => MapViewScreen(clinics: Get.arguments['clinics'], onClinicTap: Get.arguments['onClinicTap']),
      binding: DiscoveryBinding(),
    ),
    GetPage(
      name: AppRoutes.filters,
      page: () => const FiltersScreen(),
      binding: DiscoveryBinding(),
    ),
    GetPage(
      name: AppRoutes.booking,
      page: () => const BookingScreen(),
      binding: DiscoveryBinding(),
    ),
    GetPage(
      name: AppRoutes.appointmentBooking,
      page: () => AppointmentBookingScreen(clinic: Get.arguments),
    ),
    GetPage(
      name: AppRoutes.clinicServices,
      page: () => ClinicServicesScreen(),
    ),
    
    // Module 3 - Appointment Routes
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
    GetPage(
      name: AppRoutes.cancelAppointment,
      page: () => const CancellationPolicyScreen(),
      binding: AppointmentsBinding(),
    ),
    
    // Module 3 - Profile Routes
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.healthHistory,
      page: () => const HealthHistoryScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.documents,
      page: () => const DocumentsScreen(),
      binding: ProfileBinding(),
    ),
    
    // Module 5 - Engagement Routes
    GetPage(
      name: AppRoutes.reviews,
      page: () => const ReviewsScreen(),
      binding: ReviewsBinding(),
    ),
    GetPage(
      name: AppRoutes.writeReview,
      page: () => const WriteReviewScreen(),
      binding: WriteReviewBinding(),
    ),
    GetPage(
      name: AppRoutes.support,
      page: () => const SupportScreen(),
      binding: SupportBinding(),
    ),
    GetPage(
      name: AppRoutes.faq,
      page: () => const FaqScreen(),
      binding: FaqBinding(),
    ),
    GetPage(
      name: AppRoutes.community,
      page: () => const CommunityScreen(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: AppRoutes.feedback,
      page: () => const FeedbackScreen(),
      binding: FeedbackBinding(),
    ),
    GetPage(
      name: AppRoutes.trustCenter,
      page: () => const TrustCenterScreen(),
      binding: TrustCenterBinding(),
    ),

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