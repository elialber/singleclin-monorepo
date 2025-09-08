import 'package:get/get.dart';
import '../models/subscription_plan.dart';

class SubscriptionController extends GetxController {
  // Reactive variables
  final _isLoading = false.obs;
  final _isProcessing = false.obs;
  final _plans = <SubscriptionPlan>[].obs;
  final _currentSubscription = Rx<UserSubscription?>(null);
  final _selectedPlan = Rx<SubscriptionPlan?>(null);
  final _selectedBillingCycle = SubscriptionBillingCycle.monthly.obs;
  final _comparisonMode = false.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isProcessing => _isProcessing.value;
  List<SubscriptionPlan> get plans => _plans;
  UserSubscription? get currentSubscription => _currentSubscription.value;
  SubscriptionPlan? get selectedPlan => _selectedPlan.value;
  SubscriptionBillingCycle get selectedBillingCycle => _selectedBillingCycle.value;
  bool get comparisonMode => _comparisonMode.value;

  bool get hasActiveSubscription => currentSubscription?.isActive ?? false;
  bool get canChangePlan => hasActiveSubscription;
  
  SubscriptionPlan? get currentPlan => currentSubscription?.plan;

  List<SubscriptionPlan> get sortedPlans {
    final sorted = List<SubscriptionPlan>.from(_plans);
    sorted.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted;
  }

  double get selectedPlanPrice {
    if (selectedPlan == null) return 0;
    return selectedBillingCycle == SubscriptionBillingCycle.monthly
        ? selectedPlan!.monthlyPrice
        : selectedPlan!.annualPrice;
  }

  String get selectedPlanPriceDisplay {
    if (selectedPlan == null) return '';
    return selectedBillingCycle == SubscriptionBillingCycle.monthly
        ? selectedPlan!.monthlyPriceDisplay
        : selectedPlan!.annualPriceDisplay;
  }

  double get annualSavings {
    if (selectedPlan == null) return 0;
    return selectedPlan!.annualSavings;
  }

  String get annualSavingsDisplay => 'R\$ ${annualSavings.toStringAsFixed(2)}';

  @override
  void onInit() {
    super.onInit();
    loadSubscriptionPlans();
    loadCurrentSubscription();
  }

