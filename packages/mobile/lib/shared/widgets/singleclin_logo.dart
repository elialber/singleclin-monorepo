import 'package:flutter/material.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';

/// SingleClin Logo Widget
/// Draws the medical cross logo for the SingleClin brand
class SingleClinLogo extends StatelessWidget {
  const SingleClinLogo({
    super.key,
    this.size = 60.0,
    this.color = AppColors.primary,
    this.strokeWidth = 4.0,
  });
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SingleClinLogoPainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class _SingleClinLogoPainter extends CustomPainter {
  _SingleClinLogoPainter({required this.color, required this.strokeWidth});
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final crossSize = size.width * 0.6;
    final thickness = crossSize * 0.25;

    // Draw horizontal bar of the cross
    final horizontalRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: crossSize, height: thickness),
      Radius.circular(thickness * 0.1),
    );
    canvas.drawRRect(horizontalRect, paint);

    // Draw vertical bar of the cross
    final verticalRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: thickness, height: crossSize),
      Radius.circular(thickness * 0.1),
    );
    canvas.drawRRect(verticalRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
