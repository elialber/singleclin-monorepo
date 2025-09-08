import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../../../core/constants/app_colors.dart';

/// LGPD Settings Widget
/// Provides LGPD compliance controls and information
class LgpdSettings extends StatelessWidget {
  final PrivacySettings privacySettings;
  final Function(String, bool)? onConsentUpdate;
  final VoidCallback? onDataExport;
  final VoidCallback? onAccountDeletion;
  final bool isEditable;

  const LgpdSettings({
    Key? key,
    required this.privacySettings,
    this.onConsentUpdate,
    this.onDataExport,
    this.onAccountDeletion,
    this.isEditable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
          width: 1,
        ),
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
          _buildHeader(),
          const SizedBox(height: 16),
          _buildConsentDate(),
          const SizedBox(height: 20),
          _buildConsentControls(),
          const SizedBox(height: 20),
          _buildDataRights(),
        ],
      ),
    );
  }

  /// Build section header
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              color: AppColors.info,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Privacidade e Dados (LGPD)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Gerencie como seus dados são utilizados de acordo com a Lei Geral de Proteção de Dados.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  /// Build consent date information
  Widget _buildConsentDate() {
    if (privacySettings.consentDate == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.warning.withOpacity(0.3),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.warning_outlined,
              color: AppColors.warning,
              size: 16,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Consentimento pendente. Por favor, revise suas preferências.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final consentDate = privacySettings.consentDate!;
    final formattedDate = '${consentDate.day.toString().padLeft(2, '0')}/${consentDate.month.toString().padLeft(2, '0')}/${consentDate.year}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outlined,
            color: AppColors.success,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Consentimento atualizado em $formattedDate',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build consent controls
  Widget _buildConsentControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Consentimentos',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildConsentSwitch(
          title: 'Processamento de Dados Pessoais',
          subtitle: 'Autorizo o tratamento dos meus dados para prestação de serviços',
          value: privacySettings.dataProcessingConsent,
          onChanged: isEditable 
              ? (value) => onConsentUpdate?.call('data_processing', value)
              : null,
          isRequired: true,
        ),
        _buildConsentSwitch(
          title: 'Marketing e Comunicações',
          subtitle: 'Receber ofertas, promoções e conteúdos personalizados',
          value: privacySettings.marketingConsent,
          onChanged: isEditable 
              ? (value) => onConsentUpdate?.call('marketing', value)
              : null,
        ),
        _buildConsentSwitch(
          title: 'Análise e Melhorias',
          subtitle: 'Usar dados para análises e melhoria dos serviços',
          value: privacySettings.analyticsConsent,
          onChanged: isEditable 
              ? (value) => onConsentUpdate?.call('analytics', value)
              : null,
        ),
        _buildConsentSwitch(
          title: 'Compartilhamento com Parceiros',
          subtitle: 'Compartilhar dados com clínicas parceiras para melhor atendimento',
          value: privacySettings.sharingConsent,
          onChanged: isEditable 
              ? (value) => onConsentUpdate?.call('sharing', value)
              : null,
        ),
      ],
    );
  }

  /// Build consent switch
  Widget _buildConsentSwitch({
    required String title,
    required String subtitle,
    required bool value,
    Function(bool)? onChanged,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isRequired) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Obrigatório',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: isRequired ? null : onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// Build data rights section
  Widget _buildDataRights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seus Direitos',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildDataRightItem(
          icon: Icons.download_outlined,
          title: 'Portabilidade dos Dados',
          subtitle: 'Baixe uma cópia de todos os seus dados',
          onTap: onDataExport,
          color: AppColors.info,
        ),
        _buildDataRightItem(
          icon: Icons.info_outlined,
          title: 'Transparência',
          subtitle: 'Saiba que dados coletamos e como são usados',
          onTap: () => _showDataUsageDialog(),
          color: AppColors.primary,
        ),
        _buildDataRightItem(
          icon: Icons.delete_forever_outlined,
          title: 'Exclusão da Conta',
          subtitle: 'Exclua permanentemente sua conta e dados',
          onTap: onAccountDeletion,
          color: AppColors.error,
        ),
      ],
    );
  }

  /// Build data right item
  Widget _buildDataRightItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.mediumGrey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show data usage information dialog
  void _showDataUsageDialog() {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: const Text('Como Usamos Seus Dados'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDataUsageItem(
                'Dados de Identificação',
                'Nome, email, CPF, telefone - Para identificação e contato',
              ),
              _buildDataUsageItem(
                'Dados de Saúde',
                'Histórico médico, alergias, medicamentos - Para segurança nos procedimentos',
              ),
              _buildDataUsageItem(
                'Dados de Uso',
                'Interações no app, preferências - Para melhorar a experiência',
              ),
              _buildDataUsageItem(
                'Dados de Localização',
                'Localização aproximada - Para encontrar clínicas próximas',
              ),
              const SizedBox(height: 16),
              const Text(
                'Seus dados são criptografados e nunca são vendidos para terceiros. Apenas compartilhamos com clínicas parceiras quando necessário para seu atendimento.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  /// Build data usage item for dialog
  Widget _buildDataUsageItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}