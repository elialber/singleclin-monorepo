class AppRoutes {
  // Auth Routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main App Routes
  static const String dashboard = '/dashboard';
  static const String home = '/home';

  // Discovery Routes
  static const String discovery = '/discovery';
  static const String clinicDetails = '/clinic-details';
  static const String serviceDetails = '/service-details';
  static const String searchResults = '/search-results';
  static const String mapView = '/map-view';
  static const String filters = '/filters';

  // Appointment Routes
  static const String appointments = '/appointments';
  static const String appointmentDetails = '/appointments/details';
  static const String bookAppointment = '/book-appointment';
  static const String booking = '/booking';
  static const String appointmentBooking = '/appointment-booking';
  static const String clinicServices = '/clinic-services';
  static const String selectDateTime = '/select-date-time';
  static const String appointmentSummary = '/appointment-summary';
  static const String appointmentConfirmation = '/appointment-confirmation';
  static const String rescheduleAppointment = '/reschedule-appointment';
  static const String cancelAppointment = '/appointments/cancel';
  static const String appointmentRate = '/appointments/rate';

  static const String clinicScanHistory = '/clinic/scan-history';

  // Profile Routes
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String personalInfo = '/personal-info';
  static const String healthHistory = '/profile/health-history';
  static const String documents = '/profile/documents';
  static const String documentView = '/documents/view';
  static const String preferences = '/preferences';
  static const String notificationSettings = '/notification-settings';
  static const String privacySettings = '/privacy-settings';

  // Credits Routes
  static const String credits = '/credits';
  static const String creditHistory = '/credit-history';
  static const String buyCredits = '/buy-credits';
  static const String subscriptionPlans = '/subscription-plans';
  static const String subscriptionDetails = '/subscription-details';
  static const String paymentMethods = '/payment-methods';
  static const String addPaymentMethod = '/add-payment-method';
  static const String referralProgram = '/referral-program';

  // Engagement Routes
  static const String reviews = '/reviews';
  static const String writeReview = '/write-review';
  static const String support = '/support';
  static const String supportTicket = '/support/ticket';
  static const String faq = '/faq';
  static const String community = '/community';
  static const String communityPost = '/community/post';
  static const String feedback = '/feedback';
  static const String trustCenter = '/trust-center';
  static const String contactSupport = '/contact-support';
  static const String helpCenter = '/help-center';

  // Settings Routes
  static const String settings = '/settings';
  static const String about = '/about';
  static const String termsOfService = '/terms-of-service';
  static const String privacyPolicy = '/privacy-policy';

  // Error Routes
  static const String error = '/error';
  static const String maintenance = '/maintenance';
  static const String noInternet = '/no-internet';
}