  Future<void> loadSubscriptionPlans() async {
    try {
      _isLoading.value = true;
      
      // Mock API call
      await Future.delayed(const Duration(seconds: 1));
      
      _plans.assignAll([
        SubscriptionPlan(
          id: 'basic',
          name: 'Basic',
          description: 'Ideal para uso ocasional',
          monthlyCredits: 50,
          monthlyPrice: 9.90,
          annualPrice: 99.00,
          features: [
            'Agendamentos básicos',
            '50 créditos SG/mês',
            'Suporte via chat',
            '1 clínica favorita',
            'Notificações por email',
          ],
          restrictions: [
            'Reagendamento limitado',
            'Sem suporte telefônico',
          ],
          isPopular: false,
          isActive: true,
          hasFreeTrial: true,
          freeTrialDays: 7,
          maxClinics: 1,
          maxAppointmentsPerDay: 2,
          sortOrder: 1,
          category: 'basic',
        ),
        SubscriptionPlan(
          id: 'premium',
          name: 'Premium',
          description: 'O mais escolhido pelos usuários',
          monthlyCredits: 200,
          monthlyPrice: 29.90,
          annualPrice: 299.00,
          features: [
            'Agendamentos ilimitados',
            '200 créditos SG/mês',
            'Suporte prioritário',
            '5 clínicas favoritas',
            'Cancelamento grátis até 2h antes',
            'Relatórios de saúde',
            'Notificações personalizadas',
            'Desconto em parceiros',
          ],
          isPopular: true,
          isActive: true,
          hasFreeTrial: true,
          freeTrialDays: 14,
          maxClinics: 5,
          maxAppointmentsPerDay: 5,
          discountPercentage: 16.7,
          sortOrder: 2,
          category: 'premium',
        ),
        SubscriptionPlan(
          id: 'vip',
          name: 'VIP',
          description: 'Máximo benefício e exclusividade',
          monthlyCredits: 500,
          monthlyPrice: 69.90,
          annualPrice: 699.00,
          features: [
            'Agendamentos ilimitados',
            '500 créditos SG/mês',
            'Suporte 24/7 dedicado',
            'Clínicas ilimitadas',
            'Cancelamento grátis até 30min antes',
            'Telemedicina inclusa',
            'Consultor de saúde pessoal',
            'Relatórios médicos avançados',
            'Prioridade na fila',
            'Descontos exclusivos',
            'Créditos extras mensais',
          ],
          isPopular: false,
          isActive: true,
          hasFreeTrial: true,
          freeTrialDays: 30,
          maxClinics: 999,
          maxAppointmentsPerDay: 999,
          discountPercentage: 16.7,
          sortOrder: 3,
          category: 'vip',
        ),
      ]);
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível carregar os planos',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadCurrentSubscription() async {
    try {
      // Mock API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock current subscription (Premium)
      final premiumPlan = _plans.firstWhere(
        (plan) => plan.id == 'premium',
        orElse: () => _plans.first,
      );
      
      _currentSubscription.value = UserSubscription(
        id: 'sub_123',
        userId: 'user_123',
        planId: premiumPlan.id,
        plan: premiumPlan,
        status: SubscriptionStatus.active,
        billingCycle: SubscriptionBillingCycle.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        nextBillingDate: DateTime.now().add(const Duration(days: 15)),
        creditsBalance: 180,
        creditsUsedThisMonth: 20,
        creditsTotal: 200,
        amountPaid: premiumPlan.monthlyPrice,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      );
      
    } catch (e) {
      print('Error loading current subscription: $e');
    }
  }

  void selectPlan(SubscriptionPlan plan) {
    _selectedPlan.value = plan;
    update(['plan_selection']);
  }

  void setBillingCycle(SubscriptionBillingCycle cycle) {
    _selectedBillingCycle.value = cycle;
    update(['billing_cycle']);
  }

  void toggleComparisonMode() {
    _comparisonMode.value = !_comparisonMode.value;
    update(['comparison_mode']);
  }

  Future<void> subscribeToPlan(SubscriptionPlan plan, {SubscriptionBillingCycle? cycle}) async {
    if (isProcessing) return;
    
    try {
      _isProcessing.value = true;
      
      final billingCycle = cycle ?? _selectedBillingCycle.value;
      
      // Show confirmation dialog
      final confirmed = await _showSubscriptionConfirmation(plan, billingCycle);
      if (!confirmed) return;
      
      // Show processing dialog
      Get.dialog(
        AlertDialog(
          title: const Text('Processando Assinatura'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Aguarde enquanto processamos sua assinatura...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );
      
      // Mock subscription process
      await Future.delayed(const Duration(seconds: 3));
      
      // Close processing dialog
      Get.back();
      
      // Show success
      Get.dialog(
        AlertDialog(
          title: const Text('🎉 Assinatura Ativada!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bem-vindo ao plano ${plan.name}!'),
              const SizedBox(height: 8),
              Text('${plan.monthlyCredits} créditos SG foram adicionados à sua conta.'),
              if (plan.hasFreeTrial)
                Text('\n🎁 Aproveite seus ${plan.freeTrialDays} dias grátis!'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                Get.back(); // Go back to main credits screen
              },
              child: const Text('Começar a Usar'),
            ),
          ],
        ),
      );
      
      // Refresh subscription data
      await loadCurrentSubscription();
      
    } catch (e) {
      Get.back(); // Close any open dialog
      Get.snackbar(
        'Erro',
        'Não foi possível processar a assinatura',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isProcessing.value = false;
    }
  }

  Future<bool> _showSubscriptionConfirmation(
    SubscriptionPlan plan, 
    SubscriptionBillingCycle cycle
  ) async {
    final price = cycle == SubscriptionBillingCycle.monthly 
        ? plan.monthlyPrice 
        : plan.annualPrice;
    
    final priceDisplay = cycle == SubscriptionBillingCycle.monthly 
        ? plan.monthlyPriceDisplay 
        : plan.annualPriceDisplay;
    
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Confirmar Assinatura ${plan.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plano: ${plan.name}'),
            Text('Cobrança: ${cycle == SubscriptionBillingCycle.monthly ? 'Mensal' : 'Anual'}'),
            Text('Valor: $priceDisplay'),
            Text('Créditos: ${plan.monthlyCredits} SG/mês'),
            if (plan.hasFreeTrial)
              Text('\n✅ ${plan.freeTrialDays} dias grátis para testar!'),
            if (cycle == SubscriptionBillingCycle.annual)
              Text('\n💰 Economia anual: ${plan.annualSavingsDisplay}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Confirmar Assinatura'),
          ),
        ],
      ),
    );
    
