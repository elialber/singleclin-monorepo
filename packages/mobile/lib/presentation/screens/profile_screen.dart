import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/custom_bottom_nav.dart';
import '../../shared/controllers/bottom_nav_controller.dart';
import '../../core/constants/app_colors.dart';

/// User profile screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile header
            Obx(() => Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: authController.currentUser?.photoUrl != null
                          ? NetworkImage(authController.currentUser!.photoUrl!)
                          : null,
                      backgroundColor: AppColors.primary,
                      child: authController.currentUser?.photoUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      authController.currentUser?.displayName ?? 'Usuário',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authController.currentUser?.email ?? 'Não informado',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (authController.currentUser?.isEmailVerified == false) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Email não verificado',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )),
            const SizedBox(height: 16),

            // Current plan and credits
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.card_membership, color: AppColors.primary),
                    title: const Text('Plano Atual'),
                    subtitle: const Text('Premium'),
                    trailing: TextButton(
                      onPressed: () => Get.toNamed('/subscription-plans'),
                      child: const Text('Alterar'),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
                    title: const Text('Créditos Disponíveis'),
                    subtitle: const Text('Seus créditos para consultas'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '10', // TODO: Integrar com API para obter créditos reais
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Menu items
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Histórico de Transações'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed(AppRoutes.creditHistory),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Configurações'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed(AppRoutes.settings),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Sobre'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Get.toNamed(AppRoutes.about),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: Obx(() => OutlinedButton.icon(
                onPressed: authController.isLoading
                    ? null
                    : () => _showLogoutDialog(context, authController),
                icon: authController.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: Text(authController.isLoading ? 'Saindo...' : 'Sair'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              )),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3, // Perfil é índice 3
        onTap: (index) => Get.find<BottomNavController>().changePage(index),
      ),
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog(BuildContext context, AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar Logout'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              authController.signOut(); // Perform logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
