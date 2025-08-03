import 'package:flutter/material.dart';

class SingleClinLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showBackground;

  const SingleClinLogo({
    super.key,
    this.size = 48,
    this.color,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? Theme.of(context).primaryColor;
    
    return Container(
      width: size,
      height: size,
      decoration: showBackground
          ? BoxDecoration(
              color: logoColor.withOpacity(0.1),
              shape: BoxShape.circle,
            )
          : null,
      child: CustomPaint(
        painter: _SingleClinLogoPainter(
          color: logoColor,
          showBackground: showBackground,
        ),
      ),
    );
  }
}

class _SingleClinLogoPainter extends CustomPainter {
  final Color color;
  final bool showBackground;

  _SingleClinLogoPainter({
    required this.color,
    required this.showBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw main cross shape with rounded corners
    final path = Path();
    final w = size.width;
    final h = size.height;
    final cornerRadius = w * 0.1;
    
    // Vertical part of cross
    path.moveTo(w * 0.4, h * 0.3);
    path.quadraticBezierTo(w * 0.4, h * 0.2, w * 0.5, h * 0.2);
    path.quadraticBezierTo(w * 0.6, h * 0.2, w * 0.6, h * 0.3);
    path.lineTo(w * 0.6, h * 0.4);
    path.lineTo(w * 0.7, h * 0.4);
    path.quadraticBezierTo(w * 0.8, h * 0.4, w * 0.8, h * 0.5);
    path.quadraticBezierTo(w * 0.8, h * 0.6, w * 0.7, h * 0.6);
    path.lineTo(w * 0.6, h * 0.6);
    path.lineTo(w * 0.6, h * 0.7);
    path.quadraticBezierTo(w * 0.6, h * 0.8, w * 0.5, h * 0.8);
    path.quadraticBezierTo(w * 0.4, h * 0.8, w * 0.4, h * 0.7);
    path.lineTo(w * 0.4, h * 0.6);
    path.lineTo(w * 0.3, h * 0.6);
    path.quadraticBezierTo(w * 0.2, h * 0.6, w * 0.2, h * 0.5);
    path.quadraticBezierTo(w * 0.2, h * 0.4, w * 0.3, h * 0.4);
    path.lineTo(w * 0.4, h * 0.4);
    path.close();

    canvas.drawPath(path, paint);

    // Draw center circle
    final center = Offset(w / 2, h / 2);
    canvas.drawCircle(center, w * 0.08, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Icon variant for smaller uses
class SingleClinIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const SingleClinIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SingleClinLogo(
      size: size,
      color: color,
      showBackground: false,
    );
  }
}