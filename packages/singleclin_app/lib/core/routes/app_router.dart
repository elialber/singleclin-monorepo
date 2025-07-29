import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:singleclin_app/core/routes/app_routes.dart';
import 'package:singleclin_app/presentation/screens/screens.dart';
import 'package:singleclin_app/presentation/screens/theme_settings_screen.dart';

/// App router configuration with GoRouter
class AppRouter {
  // Private constructor to prevent instantiation
  AppRouter._();

  // Navigator key for GetX integration
  static final GlobalKey<NavigatorState> navigatorKey = Get.key;

  // Auth notifier for reactive route protection
  static final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);

  // User type notifier (user or clinic)
  static final ValueNotifier<String?> userType = ValueNotifier<String?>(null);

  // Route observer for analytics and debugging
  static final List<NavigatorObserver> observers = [
    GetObserver(), // GetX observer for Get.to navigation
  ];

  // GoRouter instance
  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    observers: observers,
    
    // Redirect logic for protected routes
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = isAuthenticated.value;
      final String location = state.matchedLocation;
      final bool isPublic = AppRoutes.isPublicRoute(location);
      final bool isClinicRoute = AppRoutes.isClinicRoute(location);

      // If not logged in and trying to access protected route, redirect to login
      if (!loggedIn && !isPublic) {
        return AppRoutes.login;
      }

      // If logged in and trying to access login/register, redirect to home
      if (loggedIn && (location == AppRoutes.login || location == AppRoutes.register)) {
        return AppRoutes.home;
      }

      // If trying to access clinic route without being a clinic user
      if (isClinicRoute && userType.value != 'clinic') {
        return AppRoutes.home;
      }

      // No redirect needed
      return null;
    },

    // Error handler
    errorBuilder: (context, state) => ErrorScreen(error: state.error),

    // Routes
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main app routes
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => HomePage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),

      // QR Code routes
      GoRoute(
        path: AppRoutes.qrGenerate,
        builder: (context, state) => const QrCodeScreen(),
      ),
      GoRoute(
        path: AppRoutes.qrScan,
        builder: (context, state) => const QrScanScreen(),
      ),

      // Transaction routes
      GoRoute(
        path: AppRoutes.transactionHistory,
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.transactionDetails,
        builder: (context, state) {
          final String transactionId = state.pathParameters['id'] ?? '';
          return TransactionDetailsScreen(transactionId: transactionId);
        },
      ),

      // Settings routes
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.themeSettings,
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),

      // Clinic routes
      GoRoute(
        path: AppRoutes.clinicDashboard,
        builder: (context, state) => const ClinicDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.clinicQrScan,
        builder: (context, state) => const ClinicQrScanScreen(),
      ),

      // Error routes
      GoRoute(
        path: AppRoutes.notFound,
        builder: (context, state) => const NotFoundScreen(),
      ),
    ],
  );

  // Helper methods
  static void setAuthenticated(bool value) {
    isAuthenticated.value = value;
  }

  static void setUserType(String? type) {
    userType.value = type;
  }

  static void logout() {
    isAuthenticated.value = false;
    userType.value = null;
    router.go(AppRoutes.login);
  }
}

/// Error screen widget
class ErrorScreen extends StatelessWidget {
  final Exception? error;

  const ErrorScreen({this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erro'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ops! Algo deu errado.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder screens (to be implemented)
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tela de Cadastro'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Voltar ao Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class QrScanScreen extends StatelessWidget {
  const QrScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR Code')),
      body: const Center(child: Text('Scanner QR Code')),
    );
  }
}

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: const Center(child: Text('Histórico de Transações')),
    );
  }
}

class TransactionDetailsScreen extends StatelessWidget {
  final String transactionId;
  
  const TransactionDetailsScreen({required this.transactionId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Transação')),
      body: Center(child: Text('Transação ID: $transactionId')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Aparência'),
            subtitle: const Text('Tema claro, escuro ou do sistema'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.themeSettings),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Alterar Senha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.changePassword),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Sobre'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.about),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: const Center(child: Text('Sobre o SingleClin')),
    );
  }
}

class ClinicDashboardScreen extends StatelessWidget {
  const ClinicDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Clínica')),
      body: const Center(child: Text('Dashboard da Clínica')),
    );
  }
}

class ClinicQrScanScreen extends StatelessWidget {
  const ClinicQrScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validar QR Code')),
      body: const Center(child: Text('Scanner QR Code - Clínica')),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64),
            const SizedBox(height: 16),
            const Text('404 - Página não encontrada'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    );
  }
}