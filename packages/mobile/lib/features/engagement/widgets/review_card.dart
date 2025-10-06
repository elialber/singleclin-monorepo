import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';
import 'package:singleclin_mobile/features/engagement/models/review.dart';
import 'package:singleclin_mobile/features/engagement/widgets/rating_stars.dart';

/// Card widget for displaying user reviews
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    required this.review,
    super.key,
    this.showClinicInfo = true,
    this.showServiceInfo = true,
    this.isCompact = false,
    this.onTap,
    this.onHelpfulVote,
    this.onReport,
    this.onDelete,
    this.canDelete = false,
  });
  final Review review;
  final bool showClinicInfo;
  final bool showServiceInfo;
  final bool isCompact;
  final VoidCallback? onTap;
  final Function(bool)? onHelpfulVote;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildRating(context),
              if (!isCompact) ...[
                const SizedBox(height: 8),
                _buildTitle(context),
                const SizedBox(height: 8),
                _buildContent(context),
                if (review.beforePhotos.isNotEmpty ||
                    review.afterPhotos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildPhotos(context),
                ],
                if (review.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildTags(context),
                ],
                const SizedBox(height: 12),
                _buildFooter(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Usuário verificado',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(review.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
              ),
            ],
          ),
        ),
        if (canDelete)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete' && onDelete != null) {
                _showDeleteConfirmation(context);
              } else if (value == 'report' && onReport != null) {
                onReport!();
              }
            },
            itemBuilder: (context) => [
              if (canDelete)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Excluir'),
                    ],
                  ),
                ),
              if (onReport != null)
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Denunciar'),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildRating(BuildContext context) {
    return Row(
      children: [
        RatingStars(rating: review.overallRating, size: 18),
        const SizedBox(width: 8),
        Text(
          review.overallRating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const Spacer(),
        if (review.isRecommended)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.thumb_up, size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'Recomenda',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      review.title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.darkGrey,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          review.comment,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.darkGrey,
            height: 1.4,
          ),
          maxLines: isCompact ? 2 : null,
          overflow: isCompact ? TextOverflow.ellipsis : null,
        ),
        if (showClinicInfo || showServiceInfo) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (showClinicInfo) ...[
                const Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppColors.mediumGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Clínica exemplo', // Would come from clinic data
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
                ),
              ],
              if (showClinicInfo && showServiceInfo)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 1,
                  height: 12,
                  color: AppColors.lightGrey,
                ),
              if (showServiceInfo) ...[
                const Icon(
                  Icons.medical_services,
                  size: 14,
                  color: AppColors.mediumGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Serviço exemplo', // Would come from service data
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPhotos(BuildContext context) {
    final allPhotos = [...review.beforePhotos, ...review.afterPhotos];
    if (allPhotos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (review.beforePhotos.isNotEmpty && review.afterPhotos.isNotEmpty)
          Text(
            'Antes e Depois',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allPhotos.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: allPhotos[index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.lightGrey,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.lightGrey,
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTags(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: review.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tag,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        // Helpful votes
        if (onHelpfulVote != null) ...[
          InkWell(
            onTap: () => onHelpfulVote!(true),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.thumb_up_outlined,
                    size: 16,
                    color: AppColors.mediumGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${review.helpfulCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => onHelpfulVote!(false),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.thumb_down_outlined,
                    size: 16,
                    color: AppColors.mediumGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${review.notHelpfulCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const Spacer(),
        // Status indicator
        _buildStatusIndicator(context),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (review.status) {
      case ReviewStatus.approved:
        statusColor = AppColors.success;
        statusText = 'Aprovada';
        break;
      case ReviewStatus.pending:
        statusColor = AppColors.warning;
        statusText = 'Aguardando';
        break;
      case ReviewStatus.rejected:
        statusColor = AppColors.error;
        statusText = 'Rejeitada';
        break;
      case ReviewStatus.flagged:
        statusColor = AppColors.error;
        statusText = 'Sinalizada';
        break;
      case ReviewStatus.archived:
        statusColor = AppColors.mediumGrey;
        statusText = 'Arquivada';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Avaliação'),
        content: const Text(
          'Tem certeza que deseja excluir esta avaliação? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete!();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Compact review card for lists
class CompactReviewCard extends StatelessWidget {
  const CompactReviewCard({required this.review, super.key, this.onTap});
  final Review review;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ReviewCard(
      review: review,
      isCompact: true,
      showClinicInfo: false,
      showServiceInfo: false,
      onTap: onTap,
    );
  }
}

/// Review summary widget for clinic/service pages
class ReviewSummary extends StatelessWidget {
  const ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingBreakdown,
    required this.recentReviews,
    super.key,
    this.onSeeAllReviews,
  });
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingBreakdown;
  final List<Review> recentReviews;
  final VoidCallback? onSeeAllReviews;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Avaliações',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (onSeeAllReviews != null)
                  TextButton(
                    onPressed: onSeeAllReviews,
                    child: const Text('Ver todas'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall rating
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      RatingStars(rating: averageRating),
                      const SizedBox(height: 4),
                      Text(
                        '$totalReviews avaliações',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating breakdown
                Expanded(
                  flex: 3,
                  child: RatingBreakdown(
                    ratingCounts: ratingBreakdown,
                    totalRatings: totalReviews,
                  ),
                ),
              ],
            ),
            if (recentReviews.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Avaliações Recentes',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...recentReviews
                  .take(2)
                  .map(
                    (review) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CompactReviewCard(review: review),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Review stats widget for user profile
class UserReviewStats extends StatelessWidget {
  const UserReviewStats({required this.stats, super.key});
  final ReviewStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suas Estatísticas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total de Avaliações',
                    '${stats.totalReviews}',
                    Icons.rate_review,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Média Geral',
                    stats.averageRating.toStringAsFixed(1),
                    Icons.star,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Votos Úteis',
                    '${stats.helpfulVotes}',
                    Icons.thumb_up,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Este Mês',
                    '${stats.reviewsThisMonth}',
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
            if (stats.badges.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Conquistas',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stats.badges.map((badge) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.sgGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.military_tech,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badge.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
