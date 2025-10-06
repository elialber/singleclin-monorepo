import 'package:flutter/material.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';
import 'package:singleclin_mobile/features/clinic_discovery/models/clinic.dart';

class ReviewsSection extends StatefulWidget {
  const ReviewsSection({required this.clinic, super.key});
  final Clinic clinic;

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  bool _showAllReviews = false;

  // Mock reviews data - in real implementation, this would come from API
  final List<Review> _mockReviews = [
    Review(
      id: '1',
      userName: 'Maria Silva',
      userAvatar: 'https://via.placeholder.com/40x40?text=MS',
      rating: 5,
      comment:
          'Excelente atendimento! Médicos muito qualificados e ambiente limpo.',
      date: DateTime.now().subtract(const Duration(days: 2)),
      helpful: 12,
    ),
    Review(
      id: '2',
      userName: 'João Santos',
      userAvatar: 'https://via.placeholder.com/40x40?text=JS',
      rating: 4,
      comment: 'Bom atendimento, mas a espera foi um pouco longa.',
      date: DateTime.now().subtract(const Duration(days: 5)),
      helpful: 8,
    ),
    Review(
      id: '3',
      userName: 'Ana Costa',
      userAvatar: 'https://via.placeholder.com/40x40?text=AC',
      rating: 5,
      comment: 'Profissionais muito atenciosos e diagnóstico preciso.',
      date: DateTime.now().subtract(const Duration(days: 8)),
      helpful: 15,
    ),
    Review(
      id: '4',
      userName: 'Pedro Oliveira',
      userAvatar: 'https://via.placeholder.com/40x40?text=PO',
      rating: 4,
      comment: 'Clínica bem organizada e moderna. Recomendo!',
      date: DateTime.now().subtract(const Duration(days: 12)),
      helpful: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final reviewsToShow = _showAllReviews
        ? _mockReviews
        : _mockReviews.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Avaliações e comentários',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_mockReviews.length} avaliações',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            // Add Review Button
            InkWell(
              onTap: _showAddReviewDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: AppColors.primary, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Avaliar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Rating Summary
        _buildRatingSummary(),

        const SizedBox(height: 20),

        // Reviews List
        Column(children: reviewsToShow.map(_buildReviewItem).toList()),

        // Show More/Less Button
        if (_mockReviews.length > 2) ...[
          const SizedBox(height: 16),
          Center(
            child: InkWell(
              onTap: () {
                setState(() {
                  _showAllReviews = !_showAllReviews;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _showAllReviews ? 'Ver menos' : 'Ver todas as avaliações',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Overall Rating
          Column(
            children: [
              Text(
                widget.clinic.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < widget.clinic.rating.floor()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber[600],
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_mockReviews.length} avaliações',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),

          const SizedBox(width: 24),

          // Rating Distribution
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final starCount = 5 - index;
                final percentage = _calculateRatingPercentage(starCount);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$starCount',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.star, color: Colors.amber[600], size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.amber[600]!,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${percentage.toInt()}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info and Rating
          Row(
            children: [
              // User Avatar
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(review.userAvatar),
                backgroundColor: Colors.grey[300],
                onBackgroundImageError: (_, __) {},
                child: review.userAvatar.isEmpty
                    ? Text(
                        review.userName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              // User Name and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _formatDate(review.date),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Rating Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber[600],
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Comment
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // Helpful Button
          InkWell(
            onTap: () => _toggleHelpful(review),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.thumb_up_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Útil (${review.helpful})',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateRatingPercentage(int starCount) {
    final count = _mockReviews.where((r) => r.rating == starCount).length;
    return (count / _mockReviews.length) * 100;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Hoje';
    } else if (difference == 1) {
      return 'Ontem';
    } else if (difference < 7) {
      return 'há $difference dias';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return 'há $weeks semana${weeks > 1 ? 's' : ''}';
    } else {
      final months = (difference / 30).floor();
      return 'há $months mês${months > 1 ? 'es' : ''}';
    }
  }

  void _toggleHelpful(Review review) {
    // TODO: Implement helpful toggle functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Obrigado pelo feedback!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddReviewDialog(clinic: widget.clinic),
    );
  }
}

class _AddReviewDialog extends StatefulWidget {
  const _AddReviewDialog({required this.clinic});
  final Clinic clinic;

  @override
  State<_AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<_AddReviewDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Avaliar ${widget.clinic.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Rating Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber[600],
                    size: 32,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Comment Field
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Compartilhe sua experiência...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _rating > 0 ? _submitReview : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Enviar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitReview() {
    // TODO: Submit review to API
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Avaliação enviada com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class Review {
  Review({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.date,
    required this.helpful,
  });
  final String id;
  final String userName;
  final String userAvatar;
  final int rating;
  final String comment;
  final DateTime date;
  final int helpful;
}
