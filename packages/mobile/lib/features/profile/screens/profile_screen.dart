import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_header.dart';
import '../widgets/lgpd_settings.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_bottom_nav.dart';
import '../../../core/constants/app_colors.dart';

/// Profile Screen
/// Main profile screen with user information and LGPD settings
class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Meu Perfil',
        actions: [
          Obx(() => controller.isEditing 
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: controller.cancelEditing,
                )
              : IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: controller.startEditing,
                )
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = controller.profile;
        if (profile == null) {
          return const Center(
            child: Text('Perfil não encontrado'),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              ProfileHeader(
                profile: controller.isEditing ? controller.tempProfile ?? profile : profile,
                isEditing: controller.isEditing,
                isUpdatingPhoto: controller.isUpdatingPhoto,
                onPhotoUpdate: controller.updateProfilePhoto,
                onPhotoRemove: controller.removeProfilePhoto,
              ),
              const SizedBox(height: 16),
              _buildProfileSections(),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
      bottomNavigationBar: controller.isEditing
          ? _buildBottomBar()
          : CustomBottomNav(
              currentIndex: 3, // Perfil é índice 3
              onTap: (index) => Get.find<BottomNavController>().changePage(index),
            ),
    );
  }

  /// Build profile sections
  Widget _buildProfileSections() {
    return Obx(() {
      final profile = controller.isEditing ? controller.tempProfile : controller.profile;
      if (profile == null) return const SizedBox.shrink();

      return Column(
        children: [
          _buildPersonalInfoSection(profile),
          const SizedBox(height: 16),
          _buildHealthInfoSection(profile),
          const SizedBox(height: 16),
          _buildContactInfoSection(profile),
          const SizedBox(height: 16),
          _buildAllergiesAndMedicationsSection(profile),
          const SizedBox(height: 16),
          _buildNotificationSettingsSection(profile),
          const SizedBox(height: 16),
          LgpdSettings(
            privacySettings: profile.privacySettings,
            onConsentUpdate: controller.updateConsent,
            onDataExport: controller.exportUserData,
            onAccountDeletion: controller.deleteAccount,
            isEditable: !controller.isEditing,
          ),
          const SizedBox(height: 16),
          _buildQuickActionsSection(),
        ],
      );
    });
  }

  /// Build personal information section
  Widget _buildPersonalInfoSection(profile) {
    return _buildSection(
      title: 'Informações Pessoais',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _buildInfoField(
            label: 'Nome Completo',
            value: profile.personalInfo.fullName,
            isEditable: controller.isEditing,
            onChanged: (value) {
              final newPersonalInfo = profile.personalInfo.copyWith(fullName: value);
              controller.updatePersonalInfo(newPersonalInfo);
            },
          ),
          _buildInfoField(
            label: 'Data de Nascimento',
            value: profile.personalInfo.birthDate != null 
                ? '${profile.personalInfo.birthDate!.day.toString().padLeft(2, '0')}/${profile.personalInfo.birthDate!.month.toString().padLeft(2, '0')}/${profile.personalInfo.birthDate!.year}'
                : 'Não informado',
            isEditable: false, // Date picker would be implemented separately
          ),
          _buildInfoField(
            label: 'Gênero',
            value: profile.personalInfo.gender.isEmpty ? 'Não informado' : profile.personalInfo.gender,
            isEditable: controller.isEditing,
            onChanged: (value) {
              final newPersonalInfo = profile.personalInfo.copyWith(gender: value);
              controller.updatePersonalInfo(newPersonalInfo);
            },
          ),
          _buildInfoField(
            label: 'CPF',
            value: profile.personalInfo.cpf.isEmpty ? 'Não informado' : profile.personalInfo.cpf,
            isEditable: controller.isEditing,
            onChanged: (value) {
              final newPersonalInfo = profile.personalInfo.copyWith(cpf: value);
              controller.updatePersonalInfo(newPersonalInfo);
            },
          ),
          _buildInfoField(
            label: 'Profissão',
            value: profile.personalInfo.occupation ?? 'Não informado',
            isEditable: controller.isEditing,
            onChanged: (value) {
              final newPersonalInfo = profile.personalInfo.copyWith(occupation: value.isEmpty ? null : value);
              controller.updatePersonalInfo(newPersonalInfo);
            },
          ),
          if (profile.personalInfo.age != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${profile.personalInfo.age} anos',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build health information section
  Widget _buildHealthInfoSection(profile) {
    return _buildSection(
      title: 'Informações de Saúde',
      icon: Icons.favorite_outline,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoField(
                  label: 'Tipo Sanguíneo',
                  value: profile.healthInfo.bloodType.isEmpty ? 'Não informado' : profile.healthInfo.bloodType,
                  isEditable: controller.isEditing,
                  onChanged: (value) {
                    final newHealthInfo = profile.healthInfo.copyWith(bloodType: value);
                    controller.updateHealthInfo(newHealthInfo);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoField(
                  label: 'Peso (kg)',
                  value: profile.healthInfo.weight?.toString() ?? 'Não informado',
                  isEditable: controller.isEditing,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final weight = double.tryParse(value);
                    final newHealthInfo = profile.healthInfo.copyWith(weight: weight);
                    controller.updateHealthInfo(newHealthInfo);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoField(
                  label: 'Altura (cm)',
                  value: profile.healthInfo.height?.toString() ?? 'Não informado',
                  isEditable: controller.isEditing,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final height = double.tryParse(value);
                    final newHealthInfo = profile.healthInfo.copyWith(height: height);
                    controller.updateHealthInfo(newHealthInfo);
                  },
                ),
              ),
              const SizedBox(width: 12),
              if (profile.healthInfo.bmi != null) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'IMC: ${profile.healthInfo.bmi!.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.healthInfo.bmiCategory,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoField(
            label: 'Convênio Médico',
            value: profile.healthInfo.insuranceProvider ?? 'Não informado',
            isEditable: controller.isEditing,
            onChanged: (value) {
              final newHealthInfo = profile.healthInfo.copyWith(
                insuranceProvider: value.isEmpty ? null : value
              );
              controller.updateHealthInfo(newHealthInfo);
            },
          ),
        ],
      ),
    );
  }

  /// Build contact information section
  Widget _buildContactInfoSection(profile) {
    return _buildSection(
      title: 'Informações de Contato',
      icon: Icons.contact_phone_outlined,
      child: Column(
        children: [
          _buildInfoField(
            label: 'Telefone',
            value: profile.contactInfo.phone.isEmpty ? 'Não informado' : profile.contactInfo.phone,
            isEditable: controller.isEditing,
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              final newContactInfo = profile.contactInfo.copyWith(phone: value);
              controller.updateContactInfo(newContactInfo);
            },
          ),
          _buildInfoField(
            label: 'WhatsApp',
            value: profile.contactInfo.whatsapp ?? 'Não informado',
            isEditable: controller.isEditing,
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              final newContactInfo = profile.contactInfo.copyWith(
                whatsapp: value.isEmpty ? null : value
              );
              controller.updateContactInfo(newContactInfo);
            },
          ),
          if (profile.contactInfo.address != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Endereço',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.contactInfo.address!.formattedAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build allergies and medications section
  Widget _buildAllergiesAndMedicationsSection(profile) {
    return _buildSection(
      title: 'Alergias e Medicamentos',
      icon: Icons.medical_services_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTagsList(
            label: 'Alergias',
            items: profile.allergies,
            emptyMessage: 'Nenhuma alergia informada',
            onAdd: controller.isEditing ? (value) => controller.addAllergy(value) : null,
            onRemove: controller.isEditing ? (value) => controller.removeAllergy(value) : null,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          _buildTagsList(
            label: 'Medicamentos',
            items: profile.medications,
            emptyMessage: 'Nenhum medicamento informado',
            onAdd: controller.isEditing ? (value) => controller.addMedication(value) : null,
            onRemove: controller.isEditing ? (value) => controller.removeMedication(value) : null,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          _buildTagsList(
            label: 'Condições de Saúde',
            items: profile.healthConditions,
            emptyMessage: 'Nenhuma condição informada',
            onAdd: controller.isEditing ? (value) => controller.addHealthCondition(value) : null,
            onRemove: controller.isEditing ? (value) => controller.removeHealthCondition(value) : null,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  /// Build notification settings section
  Widget _buildNotificationSettingsSection(profile) {
    if (!controller.isEditing) return const SizedBox.shrink();

    return _buildSection(
      title: 'Configurações de Notificação',
      icon: Icons.notifications_outlined,
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Notificações Push'),
            subtitle: const Text('Receber notificações no celular'),
            value: profile.notificationSettings.pushNotifications,
            onChanged: (value) {
              final newSettings = NotificationSettings(
                pushNotifications: value,
                emailNotifications: profile.notificationSettings.emailNotifications,
                smsNotifications: profile.notificationSettings.smsNotifications,
                appointmentReminders: profile.notificationSettings.appointmentReminders,
                promotionalNotifications: profile.notificationSettings.promotionalNotifications,
                healthTips: profile.notificationSettings.healthTips,
                reminderHoursBefore: profile.notificationSettings.reminderHoursBefore,
              );
              controller.updateNotificationSettings(newSettings);
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('E-mail'),
            subtitle: const Text('Receber notificações por email'),
            value: profile.notificationSettings.emailNotifications,
            onChanged: (value) {
              final newSettings = NotificationSettings(
                pushNotifications: profile.notificationSettings.pushNotifications,
                emailNotifications: value,
                smsNotifications: profile.notificationSettings.smsNotifications,
                appointmentReminders: profile.notificationSettings.appointmentReminders,
                promotionalNotifications: profile.notificationSettings.promotionalNotifications,
                healthTips: profile.notificationSettings.healthTips,
                reminderHoursBefore: profile.notificationSettings.reminderHoursBefore,
              );
              controller.updateNotificationSettings(newSettings);
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Lembretes de Agendamento'),
            subtitle: const Text('Lembrar sobre consultas próximas'),
            value: profile.notificationSettings.appointmentReminders,
            onChanged: (value) {
              final newSettings = NotificationSettings(
                pushNotifications: profile.notificationSettings.pushNotifications,
                emailNotifications: profile.notificationSettings.emailNotifications,
                smsNotifications: profile.notificationSettings.smsNotifications,
                appointmentReminders: value,
                promotionalNotifications: profile.notificationSettings.promotionalNotifications,
                healthTips: profile.notificationSettings.healthTips,
                reminderHoursBefore: profile.notificationSettings.reminderHoursBefore,
              );
              controller.updateNotificationSettings(newSettings);
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  /// Build quick actions section
  Widget _buildQuickActionsSection() {
    return _buildSection(
      title: 'Acesso Rápido',
      icon: Icons.dashboard_outlined,
      child: Column(
        children: [
          _buildQuickActionTile(
            icon: Icons.history,
            title: 'Histórico Médico',
            subtitle: 'Ver procedimentos realizados',
            onTap: () => Get.toNamed('/profile/health-history'),
          ),
          _buildQuickActionTile(
            icon: Icons.folder_outlined,
            title: 'Meus Documentos',
            subtitle: 'Resultados e receitas médicas',
            onTap: () => Get.toNamed('/profile/documents'),
          ),
          _buildQuickActionTile(
            icon: Icons.schedule,
            title: 'Meus Agendamentos',
            subtitle: 'Ver consultas marcadas',
            onTap: () => Get.toNamed('/appointments'),
          ),
          _buildQuickActionTile(
            icon: Icons.help_outline,
            title: 'Ajuda e Suporte',
            subtitle: 'Fale conosco',
            onTap: () {
              // Navigate to support screen
            },
          ),
        ],
      ),
    );
  }

  /// Build section wrapper
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// Build info field
  Widget _buildInfoField({
    required String label,
    required String value,
    bool isEditable = false,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        if (isEditable) ...[
          TextFormField(
            initialValue: value == 'Não informado' ? '' : value,
            onChanged: onChanged,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: 'Digite $label...',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ] else ...[
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// Build tags list
  Widget _buildTagsList({
    required String label,
    required List<String> items,
    required String emptyMessage,
    Function(String)? onAdd,
    Function(String)? onRemove,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (onAdd != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showAddItemDialog(label, onAdd),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty) ...[
          Text(
            emptyMessage,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ] else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (onRemove != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onRemove(item),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: color,
                      ),
                    ),
                  ],
                ],
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  /// Build quick action tile
  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.mediumGrey,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// Build bottom bar
  Widget _buildBottomBar() {
    return Obx(() {
      if (!controller.isEditing) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.cancelEditing,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.isSaving ? null : controller.saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: controller.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Show add item dialog
  void _showAddItemDialog(String type, Function(String) onAdd) {
    final controller = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: Text('Adicionar $type'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Digite o nome...',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAdd(controller.text);
                Get.back();
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}