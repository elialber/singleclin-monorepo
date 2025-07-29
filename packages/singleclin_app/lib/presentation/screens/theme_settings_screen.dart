import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:singleclin_app/core/routes/app_routes.dart';
import 'package:singleclin_app/core/theme/app_colors.dart';
import 'package:singleclin_app/presentation/controllers/theme_controller.dart';

/// Theme settings screen
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Tema'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.settings),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Current theme info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Obx(() => Icon(
                            themeController.getThemeIcon(),
                            size: 32,
                            color: Theme.of(context).primaryColor,
                          )),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tema Atual',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Obx(() => Text(
                                  themeController.getThemeName(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Theme options
          const Text(
            'Escolha um tema',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Theme option tiles
          Obx(() {
            final options = themeController.getThemeOptions();
            return Column(
              children: options.map((option) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<ThemeMode>(
                    value: option.mode,
                    groupValue: themeController.themeMode,
                    onChanged: (mode) {
                      if (mode != null) {
                        themeController.setThemeMode(mode);
                      }
                    },
                    title: Text(option.title),
                    subtitle: Text(option.subtitle),
                    secondary: Icon(
                      option.icon,
                      color: option.isSelected
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          
          const SizedBox(height: 24),
          
          // Color preview section
          const Text(
            'Cores do Tema',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Color preview grid
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildColorRow(
                    'Principal',
                    AppColors.primary(context),
                    context,
                  ),
                  const SizedBox(height: 12),
                  _buildColorRow(
                    'Secundária',
                    AppColors.secondary(context),
                    context,
                  ),
                  const SizedBox(height: 12),
                  _buildColorRow(
                    'Sucesso',
                    AppColors.success,
                    context,
                  ),
                  const SizedBox(height: 12),
                  _buildColorRow(
                    'Aviso',
                    AppColors.warning,
                    context,
                  ),
                  const SizedBox(height: 12),
                  _buildColorRow(
                    'Erro',
                    AppColors.error,
                    context,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Preview components
          const Text(
            'Pré-visualização',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Button previews
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Botão Elevado'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Botão Contorno'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Botão Texto'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Other component previews
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Switch'),
                    value: true,
                    onChanged: (_) {},
                  ),
                  CheckboxListTile(
                    title: const Text('Checkbox'),
                    value: true,
                    onChanged: (_) {},
                  ),
                  RadioListTile<int>(
                    title: const Text('Radio'),
                    value: 1,
                    groupValue: 1,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildColorRow(String label, Color color, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          width: 60,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }
}