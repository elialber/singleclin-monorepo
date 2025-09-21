import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_bottom_nav.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Planos de Assinatura',
        showBackButton: false,
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) => Get.find<BottomNavController>().changePage(index),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 24),
          _buildPlansSection(),
          const SizedBox(height: 24),
          _buildBenefitsSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escolha o melhor plano para você',
          style: Get.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.darkGrey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tenha acesso ilimitado aos melhores tratamentos estéticos com nossos planos mensais',
          style: Get.textTheme.bodyMedium?.copyWith(
            color: AppColors.mediumGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildPlansSection() {
    final plans = [
      {
        'name': 'Básico',
        'price': 'R\$ 199',
        'credits': 50,
        'description': 'Ideal para quem está começando',
        'features': [
          '50 créditos SG por mês',
          'Acesso a clínicas parceiras',
          'Suporte via chat',
          'Histórico de tratamentos',
        ],
        'color': AppColors.info,
        'isPopular': false,
      },
      {
        'name': 'Premium',
        'price': 'R\$ 349',
        'credits': 100,
        'description': 'Nosso plano mais popular',
        'features': [
          '100 créditos SG por mês',
          'Acesso a todas as clínicas',
          'Suporte prioritário',
          'Agendamento preferencial',
          '10% de desconto em produtos',
        ],
        'color': AppColors.primary,
        'isPopular': true,
      },
      {
        'name': 'VIP',
        'price': 'R\$ 599',
        'credits': 200,
        'description': 'Para quem quer o melhor',
        'features': [
          '200 créditos SG por mês',
          'Acesso VIP a clínicas premium',
          'Suporte 24/7',
          'Consultorias gratuitas',
          '20% de desconto em produtos',
          'Sessões de coaching',
        ],
        'color': AppColors.warning,
        'isPopular': false,
      },
    ];

    return Column(
      children: plans.map((plan) => _buildPlanCard(plan)).toList(),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isPopular = plan['isPopular'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPopular ? AppColors.primary : AppColors.lightGrey,
                width: isPopular ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkGrey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan['name'] as String,
                          style: Get.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: plan['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan['description'] as String,
                          style: Get.textTheme.bodyMedium?.copyWith(
                            color: AppColors.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          plan['price'] as String,
                          style: Get.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGrey,
                          ),
                        ),
                        Text(
                          '/mês',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppColors.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (plan['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${plan['credits']} créditos SG inclusos',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: plan['color'] as Color,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...((plan['features'] as List<String>).map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 20,
                          color: plan['color'] as Color,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: Get.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _selectPlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? AppColors.primary : AppColors.lightGrey,
                      foregroundColor: isPopular ? AppColors.white : AppColors.darkGrey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isPopular ? 'Escolher Plano Popular' : 'Escolher Plano',
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: -1,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'MAIS POPULAR',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Por que escolher nossos planos?',
          style: Get.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildBenefitItem(
          icon: Icons.local_hospital,
          title: 'Rede de Clínicas Premium',
          description: 'Acesso às melhores clínicas de estética do país',
        ),
        _buildBenefitItem(
          icon: Icons.schedule,
          title: 'Flexibilidade Total',
          description: 'Use seus créditos quando e onde quiser',
        ),
        _buildBenefitItem(
          icon: Icons.security,
          title: 'Garantia de Qualidade',
          description: 'Todos os profissionais são certificados',
        ),
        _buildBenefitItem(
          icon: Icons.support_agent,
          title: 'Suporte Especializado',
          description: 'Equipe dedicada para te ajudar sempre',
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: AppColors.mediumGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectPlan(Map<String, dynamic> plan) {
    Get.dialog(
      AlertDialog(
        title: Text('Confirmar Plano ${plan['name']}'),
        content: Text(
          'Você deseja assinar o plano ${plan['name']} por ${plan['price']}/mês?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Plano Selecionado',
                'Redirecionando para o pagamento...',
                snackPosition: SnackPosition.BOTTOM,
              );
              // TODO: Implementar navegação para tela de pagamento
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}