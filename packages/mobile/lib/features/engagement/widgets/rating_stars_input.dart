import 'package:flutter/material.dart';

class RatingStarsInput extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final double size;
  final int maxStars;

  const RatingStarsInput({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 32,
    this.maxStars = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        final starIndex = index + 1;
        final isFilled = rating >= starIndex;
        return IconButton(
          onPressed: () => onRatingChanged(starIndex.toDouble()),
          iconSize: size,
          padding: const EdgeInsets.all(0),
          constraints: const BoxConstraints(),
          icon: Icon(
            isFilled ? Icons.star : Icons.star_border,
            color: const Color(0xFF005156),
          ),
        );
      }),
    );
  }
}
