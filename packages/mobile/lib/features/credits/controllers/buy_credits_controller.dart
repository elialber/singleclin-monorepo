import 'package:get/get.dart';
import 'package:singleclin_mobile/features/credits/models/credit_package.dart';

class BuyCreditsController extends GetxController {
  // Reactive variables
  final _isLoading = false.obs;
  final _isProcessingPurchase = false.obs;
  final _packages = <CreditPackage>[].obs;
  final _paymentMethods = <PaymentMethod>[].obs;
  final _selectedPackage = Rx<CreditPackage?>(null);
  final _selectedPaymentMethod = Rx<PaymentMethod?>(null);
  final _promoCode = ''.obs;
  final _appliedDiscount = 0.0.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isProcessingPurchase => _isProcessingPurchase.value;
  List<CreditPackage> get packages => _packages;
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  CreditPackage? get selectedPackage => _selectedPackage.value;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod.value;
  String get promoCode => _promoCode.value;
  double get appliedDiscount => _appliedDiscount.value;

  bool get canPurchase =>
      selectedPackage != null && selectedPaymentMethod != null;

  double get finalPrice {
    if (selectedPackage == null) return 0;
    final originalPrice = selectedPackage!.price;
    return originalPrice - (originalPrice * appliedDiscount / 100);
  }

  String get finalPriceDisplay => 'R\$ ${finalPrice.toStringAsFixed(2)}';

  double get totalSavings {
    if (selectedPackage == null) return 0;
    return selectedPackage!.savings +
        (selectedPackage!.price * appliedDiscount / 100);
  }

  String get totalSavingsDisplay => 'R\$ ${totalSavings.toStringAsFixed(2)}';

  @override
  void onInit() {
    super.onInit();
    loadCreditPackages();
    loadPaymentMethods();
  }

