import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'package:singleclin_mobile/core/routes/app_router.dart';
import 'package:singleclin_mobile/core/routes/app_routes.dart';
import 'package:singleclin_mobile/presentation/controllers/home_controller.dart';

/// Home page using GetX for state management
class HomePage extends StatelessWidget {
  HomePage({super.key});

  // Get the controller instance
  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Obx(() => Text(controller.welcomeMessage)),
        actions: [
          // Dark mode toggle
          IconButton(
            icon: Icon(Get.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: controller.toggleDarkMode,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Counter section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Você pressionou o botão:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Text(
                        '${controller.counter}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('vezes', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Items list section
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lista de Itens',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear_all),
                            onPressed: controller.clearItems,
                            tooltip: 'Limpar lista',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Add item input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Adicionar novo item',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (value) {
                                controller.addItem(value);
                                // Clear the text field
                                Get.focusScope?.unfocus();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Items list
                      Expanded(
                        child: Obx(
                          () => controller.items.isEmpty
                              ? const Center(
                                  child: Text('Nenhum item na lista'),
                                )
                              : ListView.builder(
                                  itemCount: controller.items.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(controller.items[index]),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () =>
                                            controller.removeItem(index),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: controller.showExampleDialog,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Diálogo'),
                ),
                ElevatedButton.icon(
                  onPressed: controller.showExampleBottomSheet,
                  icon: const Icon(Icons.vertical_align_bottom),
                  label: const Text('Bottom Sheet'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Navigation buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.qrGenerate),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('QR Code'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.profile),
                  icon: const Icon(Icons.person),
                  label: const Text('Perfil'),
                ),
                OutlinedButton.icon(
                  onPressed: AppRouter.logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                ),
              ],
            ),

            // Loading indicator
            const SizedBox(height: 20),
            Obx(
              () => controller.isLoading
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.incrementCounter,
        tooltip: 'Incrementar',
        child: const Icon(Icons.add),
      ),
    );
  }
}
