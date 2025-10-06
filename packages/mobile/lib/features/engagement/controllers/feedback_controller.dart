import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:singleclin_mobile/core/services/api_service.dart';
import 'package:singleclin_mobile/features/credits/controllers/credits_controller.dart';
import 'package:singleclin_mobile/features/engagement/models/feedback_report.dart';

/// Controller for app feedback and improvement suggestions
class FeedbackController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final CreditsController _creditsController = Get.find<CreditsController>();

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxString error = ''.obs;

  final RxList<FeedbackReport> myReports = <FeedbackReport>[].obs;
  final RxList<FeatureRequest> featureRequests = <FeatureRequest>[].obs;
  final RxList<RoadmapItem> roadmapItems = <RoadmapItem>[].obs;
  final RxList<BetaProgram> betaPrograms = <BetaProgram>[].obs;

  // Form state
  final Rx<FeedbackType> selectedType = FeedbackType.suggestion.obs;
  final Rx<FeedbackCategory> selectedCategory = FeedbackCategory.general.obs;
  final Rx<FeedbackPriority> selectedPriority = FeedbackPriority.medium.obs;
  final RxList<File> screenshots = <File>[].obs;

  // Device and app info
  final Rx<Map<String, dynamic>> deviceInfo = Rx<Map<String, dynamic>>({});
  String appVersion = '';
  String osVersion = '';

  @override
  void onInit() {
    super.onInit();
    _collectDeviceInfo();
    loadMyReports();
    loadFeatureRequests();
    loadRoadmap();
    loadBetaPrograms();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// Load user's feedback reports
  Future<void> loadMyReports({bool refresh = false}) async {
    try {
      refresh ? isLoading.value = true : null;
      error.value = '';

      final response = await _apiService.get('/user/feedback');

      final List<FeedbackReport> reports = (response.data['reports'] as List)
          .map((json) => FeedbackReport.fromJson(json))
          .toList();

      myReports.assignAll(reports);
    } catch (e) {
      error.value = 'Erro ao carregar feedbacks: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load feature requests for voting
  Future<void> loadFeatureRequests() async {
    try {
      final response = await _apiService.get(
        '/feedback/feature-requests',
        queryParameters: {'status': 'open', 'sort': 'votes', 'limit': 50},
      );

      final List<FeatureRequest> requests = (response.data['requests'] as List)
          .map((json) => FeatureRequest.fromJson(json))
          .toList();

      featureRequests.assignAll(requests);
    } catch (e) {
      print('Error loading feature requests: $e');
    }
  }

  /// Load public roadmap
  Future<void> loadRoadmap() async {
    try {
      final response = await _apiService.get('/feedback/roadmap');

      final List<RoadmapItem> items = (response.data['items'] as List)
          .map((json) => RoadmapItem.fromJson(json))
          .toList();

      roadmapItems.assignAll(items);
    } catch (e) {
      print('Error loading roadmap: $e');
    }
  }

  /// Load beta programs
  Future<void> loadBetaPrograms() async {
    try {
      final response = await _apiService.get('/feedback/beta-programs');

      final List<BetaProgram> programs = (response.data['programs'] as List)
          .map((json) => BetaProgram.fromJson(json))
          .toList();

      betaPrograms.assignAll(programs);
    } catch (e) {
      print('Error loading beta programs: $e');
    }
  }

  /// Submit feedback report
  Future<void> submitFeedback() async {
    if (!validateForm()) return;

    try {
      isSubmitting.value = true;
      error.value = '';

      // Upload screenshots if any
      final List<String> screenshotUrls = await uploadScreenshots();

      final feedbackData = {
        'type': selectedType.value.name,
        'category': selectedCategory.value.name,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'priority': selectedPriority.value.name,
        'screenshots': screenshotUrls,
        'deviceInfo': deviceInfo.value,
        'appVersion': appVersion,
        'osVersion': osVersion,
      };

      final response = await _apiService.post(
        '/user/feedback',
        data: feedbackData,
      );

      final newReport = FeedbackReport.fromJson(response.data['report']);
      myReports.insert(0, newReport);

      // Award SG credits for valuable feedback
      if (selectedType.value == FeedbackType.bugReport ||
          selectedType.value == FeedbackType.featureRequest) {
        await _creditsController.awardCreditsForFeedback(newReport.id);
      }

      // Clear form
      clearForm();

      Get.snackbar(
        'Feedback enviado!',
        'Obrigado por nos ajudar a melhorar o app${_shouldAwardCredits() ? ". +3 SG!" : ""}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.back();
    } catch (e) {
      error.value = 'Erro ao enviar feedback: ${e.toString()}';
      Get.snackbar(
        'Erro',
        error.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Vote on feature request
  Future<void> voteOnFeatureRequest(String requestId) async {
    try {
      final requestIndex = featureRequests.indexWhere((r) => r.id == requestId);
      if (requestIndex == -1) return;

      final request = featureRequests[requestIndex];
      final isCurrentlyVoted = request.hasVoted;

      // Optimistic update
      final updatedRequest = request.copyWith(
        hasVoted: !isCurrentlyVoted,
        votesCount: isCurrentlyVoted
            ? request.votesCount - 1
            : request.votesCount + 1,
      );
      featureRequests[requestIndex] = updatedRequest;

      // API call
      await _apiService.post('/feedback/feature-requests/$requestId/vote');

      Get.snackbar(
        isCurrentlyVoted ? 'Voto removido' : 'Voto registrado!',
        isCurrentlyVoted
            ? 'Seu voto foi removido'
            : 'Obrigado por votar nesta funcionalidade',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // Revert on error
      loadFeatureRequests();
      Get.snackbar(
        'Erro',
        'Não foi possível registrar seu voto',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Vote on roadmap item
  Future<void> voteOnRoadmapItem(String itemId) async {
    try {
      final itemIndex = roadmapItems.indexWhere((r) => r.id == itemId);
      if (itemIndex == -1) return;

      final item = roadmapItems[itemIndex];
      final isCurrentlyVoted = item.hasVoted;

      // Optimistic update
      final updatedItem = item.copyWith(
        hasVoted: !isCurrentlyVoted,
        userVotes: isCurrentlyVoted ? item.userVotes - 1 : item.userVotes + 1,
      );
      roadmapItems[itemIndex] = updatedItem;

      // API call
      await _apiService.post('/feedback/roadmap/$itemId/vote');
    } catch (e) {
      // Revert on error
      loadRoadmap();
      Get.snackbar(
        'Erro',
        'Não foi possível registrar seu voto',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Join beta program
  Future<void> joinBetaProgram(String programId) async {
    try {
      await _apiService.post('/feedback/beta-programs/$programId/join');

      final programIndex = betaPrograms.indexWhere((p) => p.id == programId);
      if (programIndex != -1) {
        final program = betaPrograms[programIndex];
        final updatedProgram = program.copyWith(
          isEnrolled: true,
          currentParticipants: program.currentParticipants + 1,
        );
        betaPrograms[programIndex] = updatedProgram;
      }

      Get.snackbar(
        'Inscrição confirmada!',
        'Você foi inscrito no programa beta',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível se inscrever no programa beta',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Leave beta program
  Future<void> leaveBetaProgram(String programId) async {
    try {
      await _apiService.post('/feedback/beta-programs/$programId/leave');

      final programIndex = betaPrograms.indexWhere((p) => p.id == programId);
      if (programIndex != -1) {
        final program = betaPrograms[programIndex];
        final updatedProgram = program.copyWith(
          isEnrolled: false,
          currentParticipants: program.currentParticipants - 1,
        );
        betaPrograms[programIndex] = updatedProgram;
      }

      Get.snackbar(
        'Inscrição cancelada',
        'Você saiu do programa beta',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível sair do programa beta',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Add screenshot
  Future<void> addScreenshot() async {
    if (screenshots.length >= 5) {
      Get.snackbar(
        'Limite atingido',
        'Você pode adicionar no máximo 5 capturas de tela',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        screenshots.add(File(image.path));
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível adicionar a captura de tela',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Take screenshot
  Future<void> takeScreenshot() async {
    if (screenshots.length >= 5) {
      Get.snackbar(
        'Limite atingido',
        'Você pode adicionar no máximo 5 capturas de tela',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        screenshots.add(File(image.path));
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível tirar a captura de tela',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Remove screenshot
  void removeScreenshot(int index) {
    if (index < screenshots.length) {
      screenshots.removeAt(index);
    }
  }

  /// Upload screenshots
  Future<List<String>> uploadScreenshots() async {
    if (screenshots.isEmpty) return [];

    try {
      final List<String> uploadedUrls = [];

      for (final screenshot in screenshots) {
        final response = await _apiService.uploadFile(
          '/upload/feedback-screenshot',
          screenshot,
          fileField: 'screenshot',
        );

        uploadedUrls.add(response.data['url']);
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Erro ao fazer upload das capturas de tela: $e');
    }
  }

  /// Collect device and app information
  Future<void> _collectDeviceInfo() async {
    try {
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();

      appVersion = packageInfo.version;

      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo =
            await deviceInfoPlugin.androidInfo;
        osVersion = 'Android ${androidInfo.version.release}';
        deviceInfo.value = {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'osVersion': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'display': androidInfo.display,
          'fingerprint': androidInfo.fingerprint,
          'hardware': androidInfo.hardware,
          'product': androidInfo.product,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        osVersion = 'iOS ${iosInfo.systemVersion}';
        deviceInfo.value = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'osVersion': iosInfo.systemVersion,
          'localizedModel': iosInfo.localizedModel,
          'systemName': iosInfo.systemName,
          'utsname': iosInfo.utsname.machine,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      }
    } catch (e) {
      print('Error collecting device info: $e');
    }
  }

  /// Validate form
  bool validateForm() {
    if (titleController.text.trim().isEmpty) {
      error.value = 'Por favor, adicione um título';
      return false;
    }

    if (descriptionController.text.trim().length < 10) {
      error.value = 'A descrição deve ter pelo menos 10 caracteres';
      return false;
    }

    return true;
  }

  /// Clear form
  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    screenshots.clear();
    selectedType.value = FeedbackType.suggestion;
    selectedCategory.value = FeedbackCategory.general;
    selectedPriority.value = FeedbackPriority.medium;
  }

  /// Check if should award credits
  bool _shouldAwardCredits() {
    return selectedType.value == FeedbackType.bugReport ||
        selectedType.value == FeedbackType.featureRequest;
  }

  /// Get type display name
  String getTypeDisplayName(FeedbackType type) {
    switch (type) {
      case FeedbackType.bugReport:
        return 'Reportar Bug';
      case FeedbackType.featureRequest:
        return 'Sugerir Funcionalidade';
      case FeedbackType.improvement:
        return 'Melhoria';
      case FeedbackType.suggestion:
        return 'Sugestão';
      case FeedbackType.compliment:
        return 'Elogio';
      case FeedbackType.complaint:
        return 'Reclamação';
    }
  }

  /// Get category display name
  String getCategoryDisplayName(FeedbackCategory category) {
    switch (category) {
      case FeedbackCategory.general:
        return 'Geral';
      case FeedbackCategory.ui:
        return 'Interface';
      case FeedbackCategory.performance:
        return 'Performance';
      case FeedbackCategory.functionality:
        return 'Funcionalidade';
      case FeedbackCategory.accessibility:
        return 'Acessibilidade';
      case FeedbackCategory.security:
        return 'Segurança';
      case FeedbackCategory.content:
        return 'Conteúdo';
      case FeedbackCategory.integration:
        return 'Integração';
    }
  }

  /// Get priority display name
  String getPriorityDisplayName(FeedbackPriority priority) {
    switch (priority) {
      case FeedbackPriority.low:
        return 'Baixa';
      case FeedbackPriority.medium:
        return 'Média';
      case FeedbackPriority.high:
        return 'Alta';
      case FeedbackPriority.critical:
        return 'Crítica';
    }
  }

  /// Get status display name
  String getStatusDisplayName(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.submitted:
        return 'Enviado';
      case FeedbackStatus.underReview:
        return 'Em Análise';
      case FeedbackStatus.inProgress:
        return 'Em Desenvolvimento';
      case FeedbackStatus.testing:
        return 'Em Teste';
      case FeedbackStatus.resolved:
        return 'Resolvido';
      case FeedbackStatus.rejected:
        return 'Rejeitado';
      case FeedbackStatus.archived:
        return 'Arquivado';
    }
  }

  /// Get roadmap status display name
  String getRoadmapStatusDisplayName(RoadmapStatus status) {
    switch (status) {
      case RoadmapStatus.planned:
        return 'Planejado';
      case RoadmapStatus.inProgress:
        return 'Em Desenvolvimento';
      case RoadmapStatus.testing:
        return 'Em Teste';
      case RoadmapStatus.released:
        return 'Lançado';
      case RoadmapStatus.cancelled:
        return 'Cancelado';
    }
  }

  /// Get available types
  List<FeedbackType> get availableTypes => FeedbackType.values;

  /// Get available categories
  List<FeedbackCategory> get availableCategories => FeedbackCategory.values;

  /// Get available priorities
  List<FeedbackPriority> get availablePriorities => FeedbackPriority.values;

  /// Get feedback templates
  List<Map<String, String>> get feedbackTemplates => [
    {
      'title': 'Bug na tela de login',
      'description':
          'Quando tento fazer login, o app trava e fecha automaticamente. Isso acontece sempre que...',
    },
    {
      'title': 'Sugestão: Filtros avançados',
      'description':
          'Seria muito útil ter filtros mais específicos na busca por clínicas, como distância, preços, especialidades...',
    },
    {
      'title': 'Melhoria no design',
      'description':
          'A tela principal poderia ter um design mais limpo e intuitivo. Sugiro...',
    },
    {
      'title': 'Problema com notificações',
      'description':
          'Não estou recebendo notificações de agendamentos confirmados. Já verifiquei as configurações e...',
    },
  ];

  /// Apply feedback template
  void applyTemplate(Map<String, String> template) {
    titleController.text = template['title'] ?? '';
    descriptionController.text = template['description'] ?? '';
  }

  /// Get user feedback statistics
  Map<String, int> get userFeedbackStats {
    final Map<String, int> stats = {};

    for (final report in myReports) {
      final status = getStatusDisplayName(report.status);
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }
}
