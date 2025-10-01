import 'package:flutter/material.dart';
import 'package:singleclin_mobile/features/clinic_discovery/models/clinic.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';

class SubscriptionSection extends StatefulWidget {
  const SubscriptionSection({Key? key, required this.clinic}) : super(key: key);
  final Clinic clinic;

  @override
  State<SubscriptionSection> createState() => _SubscriptionSectionState();
}

class _SubscriptionSectionState extends State<SubscriptionSection> {
  bool _isSubscribed = false; // This should come from user state

  // Mock subscription plans
  final List<SubscriptionPlan> _subscriptionPlans = [
    SubscriptionPlan(
      id: 'basic',
      name: 'Plano Básico',
      price: 39.90,
      period: 'mês',
      benefits: [
        'Consultas ilimitadas',
        'Descontos em exames',
        'Prioridade no agendamento',
      ],
      isPopular: false,
    ),
    SubscriptionPlan(
      id: 'premium',
      name: 'Plano Premium',
      price: 69.90,
      period: 'mês',
      benefits: [
        'Todos os benefícios do Básico',
        'Consultas de emergência',
        'Telemedicina inclusa',
        'Descontos em medicamentos',
      ],
      isPopular: true,
    ),
    SubscriptionPlan(
      id: 'family',
      name: 'Plano Família',
      price: 119.90,
      period: 'mês',
      benefits: [
        'Todos os benefícios do Premium',
        'Cobertura para até 4 pessoas',
        'Consultoria nutricional',
        'Check-ups anuais gratuitos',
      ],
      isPopular: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assinatura e acesso',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tenha acesso privilegiado',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            // Subscription Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isSubscribed ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isSubscribed
                      ? Colors.green[200]!
                      : Colors.orange[200]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isSubscribed ? Icons.check_circle : Icons.info,
                    size: 14,
                    color: _isSubscribed
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isSubscribed ? 'Assinante' : 'Não assinante',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isSubscribed
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Current Status Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isSubscribed ? Colors.green[50] : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isSubscribed ? Colors.green[200]! : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isSubscribed ? Colors.green[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isSubscribed ? Icons.star : Icons.star_border,
                  color: _isSubscribed ? Colors.green[700] : Colors.grey[600],
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSubscribed
                          ? 'Você é assinante Premium'
                          : 'Torne-se um assinante',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _isSubscribed
                            ? Colors.green[700]
                            : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isSubscribed
                          ? 'Aproveite todos os benefícios exclusivos'
                          : 'Tenha acesso prioritário e descontos especiais',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isSubscribed
                            ? Colors.green[600]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              if (!_isSubscribed)
                InkWell(
                  onTap: _showSubscriptionOptions,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Assinar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Benefits Preview
        if (!_isSubscribed) ...[
          const SizedBox(height: 16),

          Text(
            'Benefícios da assinatura',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),

          const SizedBox(height: 8),

          Column(
            children: [
              _buildBenefitItem(
                icon: Icons.schedule,
                title: 'Agendamento prioritário',
                description: 'Acesso preferencial aos horários disponíveis',
              ),
              _buildBenefitItem(
                icon: Icons.discount,
                title: 'Descontos exclusivos',
                description: 'Até 20% de desconto em procedimentos',
              ),
              _buildBenefitItem(
                icon: Icons.support_agent,
                title: 'Suporte 24/7',
                description: 'Atendimento preferencial via chat',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Subscribe Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _showSubscriptionOptions,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Ver planos de assinatura',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],

        // Current Subscription Info
        if (_isSubscribed) ...[
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Plano Premium',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const Text(
                      r'R$ 69,90/mês',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'Próxima renovação: 15 de outubro',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _showManageSubscription,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Gerenciar',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showUpgradeOptions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Upgrade',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SubscriptionOptionsBottomSheet(
        plans: _subscriptionPlans,
        onPlanSelected: _subscribeToPlan,
      ),
    );
  }

  void _subscribeToPlan(SubscriptionPlan plan) {
    // TODO: Implement subscription logic
    setState(() {
      _isSubscribed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assinatura ${plan.name} ativada com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showManageSubscription() {
    // TODO: Navigate to subscription management screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Gerenciar assinatura...')));
  }

  void _showUpgradeOptions() {
    // TODO: Show upgrade options
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opções de upgrade...')));
  }
}

class _SubscriptionOptionsBottomSheet extends StatelessWidget {
  const _SubscriptionOptionsBottomSheet({
    required this.plans,
    required this.onPlanSelected,
  });
  final List<SubscriptionPlan> plans;
  final Function(SubscriptionPlan) onPlanSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Escolha seu plano',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 20),

                Column(
                  children: plans
                      .map((plan) => _buildPlanCard(context, plan))
                      .toList(),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: plan.isPopular ? AppColors.primary : Colors.grey[300]!,
          width: plan.isPopular ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onPlanSelected(plan);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (plan.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Popular',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Text(
                    'R\$ ${plan.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '/${plan.period}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: plan.benefits
                    .map(
                      (benefit) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.green[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                benefit,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubscriptionPlan {
  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.benefits,
    required this.isPopular,
  });
  final String id;
  final String name;
  final double price;
  final String period;
  final List<String> benefits;
  final bool isPopular;
}
