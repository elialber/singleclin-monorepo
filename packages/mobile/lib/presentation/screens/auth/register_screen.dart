import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:singleclin_mobile/core/utils/form_validators.dart';
import 'package:singleclin_mobile/data/services/firebase_initialization_service.dart';
import 'package:singleclin_mobile/presentation/controllers/auth_controller.dart';
import 'package:singleclin_mobile/presentation/widgets/firebase_unavailable_view.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final FirebaseInitializationService firebaseService =
        Get.find<FirebaseInitializationService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: authController.goToLogin,
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (!firebaseService.firebaseReady) {
            return const FirebaseUnavailableView(compact: true);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Welcome text
              Column(
                children: [
                  Text(
                    'Crie sua conta',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preencha os dados abaixo para se cadastrar',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Register form
              Form(
                key: authController.registerFormKey,
                child: Column(
                  children: [
                    // Name field
                    TextFormField(
                      controller: authController.nameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: FormValidators.validateName,
                      decoration: InputDecoration(
                        labelText: 'Nome completo',
                        hintText: 'Digite seu nome completo',
                        prefixIcon: const Icon(Icons.person_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Email field
                    TextFormField(
                      controller: authController.emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.validateEmail,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Digite seu email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: authController.passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.validatePassword,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        hintText: 'Mínimo 6 caracteres',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Confirm password field
                    TextFormField(
                      controller: authController.confirmPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: (value) =>
                          FormValidators.validateConfirmPassword(
                            value,
                            authController.passwordController.text,
                          ),
                      onFieldSubmitted: (_) => authController.signUp(),
                      decoration: InputDecoration(
                        labelText: 'Confirmar senha',
                        hintText: 'Digite a senha novamente',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Terms and privacy info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  'Ao criar uma conta, você concorda com nossos ',
                            ),
                            TextSpan(
                              text: 'Termos de Uso',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: ' e '),
                            TextSpan(
                              text: 'Política de Privacidade',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Error message
                    Obx(
                      () => authController.errorMessage != null
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      authController.errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Register button
                    Obx(
                      () => SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: authController.isLoading
                              ? null
                              : authController.signUp,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: authController.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Criar Conta',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'ou',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 32),

              // Social registration buttons
              Column(
                children: [
                  // Google Sign Up
                  Obx(
                    () => SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: authController.isLoading
                            ? null
                            : authController.signInWithGoogle,
                        icon: Image.asset(
                          'assets/icons/google.png',
                          height: 20,
                          width: 20,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.g_mobiledata, size: 24),
                        ),
                        label: const Text('Cadastrar com Google'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Apple Sign Up (only show on iOS)
                  if (GetPlatform.isIOS)
                    Obx(
                      () => SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: authController.isLoading
                              ? null
                              : authController.signInWithApple,
                          icon: const Icon(Icons.apple, size: 20),
                          label: const Text('Cadastrar com Apple'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 32),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Já tem uma conta? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: authController.goToLogin,
                    child: Text(
                      'Faça login',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        }),
      ),
    );
  }
}
