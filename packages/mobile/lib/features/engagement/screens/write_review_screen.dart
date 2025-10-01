import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/features/engagement/controllers/write_review_controller.dart';
import 'package:singleclin_mobile/features/engagement/widgets/rating_stars.dart';

class WriteReviewScreen extends StatelessWidget {
  const WriteReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WriteReviewController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Escrever Avaliação'),
            backgroundColor: const Color(0xFF005156),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step indicator
                LinearProgressIndicator(
                  value: (controller.currentStep + 1) / 4,
                  backgroundColor: Colors.grey[300],
                  color: const Color(0xFF005156),
                ),
                const SizedBox(height: 24),

                // Step content
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(controller),
                ),

                const SizedBox(height: 32),

                // Navigation buttons
                Row(
                  children: [
                    if (controller.currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.previousStep,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF005156)),
                            foregroundColor: const Color(0xFF005156),
                          ),
                          child: const Text('Voltar'),
                        ),
                      ),
                    if (controller.currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: controller.canProceed
                            ? (controller.currentStep == 3
                                  ? controller.submitReview
                                  : controller.nextStep)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005156),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: controller.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                controller.currentStep == 3
                                    ? 'Publicar Avaliação'
                                    : 'Continuar',
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(WriteReviewController controller) {
    switch (controller.currentStep) {
      case 0:
        return _buildRatingStep(controller);
      case 1:
        return _buildCommentStep(controller);
      case 2:
        return _buildPhotosStep(controller);
      case 3:
        return _buildReviewStep(controller);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRatingStep(WriteReviewController controller) {
    return Column(
      key: const ValueKey('rating-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Como você avalia sua experiência?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005156),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sua avaliação ajuda outros pacientes e a clínica a melhorar.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              RatingStarsInput(
                rating: controller.rating,
                onRatingChanged: controller.setRating,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                controller.getRatingDescription(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF005156),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentStep(WriteReviewController controller) {
    return Column(
      key: const ValueKey('comment-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conte-nos sobre sua experiência',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005156),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Compartilhe detalhes que possam ajudar outros pacientes.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller.commentController,
          maxLines: 6,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Descreva sua experiência... (opcional)',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF005156)),
            ),
          ),
          onChanged: (_) => controller.update(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Evite informações pessoais ou dados médicos específicos.',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosStep(WriteReviewController controller) {
    return Column(
      key: const ValueKey('photos-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adicionar fotos (opcional)',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005156),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Fotos ajudam a ilustrar sua experiência. Máximo de 3 fotos.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        // Photos grid
        if (controller.selectedPhotos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: controller.selectedPhotos.length,
            itemBuilder: (context, index) {
              final photo = controller.selectedPhotos[index];
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(photo),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => controller.removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        const SizedBox(height: 16),

        // Add photo buttons
        if (controller.selectedPhotos.length < 3)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.pickFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Câmera'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF005156)),
                    foregroundColor: const Color(0xFF005156),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeria'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF005156)),
                    foregroundColor: const Color(0xFF005156),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildReviewStep(WriteReviewController controller) {
    return Column(
      key: const ValueKey('review-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revisar avaliação',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005156),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Confirme os dados antes de publicar sua avaliação.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        // Review summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RatingStarsDisplay(rating: controller.rating.toDouble()),
                  const SizedBox(width: 8),
                  Text(
                    controller.getRatingDescription(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF005156),
                    ),
                  ),
                ],
              ),

              if (controller.commentController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  controller.commentController.text,
                  style: const TextStyle(fontSize: 16),
                ),
              ],

              if (controller.selectedPhotos.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${controller.selectedPhotos.length} foto(s) anexada(s)',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Terms agreement
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: controller.agreeToTerms,
              onChanged: controller.setAgreeToTerms,
              activeColor: const Color(0xFF005156),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    controller.setAgreeToTerms(!controller.agreeToTerms),
                child: const Text(
                  'Concordo com os termos de uso e confirmo que esta avaliação é baseada na minha experiência real.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
