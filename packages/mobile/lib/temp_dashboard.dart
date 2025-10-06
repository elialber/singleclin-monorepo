import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/features/clinic_discovery/screens/clinic_discovery_screen.dart';
import 'package:singleclin_mobile/shared/controllers/bottom_nav_controller.dart';
import 'package:singleclin_mobile/shared/widgets/custom_bottom_nav.dart';

class TempDashboardScreen extends StatelessWidget {
  const TempDashboardScreen({super.key});

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
  const TempTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dados simulados de transações
    final transactions = [
      {
        'id': 'TXN001',
        'type': 'Consulta',
        'clinic': 'Clínica São Paulo',
        'amount': -2,
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'status': 'Concluída',
      },
      {
        'id': 'TXN002',
        'type': 'Compra de Créditos',
        'clinic': 'SingleClin',
        'amount': 10,
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'status': 'Concluída',
      },
      {
        'id': 'TXN003',
        'type': 'Consulta',
        'clinic': 'Clínica Centro',
        'amount': -1,
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'status': 'Concluída',
      },
      {
        'id': 'TXN004',
        'type': 'Exame',
        'clinic': 'Lab Diagnóstico',
        'amount': -3,
        'date': DateTime.now().subtract(const Duration(days: 15)),
        'status': 'Concluída',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Transações'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: transactions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 100, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Nenhuma transação encontrada',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Suas transações aparecerão aqui',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final amount = transaction['amount']! as int;
                final isCredit = amount > 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCredit ? Colors.green : Colors.red,
                      child: Icon(
                        isCredit ? Icons.add : Icons.remove,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      transaction['type']! as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(transaction['clinic']! as String),
                        Text(
                          'ID: ${transaction['id']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _formatDate(transaction['date']! as DateTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isCredit ? '+' : ''}$amount créditos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCredit ? Colors.green : Colors.red,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            transaction['status']! as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1, // Transações agora é índice 1
        onTap: (index) => Get.find<BottomNavController>().changePage(index),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Hoje';
    } else if (difference == 1) {
      return 'Ontem';
    } else if (difference < 7) {
      return '$difference dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class TempPlansScreen extends StatelessWidget {
  const TempPlansScreen({super.key});

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

class ClinicDiscoveryWithNavScreen extends StatelessWidget {
  const ClinicDiscoveryWithNavScreen({super.key});

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

class TempProfileScreen extends StatelessWidget {
  const TempProfileScreen({super.key});

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
        currentIndex: 3, // Perfil é índice 3
        onTap: (index) => Get.find<BottomNavController>().changePage(index),
      ),
    );
  }
}