    return confirmed ?? false;
  }

  Future<void> changePlan(SubscriptionPlan newPlan) async {
    if (!canChangePlan || currentPlan == null) return;
    
    try {
      _isProcessing.value = true;
      
      final isUpgrade = newPlan.monthlyPrice > currentPlan!.monthlyPrice;
      final isDowngrade = newPlan.monthlyPrice < currentPlan!.monthlyPrice;
      
      String dialogTitle = isUpgrade ? 'Fazer Upgrade' : 
                          isDowngrade ? 'Fazer Downgrade' : 'Alterar Plano';
      
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text(dialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plano atual: ${currentPlan!.name}'),
              Text('Novo plano: ${newPlan.name}'),
              const SizedBox(height: 8),
              if (isUpgrade) ...[
                Text('Você será cobrado a diferença proporcional.'),
                Text('Novos créditos serão adicionados imediatamente.'),
              ] else if (isDowngrade) ...[
                Text('A alteração será aplicada no próximo ciclo.'),
                Text('Você manterá os créditos atuais.'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: Text(isUpgrade ? 'Fazer Upgrade' : 'Alterar Plano'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
      
      // Mock plan change process
      await Future.delayed(const Duration(seconds: 2));
      
      Get.snackbar(
        'Plano Alterado!',
        isUpgrade 
          ? 'Upgrade realizado com sucesso!'
          : 'Seu plano será alterado no próximo ciclo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
      // Refresh subscription data
      await loadCurrentSubscription();
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível alterar o plano',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isProcessing.value = false;
    }
  }

  Future<void> cancelSubscription() async {
    if (!hasActiveSubscription) return;
    
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancelar Assinatura'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tem certeza que deseja cancelar sua assinatura?'),
            SizedBox(height: 8),
            Text('• Você manterá acesso até o final do período pago'),
            Text('• Seus créditos atuais serão mantidos'),
            Text('• Você pode reativar a qualquer momento'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Manter Assinatura'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      _isProcessing.value = true;
      
      // Mock cancellation process
      await Future.delayed(const Duration(seconds: 1));
      
      Get.snackbar(
        'Assinatura Cancelada',
        'Sua assinatura foi cancelada e será válida até ${currentSubscription?.nextBillingDate.day}/${currentSubscription?.nextBillingDate.month}',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Refresh subscription data
      await loadCurrentSubscription();
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível cancelar a assinatura',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isProcessing.value = false;
    }
  }

  Future<void> pauseSubscription() async {
    if (!hasActiveSubscription) return;
    
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Pausar Assinatura'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deseja pausar sua assinatura temporariamente?'),
            SizedBox(height: 8),
            Text('• As cobranças serão suspensas'),
            Text('• Você manterá os créditos atuais'),
            Text('• Pode reativar quando quiser'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Pausar Assinatura'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      _isProcessing.value = true;
      
      // Mock pause process
      await Future.delayed(const Duration(seconds: 1));
      
      Get.snackbar(
        'Assinatura Pausada',
        'Sua assinatura foi pausada com sucesso',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      await loadCurrentSubscription();
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível pausar a assinatura',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isProcessing.value = false;
    }
  }

  void showPlanDetails(SubscriptionPlan plan) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  plan.name,
                  style: Get.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (plan.isPopular) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Get.theme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(plan.description),
            const SizedBox(height: 16),
            
            // Price and credits
            Row(
              children: [
                Text(
                  plan.monthlyPriceDisplay,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Get.theme.primaryColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${plan.monthlyCredits} SG/mês',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            if (plan.hasFreeTrial) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '${plan.freeTrialDays} dias grátis!',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            Text(
              'Recursos Inclusos:',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...plan.features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check, color: Colors.green.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            )),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  if (hasActiveSubscription && currentPlan?.id != plan.id) {
                    changePlan(plan);
                  } else if (!hasActiveSubscription) {
                    subscribeToPlan(plan);
                  }
                },
                child: Text(
                  hasActiveSubscription 
                    ? (currentPlan?.id == plan.id ? 'Plano Atual' : 'Alterar para Este Plano')
                    : 'Assinar Agora',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double calculateSavings(SubscriptionPlan plan) {
    // Calculate how much user saves compared to buying credits individually
    const creditPrice = 0.50; // R$ 0.50 per credit when buying individually
    final individualPrice = plan.monthlyCredits * creditPrice;
    return individualPrice - plan.monthlyPrice;
  }

  String calculateSavingsDisplay(SubscriptionPlan plan) {
    final savings = calculateSavings(plan);
    return 'Economize R\$ ${savings.toStringAsFixed(2)}/mês';
  }

  @override
  void onClose() {
    super.onClose();
  }
}