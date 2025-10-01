import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/features/engagement/controllers/reviews_controller.dart';
import 'package:singleclin_mobile/features/engagement/widgets/review_card.dart';
import 'package:singleclin_mobile/features/engagement/widgets/rating_stars.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReviewsController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Avaliações'),
            backgroundColor: const Color(0xFF005156),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note),
                onPressed: () => Get.toNamed('/write-review'),
              ),
            ],
          ),
          body: Column(
            children: [
              // Rating Summary
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFF8F9FA),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${controller.averageRating.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF005156),
                            ),
                          ),
                          RatingStarsDisplay(
                            rating: controller.averageRating,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${controller.reviews.length} avaliações',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Get.toNamed('/write-review'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Avaliar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005156),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Todas'),
                        selected: controller.selectedRating == 0,
                        onSelected: (_) => controller.filterByRating(0),
                        backgroundColor: Colors.grey[200],
                        selectedColor: const Color(0xFF005156),
                        labelStyle: TextStyle(
                          color: controller.selectedRating == 0
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(5, (index) {
                        final rating = 5 - index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: controller.selectedRating == rating
                                      ? Colors.white
                                      : Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text('$rating'),
                              ],
                            ),
                            selected: controller.selectedRating == rating,
                            onSelected: (_) =>
                                controller.filterByRating(rating),
                            backgroundColor: Colors.grey[200],
                            selectedColor: const Color(0xFF005156),
                            labelStyle: TextStyle(
                              color: controller.selectedRating == rating
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Reviews List
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.filteredReviews.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_border,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma avaliação encontrada',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Seja o primeiro a avaliar!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: controller.loadReviews,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: controller.filteredReviews.length,
                          itemBuilder: (context, index) {
                            final review = controller.filteredReviews[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ReviewCard(
                                review: review,
                                onLike: () => controller.likeReview(review.id),
                                onDislike: () =>
                                    controller.dislikeReview(review.id),
                                onReport: () =>
                                    _showReportDialog(context, review.id),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportDialog(BuildContext context, String reviewId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Reportar Avaliação'),
        content: const Text(
          'Esta avaliação contém conteúdo inadequado ou viola nossas diretrizes?',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.find<ReviewsController>().reportReview(reviewId);
              Get.snackbar(
                'Obrigado!',
                'Sua denúncia foi recebida e será analisada.',
                backgroundColor: const Color(0xFF005156),
                colorText: Colors.white,
              );
            },
            child: const Text('Reportar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
