import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/data/services/auth_service.dart';
import 'package:singleclin_mobile/data/services/token_refresh_service.dart';
import 'package:singleclin_mobile/presentation/widgets/singleclin_logo.dart';

/// Splash screen shown on app launch
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  final TokenRefreshService _tokenRefreshService =
      Get.find<TokenRefreshService>();

  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    try {
      // Show splash for minimum duration
      await Future.delayed(const Duration(seconds: 1));

      // Add timeout to prevent infinite loading
      final result = await Future.any([
        _checkAuthenticationWithTimeout(),
        Future.delayed(const Duration(seconds: 5), () => false), // 5-second timeout
      ]);

      if (result == true) {
        // User is authenticated, go to home
        if (mounted) {
          Get.offAllNamed('/home');
        }
      } else {
        // Not authenticated or timeout occurred, go to login
        if (mounted) {
          Get.offAllNamed('/login');
        }
      }
    } catch (e) {
      print('Splash screen error: $e');
      // On any error, default to login screen
      if (mounted) {
        Get.offAllNamed('/login');
      }
    }
  }

  Future<bool> _checkAuthenticationWithTimeout() async {
    try {
      // Simple check - just verify if user is authenticated
      // Skip token validation on splash to avoid blocking
      final isAuthenticated = await _authService.isAuthenticated().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      
      print('🔍 Authentication check result: $isAuthenticated');
      return isAuthenticated;
    } catch (e) {
      print('Authentication check error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            const SingleClinLogo(
              size: 120,
            ),
            const SizedBox(height: 24),
            Text(
              'SingleClin',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saúde simplificada',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
