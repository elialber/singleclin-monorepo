import 'package:get/get.dart';
import 'package:singleclin_mobile/core/services/api_service.dart';
import 'package:singleclin_mobile/features/auth/controllers/auth_controller.dart';

/// Serviço centralizado para gerenciamento de créditos
/// Usado por ProfileController e ClinicServicesController para manter sincronização
class CreditsService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  final AuthController _authController = Get.find<AuthController>();

  // Observables para sincronização entre telas
  final RxInt credits = 0.obs;
  final Rx<DateTime?> lastUpdate = Rx<DateTime?>(null);
  final RxBool isLoading = false.obs;

  /// Carrega créditos do usuário usando os dois endpoints disponíveis
  Future<int> loadUserCredits({bool forceRefresh = false}) async {
    try {
      // Evita múltiplas chamadas simultâneas
      if (isLoading.value && !forceRefresh) {
        return credits.value;
      }

      isLoading.value = true;

      // Verifica se o usuário está autenticado
      if (!_authController.isAuthenticated) {
        print('❌ CreditsService: User not authenticated');
        credits.value = 0;
        return 0;
      }

      final user = _authController.user;
      if (user == null) {
        print('❌ CreditsService: No user found');
        credits.value = 0;
        return 0;
      }

      print('🔍 CreditsService: Loading credits for user: ${user.id}');

      // Tenta usar o endpoint específico de créditos primeiro
      try {
        final response = await _apiService.get('/Appointments/my-credits');
        print('📊 CreditsService: Credits API response: ${response.statusCode} - ${response.data}');

        if (response.statusCode == 200) {
          final data = response.data;
          int totalCredits = 0;

          if (data is Map<String, dynamic>) {
            // Estrutura: {"data": {"TotalAvailableCredits": X}}
            final creditsData = data['data'] ?? data;
            if (creditsData is Map<String, dynamic>) {
              totalCredits = (creditsData['TotalAvailableCredits'] as num?)?.toInt() ??
                           (creditsData['totalAvailableCredits'] as num?)?.toInt() ?? 0;
            }
          }

          credits.value = totalCredits;
          lastUpdate.value = DateTime.now();
          print('✅ CreditsService: Credits loaded from appointments API: $totalCredits');
          return totalCredits;
        }
      } catch (e) {
        print('⚠️ CreditsService: Appointments API failed, trying Users API: $e');
      }

      // Fallback para o endpoint de usuários
      try {
        final response = await _apiService.get('/Users/${user.id}/credits');
        print('📊 CreditsService: Users API response: ${response.statusCode} - ${response.data}');

        if (response.statusCode == 200) {
          final data = response.data;
          int totalCredits = 0;

          if (data is Map<String, dynamic>) {
            totalCredits = (data['credits'] as num?)?.toInt() ?? 0;
          } else if (data is num) {
            totalCredits = data.toInt();
          }

          credits.value = totalCredits;
          lastUpdate.value = DateTime.now();
          print('✅ CreditsService: Credits loaded from users API: $totalCredits');
          return totalCredits;
        }
      } catch (e) {
        print('❌ CreditsService: Both APIs failed: $e');
      }

      // Se ambos falharam, mantém valor anterior ou 0
      print('⚠️ CreditsService: Could not load credits, keeping current value: ${credits.value}');
      return credits.value;

    } catch (e) {
      print('❌ CreditsService: Error loading credits: $e');
      return credits.value;
    } finally {
      isLoading.value = false;
    }
  }

  /// Atualiza créditos localmente após consumo
  void consumeCredits(int amount) {
    if (amount > 0 && credits.value >= amount) {
      credits.value -= amount;
      lastUpdate.value = DateTime.now();
      print('💳 CreditsService: Consumed $amount credits, remaining: ${credits.value}');
    }
  }

  /// Adiciona créditos localmente
  void addCredits(int amount) {
    if (amount > 0) {
      credits.value += amount;
      lastUpdate.value = DateTime.now();
      print('💰 CreditsService: Added $amount credits, total: ${credits.value}');
    }
  }

  /// Força refresh dos créditos
  Future<int> refreshCredits() async {
    return await loadUserCredits(forceRefresh: true);
  }

  /// Retorna texto formatado da última atualização
  String getLastUpdateText() {
    final lastUpdateTime = lastUpdate.value;
    if (lastUpdateTime == null) return 'Nunca atualizado';

    final now = DateTime.now();
    final difference = now.difference(lastUpdateTime);

    if (difference.inSeconds < 60) {
      return 'Atualizado agora';
    } else if (difference.inMinutes < 60) {
      return 'Há ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Há ${difference.inHours}h';
    } else {
      return 'Há ${difference.inDays} dias';
    }
  }

  /// Verifica se o usuário tem créditos suficientes
  bool hasEnoughCredits(int requiredCredits) {
    return credits.value >= requiredCredits;
  }

  /// Inicialização do serviço
  @override
  void onInit() {
    super.onInit();
    // Carrega créditos automaticamente se o usuário estiver logado
    if (_authController.isAuthenticated) {
      loadUserCredits();
    }
  }
}