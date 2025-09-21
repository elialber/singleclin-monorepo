import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'shared/widgets/custom_bottom_nav.dart';
import 'shared/controllers/bottom_nav_controller.dart';
import 'features/clinic_discovery/screens/clinic_discovery_screen.dart';

class TempDashboardScreen extends StatelessWidget {
  const TempDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SingleClin Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Bem-vindo ao SingleClin!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Use o menu inferior para navegar',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) => Get.find<BottomNavController>().changePage(index),
      ),
    );
  }
}


class TempTransactionsScreen extends StatelessWidget {
  const TempTransactionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Histórico de Transações',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Veja todas as suas transações de créditos',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1, // Transações agora é índice 1
        onTap: (index) => Get.find<BottomNavController>().changePage(index),
      ),
    );
  }
}

class TempPlansScreen extends StatelessWidget {
  const TempPlansScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monetization_on, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Planos de Assinatura',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Escolha o melhor plano para você',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2, // Planos agora é índice 2
        onTap: (index) => Get.find<BottomNavController>().changePage(index),
      ),
    );
  }
}

class TempProfileScreen extends StatelessWidget {
  const TempProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Meu Perfil',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Gerencie suas informações pessoais',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3, // Perfil agora é índice 3
        onTap: (index) => Get.find<BottomNavController>().changePage(index),
      ),
    );
  }
}

class ClinicDiscoveryWithNavScreen extends StatelessWidget {
  const ClinicDiscoveryWithNavScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const ClinicDiscoveryScreen(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0, // Início é índice 0
        onTap: (index) => Get.find<BottomNavController>().changePage(index),
      ),
    );
  }
}