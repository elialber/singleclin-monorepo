import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:singleclin_app/core/routes/app_routes.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/token_refresh_service.dart';

/// Splash screen shown on app launch
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  final TokenRefreshService _tokenRefreshService = Get.find<TokenRefreshService>();
  
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    try {
      // Show splash for minimum duration
      await Future.delayed(const Duration(seconds: 1));
      
      // Check authentication status
      final isAuthenticated = await _authService.isAuthenticated();
      
      if (isAuthenticated) {
        // Verify token is valid and refresh if needed
        final token = await _tokenRefreshService.getCurrentToken();
        
        if (token != null) {
          // User is authenticated with valid token, go to home
          if (mounted) {
            context.go(AppRoutes.home);
          }
        } else {
          // Token refresh failed, go to login
          if (mounted) {
            context.go(AppRoutes.login);
          }
        }
      } else {
        // User is not authenticated, go to login
        if (mounted) {
          context.go(AppRoutes.login);
        }
      }
    } catch (e) {
      // On any error, default to login screen
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                size: 60,
                color: Colors.white,
              ),
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
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}