  Future<void> loadCreditPackages() async {
    try {
      _isLoading.value = true;

      // Mock API call
      await Future.delayed(const Duration(seconds: 1));

      _packages.assignAll([
        CreditPackage(
          id: 'starter_100',
          name: '100 Créditos SG',
          description: 'Pacote ideal para começar',
          credits: 100,
          price: 49.90,
          originalPrice: 59.90,
          discount: 16.7,
          isPopular: false,
          isActive: true,
          type: PackageType.starter,
        ),
        CreditPackage(
          id: 'popular_500',
          name: '500 Créditos SG',
          description: 'Nosso pacote mais popular',
          credits: 500,
          price: 199.90,
          originalPrice: 249.90,
          discount: 20.0,
          isPopular: true,
          isActive: true,
          type: PackageType.popular,
          isPromo: true,
          promoEndDate: DateTime.now().add(const Duration(days: 7)),
          promoDescription: 'Oferta especial por tempo limitado!',
        ),
        CreditPackage(
          id: 'value_1000',
          name: '1000 Créditos SG',
          description: 'Melhor valor para uso frequente',
          credits: 1000,
          price: 349.90,
          originalPrice: 449.90,
          discount: 22.2,
          isPopular: false,
          isActive: true,
          type: PackageType.value,
        ),
        CreditPackage(
          id: 'premium_2500',
          name: '2500 Créditos SG',
          description: 'Pacote premium com máximo desconto',
          credits: 2500,
          price: 799.90,
          originalPrice: 1099.90,
          discount: 27.3,
          isPopular: false,
          isActive: true,
          type: PackageType.premium,
          bonusFeatures: {
            'priority_support': true,
            'exclusive_offers': true,
            'extended_validity': true,
          },
        ),
      ]);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível carregar os pacotes de créditos',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadPaymentMethods() async {
    try {
      // Mock API call
      await Future.delayed(const Duration(milliseconds: 500));

      _paymentMethods.assignAll([
        PaymentMethod(
          id: 'pix',
          type: 'pix',
          displayName: 'PIX',
          isDefault: true,
          isActive: true,
          createdAt: DateTime.now(),
        ),
        PaymentMethod(
          id: 'credit_card_1',
          type: 'credit_card',
          displayName: 'Cartão •••• 1234',
          last4: '1234',
          brand: 'visa',
          isDefault: false,
          isActive: true,
          expiryDate: DateTime(2028, 12, 31),
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        PaymentMethod(
          id: 'apple_pay',
          type: 'apple_pay',
          displayName: 'Apple Pay',
          isDefault: false,
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ]);

      // Auto-select default payment method
      final defaultMethod = _paymentMethods.firstWhere(
        (method) => method.isDefault,
        orElse: () => _paymentMethods.first,
      );
      _selectedPaymentMethod.value = defaultMethod;
    } catch (e) {
      print('Error loading payment methods: $e');
    }
  }

  void selectPackage(CreditPackage package) {
    _selectedPackage.value = package;
    update(['package_selection']);
  }

  void selectPaymentMethod(PaymentMethod method) {
    _selectedPaymentMethod.value = method;
    update(['payment_method_selection']);
  }

  Future<void> applyPromoCode(String code) async {
    if (code.isEmpty) {
      clearPromoCode();
      return;
    }

    try {
      _isLoading.value = true;

      // Mock promo code validation
      await Future.delayed(const Duration(seconds: 1));

      // Mock promo codes
      final promoDiscounts = {
        'PRIMEIRA10': 10.0,
        'DESCONTO15': 15.0,
        'SPECIAL20': 20.0,
        'VIP25': 25.0,
      };

      final discount = promoDiscounts[code.toUpperCase()];

      if (discount != null) {
        _promoCode.value = code.toUpperCase();
        _appliedDiscount.value = discount;

        Get.snackbar(
          'Promocode Aplicado!',
          'Você ganhou ${discount.toInt()}% de desconto',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      } else {
        Get.snackbar(
          'Código Inválido',
          'O código promocional informado não é válido',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível validar o código promocional',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void clearPromoCode() {
    _promoCode.value = '';
    _appliedDiscount.value = 0.0;
  }

  Future<void> purchaseCredits() async {
    if (!canPurchase) {
      Get.snackbar(
        'Erro',
        'Selecione um pacote e forma de pagamento',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      _isProcessingPurchase.value = true;

      // Show processing dialog
      Get.dialog(
        AlertDialog(
          title: const Text('Processando Pagamento'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Aguarde enquanto processamos seu pagamento...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Mock payment processing
      await Future.delayed(const Duration(seconds: 3));

      // Close processing dialog
      Get.back();

      // Show success dialog
      final package = selectedPackage!;
      Get.dialog(
        AlertDialog(
          title: const Text('🎉 Compra Realizada!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Parabéns! Você adquiriu ${package.credits} créditos SG.'),
              const SizedBox(height: 8),
              Text('Valor pago: $finalPriceDisplay'),
              if (appliedDiscount > 0)
                Text('Desconto aplicado: ${appliedDiscount.toInt()}%'),
              const SizedBox(height: 8),
              const Text(
                'Seus créditos já estão disponíveis na sua conta!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(); // Close dialog
                Get.back(); // Go back to previous screen
              },
              child: const Text('Ver Meus Créditos'),
            ),
            TextButton(
              onPressed: () {
                Get.back(); // Close dialog
                _resetPurchaseState();
              },
              child: const Text('Comprar Mais'),
            ),
          ],
        ),
      );

      // Track purchase for analytics
      _trackPurchase(package);
    } catch (e) {
      Get.back(); // Close any open dialog
      Get.snackbar(
        'Erro no Pagamento',
        'Não foi possível processar o pagamento. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isProcessingPurchase.value = false;
    }
  }

  void _resetPurchaseState() {
    _selectedPackage.value = null;
    clearPromoCode();
    update(['package_selection']);
  }

  void _trackPurchase(CreditPackage package) {
    // Mock analytics tracking
    final purchaseData = {
      'package_id': package.id,
      'credits_purchased': package.credits,
      'amount_paid': finalPrice,
      'discount_applied': appliedDiscount,
      'payment_method': selectedPaymentMethod?.type,
      'promo_code': promoCode.isEmpty ? null : promoCode,
    };

    print('Purchase tracked: $purchaseData');
  }

  Future<void> addPaymentMethod() async {
    // Navigate to add payment method screen or show modal
    Get.toNamed('/add-payment-method');
  }

  Future<void> removePaymentMethod(PaymentMethod method) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remover Método de Pagamento'),
        content: Text('Deseja remover ${method.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      _paymentMethods.removeWhere((m) => m.id == method.id);

      // If removed method was selected, select another one
      if (selectedPaymentMethod?.id == method.id) {
        _selectedPaymentMethod.value = _paymentMethods.isNotEmpty
            ? _paymentMethods.first
            : null;
      }

      Get.snackbar(
        'Método Removido',
        '${method.displayName} foi removido com sucesso',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void showPackageDetails(CreditPackage package) {
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
            Text(
              package.name,
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(package.description),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('${package.credits} créditos'),
                const Spacer(),
                if (package.hasDiscount) ...[
                  Text(
                    package.originalPriceDisplay,
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  package.priceDisplay,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Get.theme.primaryColor,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            if (package.hasDiscount) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  package.discountDisplay,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Valor por crédito: ${package.creditValueDisplay}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (package.isPromoValid) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.orange.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      package.promoTimeRemainingDisplay,
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  selectPackage(package);
                },
                child: const Text('Selecionar Este Pacote'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
