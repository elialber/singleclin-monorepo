import 'package:get/get.dart';
import 'package:singleclin_mobile/data/services/clinic_api_service.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/clinic_discovery/models/clinic.dart';
import '../../../features/appointment/models/appointment_model.dart';
import '../../../core/constants/app_constants.dart';

class DashboardController extends GetxController {
  final ClinicApiService _clinicApiService = ClinicApiService();
  final AuthController _authController = Get.find<AuthController>();

  // Observable properties
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxList<Clinic> _nearbyClinics = <Clinic>[].obs;
  final RxList<ServiceModel> _recommendedServices = <ServiceModel>[].obs;
  final RxList<ServiceModel> _popularServices = <ServiceModel>[].obs;
  final Rx<AppointmentModel?> _nextAppointment = Rx<AppointmentModel?>(null);
  final RxString _searchQuery = ''.obs;
  final RxList<String> _recentSearches = <String>[].obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  List<Clinic> get nearbyClinics => _nearbyClinics;
  List<ServiceModel> get recommendedServices => _recommendedServices;
  List<ServiceModel> get popularServices => _popularServices;
  AppointmentModel? get nextAppointment => _nextAppointment.value;
  String get searchQuery => _searchQuery.value;
  List<String> get recentSearches => _recentSearches;

  // User data getters
  int get userCredits => _authController.user?.sgCredits ?? 0;
  DateTime? get creditsRenewDate => _authController.user?.creditsRenewDate;
  String get userName => _authController.user?.fullName ?? 'Usuário';

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  /// Carregar todos os dados do dashboard
  Future<void> loadDashboardData() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      // Carregar dados em paralelo
      await Future.wait([
        _loadNearbyClinics(),
        _loadRecommendedServices(),
        _loadPopularServices(),
        _loadNextAppointment(),
        _loadRecentSearches(),
      ]);
    } catch (e) {
      _error.value = 'Erro ao carregar dados: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Carregar clínicas próximas
  Future<void> _loadNearbyClinics() async {
    try {
      final clinics = await _clinicApiService.getActiveClinics();
      _nearbyClinics.value = clinics.take(5).toList();
    } catch (e) {
      print('Erro ao carregar clínicas próximas: $e');
    }
  }

  /// Carregar serviços recomendados
  Future<void> _loadRecommendedServices() async {
    try {
      final userId = _authController.user?.id;
      if (userId == null) return;

      // TODO: Implementar serviço real quando API estiver disponível
      _recommendedServices.clear();
    } catch (e) {
      print('Erro ao carregar serviços recomendados: $e');
    }
  }

  /// Carregar serviços populares
  Future<void> _loadPopularServices() async {
    try {
      // TODO: Implementar serviço real quando API estiver disponível
      _popularServices.clear();
    } catch (e) {
      print('Erro ao carregar serviços populares: $e');
    }
  }

  /// Carregar próximo agendamento
  Future<void> _loadNextAppointment() async {
    try {
      final userId = _authController.user?.id;
      if (userId == null) return;

      // TODO: Implementar serviço real quando API estiver disponível
      _nextAppointment.value = null;
    } catch (e) {
      print('Erro ao carregar próximo agendamento: $e');
    }
  }

  /// Carregar buscas recentes
  Future<void> _loadRecentSearches() async {
    try {
      // Implementar carregamento de buscas recentes do storage local
      // Por enquanto, lista vazia
      _recentSearches.clear();
    } catch (e) {
      print('Erro ao carregar buscas recentes: $e');
    }
  }

  /// Buscar serviços/clínicas
  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    try {
      _searchQuery.value = query;

      // Adicionar à lista de buscas recentes
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 5) {
          _recentSearches.removeRange(5, _recentSearches.length);
        }
      }

      // Buscar clínicas usando serviço real
      final results = await _clinicApiService.searchClinics(query);

      // Navegar para tela de resultados com os dados reais
      Get.toNamed('/search-results', arguments: {
        'query': query,
        'clinics': results,
      });
    } catch (e) {
      _error.value = 'Erro na busca: $e';
    }
  }

  /// Navegar para categoria específica
  Future<void> navigateToCategory(String category) async {
    try {
      // Buscar clínicas da categoria usando serviço real
      final clinics = await _clinicApiService.getActiveClinics();

      Get.toNamed('/discovery', arguments: {
        'category': category,
        'clinics': clinics,
      });
    } catch (e) {
      _error.value = 'Erro ao carregar categoria: $e';
    }
  }

  /// Navegar para detalhes da clínica
  Future<void> navigateToClinic(String clinicId) async {
    try {
      // Buscar dados da clínica usando serviço real
      final clinic = await _clinicApiService.getClinicById(clinicId);

      Get.toNamed('/clinic-details', arguments: {
        'clinicId': clinicId,
        'clinic': clinic,
      });
    } catch (e) {
      _error.value = 'Erro ao carregar detalhes da clínica: $e';
    }
  }

  /// Navegar para detalhes do serviço
  void navigateToService(String serviceId) {
    Get.toNamed('/service-details', arguments: {
      'serviceId': serviceId,
    });
  }

  /// Navegar para detalhes do agendamento
  void navigateToAppointment(String appointmentId) {
    Get.toNamed('/appointment-details', arguments: {
      'appointmentId': appointmentId,
    });
  }

  /// Refresh dos dados
  Future<void> refresh() async {
    await loadDashboardData();
  }

  /// Limpar busca
  void clearSearch() {
    _searchQuery.value = '';
  }

  /// Remover busca recente
  void removeRecentSearch(String search) {
    _recentSearches.remove(search);
  }

  /// Limpar todas as buscas recentes
  void clearRecentSearches() {
    _recentSearches.clear();
  }

  /// Obter dias até renovação dos créditos
  int get daysUntilCreditsRenew {
    if (creditsRenewDate == null) return 0;
    
    final now = DateTime.now();
    final difference = creditsRenewDate!.difference(now);
    
    return difference.inDays > 0 ? difference.inDays : 0;
  }

  /// Verificar se tem créditos suficientes
  bool hasSufficientCredits(int requiredCredits) {
    return userCredits >= requiredCredits;
  }

  /// Obter saudação baseada no horário
  String get greeting {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Bom dia';
    } else if (hour < 18) {
      return 'Boa tarde';
    } else {
      return 'Boa noite';
    }
  }

  /// Limpar erro
  void clearError() {
    _error.value = '';
  }
}