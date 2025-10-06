import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/features/engagement/controllers/trust_center_controller.dart';
import 'package:singleclin_mobile/features/engagement/widgets/trust_badge.dart';

class TrustCenterScreen extends StatelessWidget {
  const TrustCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TrustCenterController>(
      builder: (controller) {
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Central de Confiança'),
              backgroundColor: const Color(0xFF005156),
              foregroundColor: Colors.white,
              bottom: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Color(0xFFFFB000),
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.security), text: 'Segurança'),
                  Tab(icon: Icon(Icons.verified), text: 'Certificações'),
                  Tab(icon: Icon(Icons.privacy_tip), text: 'Privacidade'),
                  Tab(icon: Icon(Icons.policy), text: 'Políticas'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildSecurityTab(controller),
                _buildCertificationsTab(controller),
                _buildPrivacyTab(controller),
                _buildPoliciesTab(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityTab(TrustCenterController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Score Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF005156), Color(0xFF006B5D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Pontuação de Segurança',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: controller.securityScore / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        color: const Color(0xFFFFB000),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${controller.securityScore.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '/100',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _getSecurityScoreDescription(controller.securityScore),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Security Features
          const Text(
            'Recursos de Segurança',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005156),
            ),
          ),
          const SizedBox(height: 16),

          ...controller.securityFeatures.map((feature) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: feature.isActive
                      ? Colors.green
                      : Colors.grey,
                  child: Icon(
                    feature.isActive ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  feature.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(feature.description),
                trailing: feature.isActive
                    ? const Icon(Icons.verified, color: Colors.green)
                    : null,
                onTap: () => _showSecurityFeatureDetails(feature, controller),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Security Audits
          const Text(
            'Auditorias de Segurança',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005156),
            ),
          ),
          const SizedBox(height: 16),

          ...controller.securityAudits.map((audit) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF005156),
                  child: Icon(Icons.security, color: Colors.white, size: 20),
                ),
                title: Text(
                  audit.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(audit.description),
                    const SizedBox(height: 4),
                    Text(
                      'Última auditoria: ${_formatDate(audit.lastAuditDate)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                trailing: TrustBadge(
                  type: 'security',
                  level: audit.status,
                  size: 24,
                ),
                onTap: () => _showAuditDetails(audit, controller),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Report Security Issue
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.report_problem, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Encontrou um problema de segurança?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ajude-nos a manter o app seguro reportando vulnerabilidades.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showSecurityReportDialog(controller),
                  icon: const Icon(Icons.report),
                  label: const Text('Reportar Problema'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsTab(TrustCenterController controller) {
    return RefreshIndicator(
      onRefresh: controller.loadCertifications,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nossas Certificações',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005156),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Certificações que garantem a qualidade e segurança do SingleClin.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            if (controller.certifications.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.verified, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Certificações em processo',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...controller.certifications.map((cert) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TrustBadge(
                              type: cert.type,
                              level: cert.status,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cert.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    cert.issuer,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cert.isValid ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                cert.isValid ? 'VÁLIDA' : 'EXPIRADA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cert.description,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.date_range,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Emitida: ${_formatDate(cert.issuedDate)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.event,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Válida até: ${_formatDate(cert.expiryDate)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () =>
                                controller.viewCertificate(cert.certificateUrl),
                            icon: const Icon(Icons.download),
                            label: const Text('Ver Certificado'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005156),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyTab(TrustCenterController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LGPD Compliance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified_user, size: 48, color: Colors.green),
                const SizedBox(height: 12),
                const Text(
                  'Conformidade LGPD',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Estamos em total conformidade com a Lei Geral de Proteção de Dados.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showLgpdDetails(controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Saiba Mais'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Data Usage
          const Text(
            'Como Usamos Seus Dados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005156),
            ),
          ),
          const SizedBox(height: 16),

          ...controller.dataUsageCategories.map((category) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                leading: Icon(category.icon, color: const Color(0xFF005156)),
                title: Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(category.purpose),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tipos de dados coletados:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...category.dataTypes.map((type) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.fiber_manual_record,
                                  size: 8,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    type,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        Text(
                          'Período de retenção: ${category.retentionPeriod}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // User Rights
          const Text(
            'Seus Direitos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005156),
            ),
          ),
          const SizedBox(height: 16),

          ...controller.userRights.map((right) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF005156),
                  child: Icon(right.icon, color: Colors.white, size: 20),
                ),
                title: Text(
                  right.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(right.description),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showUserRightDetails(right, controller),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Data Portability
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.download, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Exportar Seus Dados',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Você pode solicitar uma cópia de todos os seus dados pessoais.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => controller.requestDataExport(),
                  icon: const Icon(Icons.file_download),
                  label: const Text('Solicitar Exportação'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesTab(TrustCenterController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.policies.length,
      itemBuilder: (context, index) {
        final policy = controller.policies[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF005156),
              child: Icon(policy.icon, color: Colors.white, size: 20),
            ),
            title: Text(
              policy.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(policy.description),
                const SizedBox(height: 4),
                Text(
                  'Última atualização: ${_formatDate(policy.lastUpdated)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showPolicyDetails(policy, controller),
          ),
        );
      },
    );
  }

  String _getSecurityScoreDescription(double score) {
    if (score >= 90) return 'Excelente segurança';
    if (score >= 80) return 'Boa segurança';
    if (score >= 70) return 'Segurança adequada';
    if (score >= 60) return 'Segurança básica';
    return 'Melhorias necessárias';
  }

  void _showSecurityFeatureDetails(
    dynamic feature,
    TrustCenterController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text(feature.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feature.description),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  feature.isActive ? Icons.check_circle : Icons.cancel,
                  color: feature.isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  feature.isActive ? 'Ativo' : 'Inativo',
                  style: TextStyle(
                    color: feature.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [TextButton(onPressed: Get.back, child: const Text('Fechar'))],
      ),
    );
  }

  void _showAuditDetails(dynamic audit, TrustCenterController controller) {
    Get.dialog(
      AlertDialog(
        title: Text(audit.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(audit.description),
            const SizedBox(height: 12),
            Text('Status: ${audit.status}'),
            Text('Última auditoria: ${_formatDate(audit.lastAuditDate)}'),
            if (audit.nextAuditDate != null)
              Text('Próxima auditoria: ${_formatDate(audit.nextAuditDate!)}'),
          ],
        ),
        actions: [TextButton(onPressed: Get.back, child: const Text('Fechar'))],
      ),
    );
  }

  void _showSecurityReportDialog(TrustCenterController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Reportar Problema de Segurança'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller.securityReportController,
              decoration: const InputDecoration(
                labelText: 'Descreva o problema',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            const Text(
              'Seus dados de contato serão incluídos para que possamos entrar em contato.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              controller.submitSecurityReport();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _showLgpdDetails(TrustCenterController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Conformidade LGPD'),
        content: const SingleChildScrollView(
          child: Text(
            'O SingleClin está em total conformidade com a Lei Geral de Proteção de Dados (LGPD). '
            'Implementamos medidas técnicas e organizacionais para garantir a proteção dos seus dados pessoais, '
            'incluindo criptografia, controle de acesso, auditorias regulares e treinamento de equipe.\n\n'
            'Você tem o direito de acessar, corrigir, excluir e portar seus dados, além de poder revogar '
            'seu consentimento a qualquer momento.',
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Fechar')),
          ElevatedButton(
            onPressed: () => controller.openLgpdPolicy(),
            child: const Text('Ler Política Completa'),
          ),
        ],
      ),
    );
  }

  void _showUserRightDetails(dynamic right, TrustCenterController controller) {
    Get.dialog(
      AlertDialog(
        title: Text(right.title),
        content: Text(right.description),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Fechar')),
          if (right.actionable)
            ElevatedButton(
              onPressed: () {
                Get.back();
                controller.exerciseUserRight(right.type);
              },
              child: const Text('Exercer Direito'),
            ),
        ],
      ),
    );
  }

  void _showPolicyDetails(dynamic policy, TrustCenterController controller) {
    Get.dialog(
      AlertDialog(
        title: Text(policy.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(policy.description),
            const SizedBox(height: 12),
            Text('Última atualização: ${_formatDate(policy.lastUpdated)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Fechar')),
          ElevatedButton(
            onPressed: () => controller.openPolicy(policy.id),
            child: const Text('Ler Completa'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
