import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:singleclin_mobile/features/engagement/models/review.dart';
import 'package:singleclin_mobile/core/services/api_service.dart';
import 'package:singleclin_mobile/features/credits/controllers/credits_controller.dart';

/// Controller for writing and submitting reviews
class WriteReviewController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final CreditsController _creditsController = Get.find<CreditsController>();

  // Form controllers
  final titleController = TextEditingController();
  final commentController = TextEditingController();

  // Observable state
  final RxBool isSubmitting = false.obs;
  final RxInt currentStep = 0.obs;
  final RxString error = ''.obs;

  // Rating values
  final RxDouble overallRating = 5.0.obs;
  final RxDouble serviceRating = 5.0.obs;
  final RxDouble cleanlinessRating = 5.0.obs;
  final RxDouble staffRating = 5.0.obs;
  final RxDouble valueRating = 5.0.obs;

  // Review options
  final RxBool isRecommended = true.obs;
  final RxBool wouldReturn = true.obs;
  final RxList<String> selectedTags = <String>[].obs;

  // Photo management
  final RxList<File> beforePhotos = <File>[].obs;
  final RxList<File> afterPhotos = <File>[].obs;
  final RxBool isUploadingPhotos = false.obs;

  // Appointment and clinic info
  String appointmentId = '';
  String clinicId = '';
  String clinicName = '';
  String serviceId = '';
  String serviceName = '';

  @override
  void onInit() {
    super.onInit();
    // Initialize with appointment data if provided
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      appointmentId = args['appointmentId'] ?? '';
      clinicId = args['clinicId'] ?? '';
      clinicName = args['clinicName'] ?? '';
      serviceId = args['serviceId'] ?? '';
      serviceName = args['serviceName'] ?? '';
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    commentController.dispose();
    super.onClose();
  }

  /// Move to next step
  void nextStep() {
    if (currentStep.value < 4) {
      currentStep.value++;
    }
  }

  /// Move to previous step
  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  /// Go to specific step
  void goToStep(int step) {
    currentStep.value = step;
  }

  /// Update overall rating
  void updateOverallRating(double rating) {
    overallRating.value = rating;
  }

  /// Update service rating
  void updateServiceRating(double rating) {
    serviceRating.value = rating;
  }

  /// Update cleanliness rating
  void updateCleanlinessRating(double rating) {
    cleanlinessRating.value = rating;
  }

  /// Update staff rating
  void updateStaffRating(double rating) {
    staffRating.value = rating;
  }

  /// Update value rating
  void updateValueRating(double rating) {
    valueRating.value = rating;
  }

  /// Toggle recommendation
  void toggleRecommendation() {
    isRecommended.value = !isRecommended.value;
  }

  /// Toggle would return
  void toggleWouldReturn() {
    wouldReturn.value = !wouldReturn.value;
  }

  /// Toggle tag selection
  void toggleTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
  }

  /// Pick before photos
  Future<void> pickBeforePhotos() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isNotEmpty && beforePhotos.length + images.length <= 5) {
        for (final image in images) {
          final compressedFile = await compressImage(File(image.path));
          if (compressedFile != null) {
            beforePhotos.add(compressedFile);
          }
        }
      } else if (beforePhotos.length + images.length > 5) {
        Get.snackbar(
          'Limite de fotos',
          'Você pode adicionar no máximo 5 fotos antes',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível adicionar as fotos',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Pick after photos
  Future<void> pickAfterPhotos() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isNotEmpty && afterPhotos.length + images.length <= 5) {
        for (final image in images) {
          final compressedFile = await compressImage(File(image.path));
          if (compressedFile != null) {
            afterPhotos.add(compressedFile);
          }
        }
      } else if (afterPhotos.length + images.length > 5) {
        Get.snackbar(
          'Limite de fotos',
          'Você pode adicionar no máximo 5 fotos depois',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível adicionar as fotos',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Compress image to reduce file size
  Future<File?> compressImage(File file) async {
    try {
      final String targetPath = file.path.replaceAll('.jpg', '_compressed.jpg');

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            targetPath,
            quality: 70,
            minWidth: 800,
            minHeight: 600,
          );

      return compressedFile != null ? File(compressedFile.path) : null;
    } catch (e) {
      return file; // Return original if compression fails
    }
  }

  /// Remove before photo
  void removeBeforePhoto(int index) {
    if (index < beforePhotos.length) {
      beforePhotos.removeAt(index);
    }
  }

  /// Remove after photo
  void removeAfterPhoto(int index) {
    if (index < afterPhotos.length) {
      afterPhotos.removeAt(index);
    }
  }

  /// Submit review
  Future<void> submitReview() async {
    if (!validateForm()) return;

    try {
      isSubmitting.value = true;
      error.value = '';

      // Upload photos first
      final List<String> beforePhotoUrls = await uploadPhotos(
        beforePhotos.toList(),
        'before',
      );
      final List<String> afterPhotoUrls = await uploadPhotos(
        afterPhotos.toList(),
        'after',
      );

      // Prepare review data
      final reviewData = {
        'appointmentId': appointmentId,
        'clinicId': clinicId,
        'serviceId': serviceId,
        'overallRating': overallRating.value,
        'serviceRating': serviceRating.value,
        'cleanlinessRating': cleanlinessRating.value,
        'staffRating': staffRating.value,
        'valueRating': valueRating.value,
        'title': titleController.text.trim(),
        'comment': commentController.text.trim(),
        'tags': selectedTags.toList(),
        'beforePhotos': beforePhotoUrls,
        'afterPhotos': afterPhotoUrls,
        'isRecommended': isRecommended.value,
        'wouldReturn': wouldReturn.value,
      };

      // Submit review
      final response = await _apiService.post(
        '/user/reviews',
        data: reviewData,
      );

      // Award SG credits for review
      await _creditsController.awardCreditsForReview(
        reviewId: response.data['reviewId'],
        hasPhotos: beforePhotos.isNotEmpty || afterPhotos.isNotEmpty,
      );

      Get.snackbar(
        'Avaliação enviada!',
        'Obrigado por compartilhar sua experiência. Você ganhou +5 SG!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate back or to success screen
      Get.back(result: true);
    } catch (e) {
      error.value = 'Erro ao enviar avaliação: ${e.toString()}';
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

  /// Upload photos to server
  Future<List<String>> uploadPhotos(List<File> photos, String type) async {
    if (photos.isEmpty) return [];

    try {
      isUploadingPhotos.value = true;
      final List<String> uploadedUrls = [];

      for (final photo in photos) {
        final response = await _apiService.uploadFile(
          '/upload/review-photo',
          photo,
          fileField: 'photo',
          data: {'type': type, 'appointmentId': appointmentId},
        );

        uploadedUrls.add(response.data['url']);
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Erro ao fazer upload das fotos: $e');
    } finally {
      isUploadingPhotos.value = false;
    }
  }

  /// Validate form data
  bool validateForm() {
    if (titleController.text.trim().isEmpty) {
      error.value = 'Por favor, adicione um título para sua avaliação';
      return false;
    }

    if (commentController.text.trim().length < 20) {
      error.value = 'O comentário deve ter pelo menos 20 caracteres';
      return false;
    }

    if (overallRating.value < 1.0) {
      error.value = 'Por favor, adicione uma avaliação geral';
      return false;
    }

    return true;
  }

  /// Get available tags for selection
  List<String> get availableTags => [
    'Excelente atendimento',
    'Profissional qualificado',
    'Ambiente limpo',
    'Resultado superou expectativas',
    'Preço justo',
    'Recomendo',
    'Voltaria novamente',
    'Pontualidade',
    'Equipamentos modernos',
    'Explicação clara',
    'Pós-atendimento',
    'Localização conveniente',
  ];

  /// Get review templates for suggestions
  List<String> get reviewTemplates => [
    'Excelente experiência na $clinicName! O atendimento foi impecável e o resultado superou minhas expectativas.',
    'Profissional muito qualificado e atencioso. O ambiente é limpo e moderno. Recomendo!',
    'Fiquei muito satisfeito(a) com o serviço de $serviceName. Equipe competente e resultado excelente.',
    'Atendimento de qualidade, preço justo e resultado fantástico. Voltaria com certeza!',
  ];

  /// Apply review template
  void applyTemplate(String template) {
    commentController.text = template;
  }

  /// Get current step title
  String get currentStepTitle {
    switch (currentStep.value) {
      case 0:
        return 'Avaliação Geral';
      case 1:
        return 'Avaliação Detalhada';
      case 2:
        return 'Adicionar Fotos';
      case 3:
        return 'Comentário';
      case 4:
        return 'Finalizar';
      default:
        return 'Avaliação';
    }
  }

  /// Get progress percentage
  double get progressPercentage {
    return (currentStep.value + 1) / 5;
  }

  /// Check if current step is valid
  bool get isCurrentStepValid {
    switch (currentStep.value) {
      case 0:
        return overallRating.value > 0;
      case 1:
        return serviceRating.value > 0 &&
            cleanlinessRating.value > 0 &&
            staffRating.value > 0 &&
            valueRating.value > 0;
      case 2:
        return true; // Photos are optional
      case 3:
        return titleController.text.trim().isNotEmpty &&
            commentController.text.trim().length >= 20;
      case 4:
        return true; // Final review
      default:
        return false;
    }
  }
}
