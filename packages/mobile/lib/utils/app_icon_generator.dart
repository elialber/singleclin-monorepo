import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import '../core/constants/app_colors.dart';
import '../shared/widgets/singleclin_logo.dart';

class AppIconGenerator {
  static Future<Uint8List> generateAppIcon({int size = 512}) async {
    // Create a custom painter for the app icon
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Background gradient
    final rect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primary,
        AppColors.primaryDark,
      ],
    ).createShader(rect);
    
    paint.shader = gradient;
    
    // Draw rounded rectangle background
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size * 0.2), // 20% border radius
    );
    canvas.drawRRect(rrect, paint);

    // Draw white circle background for logo
    final centerX = size / 2;
    final centerY = size / 2;
    final circleRadius = size * 0.32; // 32% of size
    
    paint.shader = null;
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(centerX, centerY),
      circleRadius,
      paint,
    );

    // Draw medical cross (simplified version of SingleClinLogo)
    final crossPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    
    final crossSize = size * 0.18; // 18% of size
    final crossThickness = crossSize * 0.3;
    
    // Horizontal bar
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: crossSize,
        height: crossThickness,
      ),
      crossPaint,
    );
    
    // Vertical bar
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: crossThickness,
        height: crossSize,
      ),
      crossPaint,
    );

    // Add small SG accent (golden dot)
    final sgPaint = Paint()
      ..color = AppColors.sgPrimary
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(centerX + circleRadius * 0.6, centerY - circleRadius * 0.6),
      size * 0.04, // 4% of size
      sgPaint,
    );

    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }

  static Widget buildIconPreview({double size = 120}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main logo container
          Center(
            child: Container(
              width: size * 0.64,
              height: size * 0.64,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SingleClinLogo(
                  size: size * 0.36,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          
          // SG accent dot
          Positioned(
            right: size * 0.15,
            top: size * 0.15,
            child: Container(
              width: size * 0.08,
              height: size * 0.08,
              decoration: BoxDecoration(
                color: AppColors.sgPrimary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: size * 0.01,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget to preview the generated icon
class AppIconPreviewScreen extends StatelessWidget {
  const AppIconPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('App Icon Preview'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SingleClin App Icon',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            
            // Large preview
            AppIconGenerator.buildIconPreview(size: 200),
            
            const SizedBox(height: 32),
            
            // Different sizes preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    AppIconGenerator.buildIconPreview(size: 60),
                    const SizedBox(height: 8),
                    const Text('60x60', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    AppIconGenerator.buildIconPreview(size: 80),
                    const SizedBox(height: 8),
                    const Text('80x80', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    AppIconGenerator.buildIconPreview(size: 120),
                    const SizedBox(height: 8),
                    const Text('120x120', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: () async {
                // Generate and save icon (in a real app)
                final iconData = await AppIconGenerator.generateAppIcon();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Icon generated! Size: ${iconData.length} bytes',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Generate Icon File'),
            ),
          ],
        ),
      ),
    );
  }
}