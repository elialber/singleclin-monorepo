import 'package:flutter/material.dart';

class RatingStarsDisplay extends StatelessWidget {
  final double rating; // 0..5
  final double size;
  final int maxStars;

  const RatingStarsDisplay({
    super.key,
    required this.rating,
    this.size = 20,
    this.maxStars = 5,
  });

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < fullStars; i++)
          Icon(Icons.star, color: const Color(0xFF005156), size: size),
        if (hasHalf)
          Icon(Icons.star_half, color: const Color(0xFF005156), size: size),
        for (int i = 0; i < (maxStars - fullStars - (hasHalf ? 1 : 0)); i++)
          Icon(Icons.star_border, color: const Color(0xFF005156), size: size),
      ],
    );
  }
}
