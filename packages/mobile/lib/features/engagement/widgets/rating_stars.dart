import 'package:flutter/material.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';

/// Custom rating stars widget with SingleClin styling
class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.rating,
    super.key,
    this.size = 20.0,
    this.allowHalfRating = true,
    this.isInteractive = false,
    this.onRatingChanged,
    this.color,
    this.unratedColor,
    this.maxRating = 5,
  });
  final double rating;
  final double size;
  final bool allowHalfRating;
  final bool isInteractive;
  final Function(double)? onRatingChanged;
  final Color? color;
  final Color? unratedColor;
  final int maxRating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        return GestureDetector(
          onTap: isInteractive ? () => _handleTap(index + 1) : null,
          child: Icon(
            _getIconForIndex(index),
            size: size,
            color: _getColorForIndex(index),
          ),
        );
      }),
    );
  }

  IconData _getIconForIndex(int index) {
    final starValue = index + 1;

    if (rating >= starValue) {
      return Icons.star;
    } else if (allowHalfRating && rating >= starValue - 0.5) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  Color _getColorForIndex(int index) {
    final starValue = index + 1;

    if (rating >= starValue || (allowHalfRating && rating >= starValue - 0.5)) {
      return color ?? AppColors.sgPrimary;
    } else {
      return unratedColor ?? AppColors.lightGrey;
    }
  }

  void _handleTap(int rating) {
    if (onRatingChanged != null) {
      onRatingChanged!(rating.toDouble());
    }
  }
}

/// Interactive rating stars for user input
class InteractiveRatingStars extends StatefulWidget {
  const InteractiveRatingStars({
    required this.onRatingChanged,
    super.key,
    this.initialRating = 0.0,
    this.size = 32.0,
    this.color,
    this.unratedColor,
    this.maxRating = 5,
    this.allowHalfRating = true,
    this.label,
  });
  final double initialRating;
  final double size;
  final Function(double) onRatingChanged;
  final Color? color;
  final Color? unratedColor;
  final int maxRating;
  final bool allowHalfRating;
  final String? label;

  @override
  State<InteractiveRatingStars> createState() => _InteractiveRatingStarsState();
}

class _InteractiveRatingStarsState extends State<InteractiveRatingStars>
    with SingleTickerProviderStateMixin {
  late double _currentRating;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(widget.maxRating, (index) {
              return GestureDetector(
                onTap: () => _handleTap(index + 1),
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: index < _currentRating.floor()
                          ? _scaleAnimation.value
                          : 1.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Icon(
                          _getIconForIndex(index),
                          size: widget.size,
                          color: _getColorForIndex(index),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(width: 8),
            Text(
              _currentRating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getIconForIndex(int index) {
    final starValue = index + 1;

    if (_currentRating >= starValue) {
      return Icons.star;
    } else if (widget.allowHalfRating && _currentRating >= starValue - 0.5) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  Color _getColorForIndex(int index) {
    final starValue = index + 1;

    if (_currentRating >= starValue ||
        (widget.allowHalfRating && _currentRating >= starValue - 0.5)) {
      return widget.color ?? AppColors.sgPrimary;
    } else {
      return widget.unratedColor ?? AppColors.lightGrey;
    }
  }

  void _handleTap(int rating) {
    setState(() {
      _currentRating = rating.toDouble();
    });
    widget.onRatingChanged(_currentRating);

    // Trigger animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }
}

/// Rating display with number and text
class RatingDisplay extends StatelessWidget {
  const RatingDisplay({
    required this.rating,
    super.key,
    this.totalReviews = 0,
    this.starSize = 16.0,
    this.showReviewCount = true,
    this.textStyle,
  });
  final double rating;
  final int totalReviews;
  final double starSize;
  final bool showReviewCount;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingStars(rating: rating, size: starSize),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style:
              textStyle ??
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.darkGrey,
              ),
        ),
        if (showReviewCount && totalReviews > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($totalReviews)',
            style:
                textStyle ??
                Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
          ),
        ],
      ],
    );
  }
}

/// Compact rating bar for lists
class CompactRating extends StatelessWidget {
  const CompactRating({
    required this.rating,
    super.key,
    this.totalReviews = 0,
    this.width = 60.0,
    this.height = 6.0,
    this.backgroundColor,
    this.foregroundColor,
  });
  final double rating;
  final int totalReviews;
  final double width;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: 12,
          color: foregroundColor ?? AppColors.sgPrimary,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.darkGrey,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.lightGrey,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: rating / 5.0,
            child: Container(
              decoration: BoxDecoration(
                color: foregroundColor ?? AppColors.sgPrimary,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
        if (totalReviews > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($totalReviews)',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
          ),
        ],
      ],
    );
  }
}

/// Rating breakdown chart
class RatingBreakdown extends StatelessWidget {
  const RatingBreakdown({
    required this.ratingCounts,
    required this.totalRatings,
    super.key,
  });
  final Map<int, int> ratingCounts;
  final int totalRatings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        final rating = 5 - index;
        final count = ratingCounts[rating] ?? 0;
        final percentage = totalRatings > 0 ? count / totalRatings : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              Text('$rating', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 4),
              const Icon(Icons.star, size: 12, color: AppColors.sgPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: AppColors.lightGrey,
                  color: AppColors.sgPrimary,
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Rating category breakdown for detailed reviews
class CategoryRatingBreakdown extends StatelessWidget {
  const CategoryRatingBreakdown({
    required this.categoryRatings,
    super.key,
    this.iconSize = 16.0,
  });
  final Map<String, double> categoryRatings;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'key': 'service', 'label': 'Serviço', 'icon': Icons.medical_services},
      {
        'key': 'cleanliness',
        'label': 'Limpeza',
        'icon': Icons.cleaning_services,
      },
      {'key': 'staff', 'label': 'Atendimento', 'icon': Icons.people},
      {'key': 'value', 'label': 'Custo-Benefício', 'icon': Icons.attach_money},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.map((category) {
        final rating = categoryRatings[category['key']] ?? 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Icon(
                category['icon']! as IconData,
                size: iconSize,
                color: AppColors.mediumGrey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category['label']! as String,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              RatingStars(rating: rating, size: iconSize),
              const SizedBox(width: 8),
              Text(
                rating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGrey,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
