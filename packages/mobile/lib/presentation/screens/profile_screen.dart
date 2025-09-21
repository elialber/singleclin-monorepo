import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/custom_bottom_nav.dart';
import '../../shared/controllers/bottom_nav_controller.dart';
import '../../core/constants/app_colors.dart';

/// User profile screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'João Silva',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'joao.silva@email.com',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Current plan
            Card(
              child: ListTile(
                leading: const Icon(Icons.card_membership),
                title: const Text('Plano Atual'),
                subtitle: const Text('Premium - 10 créditos'),
                trailing: TextButton(
                  onPressed: () {
                    // TODO(navigation): Navigate to plans
                  },
                  child: const Text('Alterar'),
                ),
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
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO(auth): Implement logout
                  Get.offAllNamed(AppRoutes.login);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              ),
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
}
