import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:singleclin_mobile/core/constants/app_colors.dart';
import 'package:singleclin_mobile/shared/widgets/singleclin_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SingleClin'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SingleClinLogo(size: 100),
            SizedBox(height: 24),
            Text(
              'Bem-vindo ao SingleClin!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Sua plataforma de cuidados estéticos',
              style: TextStyle(fontSize: 16, color: AppColors.mediumGrey),
            ),
          ],
        ),
      ),
    );
  }
}
