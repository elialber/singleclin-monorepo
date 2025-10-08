import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';
import 'package:singleclin_mobile/features/auth/controllers/auth_controller.dart';
import 'package:singleclin_mobile/features/onboarding/controllers/onboarding_controller.dart';
import 'package:singleclin_mobile/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _textAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSplashSequence();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    // Logo animations
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Text animations
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _textAnimationController,
            curve: Curves.easeOutBack,
          ),
        );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textAnimationController, curve: Curves.easeIn),
    );
  }

  Future<void> _startSplashSequence() async {
    // Start logo animation
    await _logoAnimationController.forward();

    // Wait a bit, then start text animation
    await Future.delayed(const Duration(milliseconds: 200));
    await _textAnimationController.forward();

    // Wait for minimum splash time
    await Future.delayed(const Duration(milliseconds: 1000));

    // Navigate to next screen
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Verificar se o usuário está autenticado
    try {
      final authController = Get.find<AuthController>();

      // Aguardar um pouco para garantir que o AuthController verificou o status
      await Future.delayed(const Duration(milliseconds: 500));

      if (authController.isAuthenticated) {
        // Usuário já está logado, ir para a lista de clínicas
        Get.offNamed(AppRoutes.clinicsList);
      } else{
        // Usuário não está logado, ir para login
        Get.offNamed(AppRoutes.login);
      }
    } catch (e) {
      // Se AuthController não estiver registrado ainda, ir para login
      print('Error checking auth status: $e');
      Get.offNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo section
              AnimatedBuilder(
                animation: _logoAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Opacity(
                      opacity: _logoOpacityAnimation.value,
                      child: _buildLogo(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 48),

              // Text section
              AnimatedBuilder(
                animation: _textAnimationController,
                builder: (context, child) {
                  return SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: _buildTextSection(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 80),

              // Loading indicator
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'SC',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: -2,
          ),
        ),
      ),
    );
  }

  Widget _buildTextSection() {
    return Column(
      children: [
        const Text(
          'SingleClin',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Estética e saúde na palma da mão',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.sgPrimary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

/// Alternative splash screen with more sophisticated animations
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late List<Animation<Offset>> _particleAnimations;

  @override
  void initState() {
    super.initState();
    _initComplexAnimations();
    _startAnimationSequence();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _initComplexAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Create particle animations
    _particleAnimations = List.generate(8, (index) {
      final angle = (index * 45) * (3.14159 / 180); // Convert to radians
      return Tween<Offset>(
        begin: Offset.zero,
        end: Offset(
          0.3 * (index % 2 == 0 ? 1 : -1),
          0.3 * (index < 4 ? -1 : 1),
        ),
      ).animate(
        CurvedAnimation(
          parent: _particleController,
          curve: Interval(
            0.2 + (index * 0.1),
            0.8 + (index * 0.1),
            curve: Curves.easeOutBack,
          ),
        ),
      );
    });
  }

  Future<void> _startAnimationSequence() async {
    // Start particle animation
    _particleController.forward();

    // Wait a bit, then start main animation
    await Future.delayed(const Duration(milliseconds: 500));
    await _mainController.forward();

    // Wait for completion
    await Future.delayed(const Duration(milliseconds: 1500));

    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    final controller = Get.find<OnboardingController>();

    if (controller.shouldShowOnboarding()) {
      Get.offNamed('/onboarding');
    } else {
      Get.offNamed('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Particle effects
                ...List.generate(_particleAnimations.length, (index) {
                  return AnimatedBuilder(
                    animation: _particleAnimations[index],
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          _particleAnimations[index].value.dx * 100,
                          _particleAnimations[index].value.dy * 100,
                        ),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.sgPrimary.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  );
                }),

                // Main content
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with scale and rotation
                        Transform.scale(
                          scale: Tween<double>(begin: 0.3, end: 1.0)
                              .animate(
                                CurvedAnimation(
                                  parent: _mainController,
                                  curve: const Interval(
                                    0.0,
                                    0.6,
                                    curve: Curves.elasticOut,
                                  ),
                                ),
                              )
                              .value,
                          child: Transform.rotate(
                            angle: Tween<double>(begin: 0.5, end: 0.0)
                                .animate(
                                  CurvedAnimation(
                                    parent: _mainController,
                                    curve: const Interval(
                                      0.0,
                                      0.4,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                )
                                .value,
                            child: _buildAnimatedLogo(),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Text with slide animation
                        Transform.translate(
                          offset: Offset(
                            0,
                            Tween<double>(begin: 50, end: 0)
                                .animate(
                                  CurvedAnimation(
                                    parent: _mainController,
                                    curve: const Interval(
                                      0.4,
                                      0.8,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                )
                                .value,
                          ),
                          child: Opacity(
                            opacity: Tween<double>(begin: 0.0, end: 1.0)
                                .animate(
                                  CurvedAnimation(
                                    parent: _mainController,
                                    curve: const Interval(
                                      0.4,
                                      0.8,
                                      curve: Curves.easeIn,
                                    ),
                                  ),
                                )
                                .value,
                            child: _buildTextSection(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: AppColors.sgPrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'SC',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: -3,
          ),
        ),
      ),
    );
  }

  Widget _buildTextSection() {
    return Column(
      children: [
        const Text(
          'SingleClin',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Conectando você aos melhores\nespecialistas em estética e saúde',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            gradient: AppColors.sgGradient,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ],
    );
  }
}
