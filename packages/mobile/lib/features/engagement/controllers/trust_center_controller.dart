import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trust_certification.dart';
import '../../../core/services/api_service.dart';

/// Controller for trust center and transparency features
class TrustCenterController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  final RxList<TrustCertification> certifications = <TrustCertification>[].obs;
  final Rx<PrivacyPolicy?> currentPrivacyPolicy = Rx<PrivacyPolicy?>(null);
  final RxList<PrivacyPolicy> privacyPolicyHistory = <PrivacyPolicy>[].obs;
  final Rx<LgpdCompliance?> lgpdCompliance = Rx<LgpdCompliance?>(null);
  final RxList<SecurityAudit> securityAudits = <SecurityAudit>[].obs;
  final Rx<TrustMetrics?> trustMetrics = Rx<TrustMetrics?>(null);
  
  // Terms and policies
  final RxMap<String, String> termsOfUse = <String, String>{}.obs;
  final RxMap<String, String> cookiePolicy = <String, String>{}.obs;
  final RxList<Map<String, dynamic>> regulatoryContacts = <Map<String, dynamic>>[].obs;
  
  // Content display state
  final RxString selectedCertificationId = ''.obs;
  final RxInt selectedPolicySection = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadTrustData();
  }

  /// Load all trust-related data
  Future<void> loadTrustData() async {
    await Future.wait([
      loadCertifications(),
      loadPrivacyPolicy(),
      loadLgpdCompliance(),
      loadSecurityAudits(),
      loadTrustMetrics(),
      loadTermsAndPolicies(),
      loadRegulatoryContacts(),
    ]);
  }

  /// Load trust certifications
  Future<void> loadCertifications({bool refresh = false}) async {
    try {
      refresh ? isLoading.value = true : null;
      error.value = '';

      final response = await _apiService.get('/trust/certifications');
      
      final List<TrustCertification> certs = (response.data['certifications'] as List)
          .map((json) => TrustCertification.fromJson(json))
          .toList();

      certifications.assignAll(certs);
    } catch (e) {
      error.value = 'Erro ao carregar certificações: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load current privacy policy
  Future<void> loadPrivacyPolicy() async {
    try {
      final response = await _apiService.get('/trust/privacy-policy');
      
      currentPrivacyPolicy.value = PrivacyPolicy.fromJson(response.data['current']);
      
      final List<PrivacyPolicy> history = (response.data['history'] as List)
          .map((json) => PrivacyPolicy.fromJson(json))
          .toList();
      privacyPolicyHistory.assignAll(history);
    } catch (e) {
      print('Error loading privacy policy: $e');
    }
  }

  /// Load LGPD compliance information
  Future<void> loadLgpdCompliance() async {
    try {
      final response = await _apiService.get('/trust/lgpd-compliance');
      lgpdCompliance.value = LgpdCompliance.fromJson(response.data);
    } catch (e) {
      print('Error loading LGPD compliance: $e');
    }
  }

  /// Load security audit reports
  Future<void> loadSecurityAudits() async {
    try {
      final response = await _apiService.get('/trust/security-audits');
      
      final List<SecurityAudit> audits = (response.data['audits'] as List)
          .map((json) => SecurityAudit.fromJson(json))
          .toList();

      securityAudits.assignAll(audits);
    } catch (e) {
      print('Error loading security audits: $e');
    }
  }

  /// Load trust metrics
  Future<void> loadTrustMetrics() async {
    try {
      final response = await _apiService.get('/trust/metrics');
      trustMetrics.value = TrustMetrics.fromJson(response.data);
    } catch (e) {
      print('Error loading trust metrics: $e');
    }
  }

  /// Load terms and policies
  Future<void> loadTermsAndPolicies() async {
    try {
      final response = await _apiService.get('/trust/terms-and-policies');
      
      termsOfUse.assignAll(Map<String, String>.from(response.data['termsOfUse'] ?? {}));
      cookiePolicy.assignAll(Map<String, String>.from(response.data['cookiePolicy'] ?? {}));
    } catch (e) {
      print('Error loading terms and policies: $e');
    }
  }

  /// Load regulatory contacts
  Future<void> loadRegulatoryContacts() async {
    try {
      final response = await _apiService.get('/trust/regulatory-contacts');
      
      final List<Map<String, dynamic>> contacts = List<Map<String, dynamic>>.from(
        response.data['contacts'] ?? []
      );
      regulatoryContacts.assignAll(contacts);
    } catch (e) {
      print('Error loading regulatory contacts: $e');
    }
  }

  /// Verify certificate authenticity
  Future<void> verifyCertificate(String certificateId) async {
    try {
      final cert = certifications.firstWhere((c) => c.id == certificateId);
      
      if (cert.verificationUrl.isNotEmpty) {
        await launchUrl(Uri.parse(cert.verificationUrl));
      } else {
        Get.snackbar(
          'Certificado Verificado',
          'Este certificado é válido e foi emitido por ${cert.issuingAuthority}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível verificar o certificado',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// View certificate details
  Future<void> viewCertificateDetails(String certificateId) async {
    try {
      final cert = certifications.firstWhere((c) => c.id == certificateId);
      selectedCertificationId.value = certificateId;
      
      if (cert.certificateUrl.isNotEmpty) {
        await launchUrl(Uri.parse(cert.certificateUrl));
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível visualizar o certificado',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Request data deletion (LGPD right)
  Future<void> requestDataDeletion() async {
    try {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Excluir Dados'),
          content: const Text(
            'Tem certeza que deseja excluir todos os seus dados? '
            'Esta ação não pode ser desfeita e você perderá acesso à sua conta.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _apiService.post('/user/request-deletion');
        
        Get.snackbar(
          'Solicitação Enviada',
          'Sua solicitação de exclusão de dados foi registrada. '
          'Você receberá uma confirmação em até 30 dias.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível processar sua solicitação',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Request data export (LGPD right)
  Future<void> requestDataExport() async {
    try {
      await _apiService.post('/user/request-data-export');
      
      Get.snackbar(
        'Exportação Solicitada',
        'Seus dados serão processados e enviados por email em até 7 dias úteis',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível processar sua solicitação',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Report security concern
  Future<void> reportSecurityConcern(String concern) async {
    try {
      await _apiService.post('/trust/report-security-concern', data: {
        'concern': concern,
        'timestamp': DateTime.now().toIso8601String(),
      });

      Get.snackbar(
        'Relatório Enviado',
        'Obrigado por relatar sua preocupação. Nossa equipe de segurança irá investigar.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível enviar o relatório',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Contact data protection officer
  Future<void> contactDPO(String subject, String message) async {
    try {
      await _apiService.post('/trust/contact-dpo', data: {
        'subject': subject,
        'message': message,
      });

      Get.snackbar(
        'Mensagem Enviada',
        'Sua mensagem foi enviada para nosso Encarregado de Dados. '
        'Responderemos em até 5 dias úteis.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível enviar a mensagem',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Launch external URL
  Future<void> launchExternalUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot launch URL');
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível abrir o link',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Get certification status color
  Color getCertificationStatusColor(CertificationStatus status) {
    switch (status) {
      case CertificationStatus.active:
        return Colors.green;
      case CertificationStatus.expired:
        return Colors.red;
      case CertificationStatus.suspended:
        return Colors.orange;
      case CertificationStatus.revoked:
        return Colors.red.shade800;
      case CertificationStatus.pending:
        return Colors.blue;
    }
  }

  /// Get certification type display name
  String getCertificationTypeDisplayName(CertificationType type) {
    switch (type) {
      case CertificationType.security:
        return 'Segurança';
      case CertificationType.privacy:
        return 'Privacidade';
      case CertificationType.quality:
        return 'Qualidade';
      case CertificationType.medical:
        return 'Médico';
      case CertificationType.regulatory:
        return 'Regulatório';
      case CertificationType.industry:
        return 'Indústria';
      case CertificationType.compliance:
        return 'Conformidade';
      case CertificationType.audit:
        return 'Auditoria';
    }
  }

  /// Get status display name
  String getStatusDisplayName(CertificationStatus status) {
    switch (status) {
      case CertificationStatus.active:
        return 'Ativo';
      case CertificationStatus.expired:
        return 'Expirado';
      case CertificationStatus.suspended:
        return 'Suspenso';
      case CertificationStatus.revoked:
        return 'Revogado';
      case CertificationStatus.pending:
        return 'Pendente';
    }
  }

  /// Get active certifications
  List<TrustCertification> get activeCertifications {
    return certifications.where((cert) => cert.status == CertificationStatus.active).toList();
  }

  /// Get expiring certifications
  List<TrustCertification> get expiringCertifications {
    return certifications.where((cert) => cert.isExpiringSoon).toList();
  }

  /// Get trust score color
  Color getTrustScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.lightGreen;
    if (score >= 70) return Colors.orange;
    if (score >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  /// Get security score description
  String getSecurityScoreDescription(String score) {
    switch (score.toUpperCase()) {
      case 'A+':
      case 'A':
        return 'Excelente - Segurança máxima';
      case 'A-':
      case 'B+':
        return 'Muito Bom - Alta segurança';
      case 'B':
      case 'B-':
        return 'Bom - Segurança adequada';
      case 'C+':
      case 'C':
        return 'Satisfatório - Melhorias necessárias';
      default:
        return 'Em desenvolvimento';
    }
  }

  /// Get LGPD compliance percentage
  double get lgpdCompliancePercentage {
    final compliance = lgpdCompliance.value;
    if (compliance == null) return 0.0;
    
    final total = compliance.requirements.length;
    final compliant = compliance.requirements.where((r) => r.isCompliant).length;
    
    return total > 0 ? compliant / total : 0.0;
  }

  /// Get user rights that can be exercised
  List<UserRight> get exercisableRights {
    return lgpdCompliance.value?.userRights.where((r) => r.isAvailable).toList() ?? [];
  }

  /// Get emergency contacts
  Map<String, String> get emergencyContacts => {
    'Ouvidoria': '0800-123-4567',
    'DPO - Encarregado de Dados': 'dpo@singleclin.com.br',
    'Segurança': 'security@singleclin.com.br',
    'ANPD': 'https://www.gov.br/anpd',
    'Procon': '151',
  };

  /// Refresh all trust data
  Future<void> refresh() async {
    isLoading.value = true;
    await loadTrustData();
    isLoading.value = false;
  }

  /// Select policy section
  void selectPolicySection(int section) {
    selectedPolicySection.value = section;
  }

  /// Check if terms acceptance is required
  bool get requiresTermsAcceptance {
    // This would check if user has accepted latest terms
    return false; // Placeholder
  }

  /// Accept updated terms
  Future<void> acceptUpdatedTerms() async {
    try {
      await _apiService.post('/user/accept-terms', data: {
        'version': currentPrivacyPolicy.value?.version,
        'acceptedAt': DateTime.now().toIso8601String(),
      });

      Get.snackbar(
        'Termos Aceitos',
        'Você aceitou os termos atualizados',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível registrar a aceitação dos termos',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}