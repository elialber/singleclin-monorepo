import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/clinic_service.dart';
import '../services/clinic_services_api.dart';
import '../../clinic_discovery/models/clinic.dart';
import '../../../presentation/controllers/auth_controller.dart';

class ClinicServicesController extends GetxController {
  final RxList<ClinicService> services = <ClinicService>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxInt userCredits = 0.obs;
  
  Clinic? _clinic;
  final AuthController _authController = Get.find<AuthController>();
  
  Clinic get clinic {
    if (_clinic == null) {
      throw Exception('Clinic data not initialized');
    }
    return _clinic!;
  }

  @override
  void onInit() {
    super.onInit();
    
    print('DEBUG: ClinicServicesController onInit called');
    
    try {
      // Get clinic data from arguments
      final arguments = Get.arguments;
      print('DEBUG: Arguments received: $arguments');
      print('DEBUG: Arguments type: ${arguments.runtimeType}');
      
      if (arguments == null) {
        print('DEBUG: Arguments is null');
        _handleNavigationError('Dados da clínica não encontrados (null)');
        return;
      }
      
      if (arguments is! Clinic) {
        print('DEBUG: Arguments is not Clinic type');
        _handleNavigationError('Dados da clínica inválidos');
        return;
      }
      
      _clinic = arguments;
      print('DEBUG: Clinic set successfully: ${_clinic!.name}');
      
      // Use services that already come from clinic data instead of making separate API call
      loadServicesFromClinic();
      loadUserCredits();
    } catch (e) {
      print('DEBUG: Exception in onInit: $e');
      _handleNavigationError('Erro ao inicializar: $e');
    }
  }
  
  void _handleNavigationError(String message) {
    print('DEBUG: Handling navigation error: $message');
    Get.back();
    Get.snackbar(
      'Erro',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  /// Load services from clinic data (no API call needed)
  void loadServicesFromClinic() {
    print('DEBUG: loadServicesFromClinic() called');
    try {
      isLoading.value = true;
      error.value = '';
      print('DEBUG: Loading set to true');
      
      // Check if clinic has services data from backend
      if (clinic.services.isNotEmpty) {
        // TODO: Convert clinic.services (List<String>) to List<ClinicService>
        // For now, create mock services based on the service names from clinic
        final List<ClinicService> mockServices = clinic.services.asMap().entries.map((entry) {
          final index = entry.key;
          final serviceName = entry.value;
          return ClinicService(
            id: 'service_${index}_${clinic.id}',
            name: serviceName,
            description: 'Serviço de $serviceName disponível na clínica',
            price: 1.0 + (index * 0.5), // Mock prices (1-3 SG créditos)
            duration: 30 + (index * 15), // Mock durations
            category: 'Serviços Gerais',
            isAvailable: true,
            imageUrl: null,
          );
        }).toList();
        
        services.value = mockServices;
        print('DEBUG: Services loaded from clinic data: ${mockServices.length} services');
      } else {
        print('DEBUG: No services found in clinic data, trying API fallback');
        loadServices();
        return;
      }
    } catch (e) {
      print('DEBUG: Error processing clinic services: $e');
      error.value = 'Erro ao processar serviços da clínica: $e';
      services.value = [];
    } finally {
      isLoading.value = false;
      print('DEBUG: Loading set to false');
      print('DEBUG: Final services count: ${services.length}');
    }
  }

  /// Fallback method to load services from API (only used if clinic data doesn't have services)
  Future<void> loadServices() async {
    print('DEBUG: loadServices() API fallback called');
    try {
      isLoading.value = true;
      error.value = '';
      print('DEBUG: Loading set to true');
      
      print('DEBUG: Calling API for clinic ID: ${clinic.id}');
      final loadedServices = await ClinicServicesApi.getClinicServices(clinic.id);
      services.value = loadedServices;
      print('DEBUG: Services loaded from API: ${loadedServices.length} services');
    } catch (e) {
      print('DEBUG: API error: $e');
      error.value = 'Erro ao carregar serviços: $e';
      services.value = [];
    } finally {
      isLoading.value = false;
      print('DEBUG: Loading set to false');
      print('DEBUG: Final services count: ${services.length}');
    }
  }

  Future<void> loadUserCredits() async {
    try {
      final userId = _authController.currentUser?.id;
      if (userId != null) {
        final creditsResponse = await ClinicServicesApi.getUserCredits(userId);
        userCredits.value = creditsResponse['credits'] ?? 0;
      } else {
        print('DEBUG: User not authenticated, using mock credits');
        userCredits.value = 0; // No credits available if not authenticated
      }
    } catch (e) {
      print('DEBUG: Error loading credits: $e');
      userCredits.value = 0;
    }
  }

  Future<void> refreshServices() async {
    loadServicesFromClinic();
    await loadUserCredits();
  }

  void showBookingConfirmation(ClinicService service) {
    Get.dialog(
      AlertDialog(
        title: Text('Confirmar Agendamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Você confirma o agendamento de ${service.name}?'),
            const SizedBox(height: 8),
            Text(
              'Preço: ${service.formattedPrice}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              'Duração: ${service.formattedDuration}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              'Seus créditos: ${userCredits.value}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _confirmBooking(service),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking(ClinicService service) async {
    try {
      Get.back(); // Close dialog
      isLoading.value = true;

      // Check if user has enough credits
      if (userCredits.value < service.price) {
        Get.snackbar(
          'Créditos Insuficientes',
          'Você não possui créditos suficientes para este serviço.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Get actual user ID
      final userId = _authController.currentUser?.id ?? 'unknown';
      
      // Book the service
      final bookingSuccess = await ClinicServicesApi.bookService(
        clinicId: clinic.id,
        serviceId: service.id,
        userId: userId,
        appointmentDate: DateTime.now().add(const Duration(days: 1)), // Mock date
      );

      if (bookingSuccess) {
        // Consume credits
        final consumeSuccess = await ClinicServicesApi.consumeCredits(
          userId: userId,
          serviceId: service.id,
          amount: service.price,
        );

        if (consumeSuccess) {
          userCredits.value = (userCredits.value - service.price).toInt();
          
          Get.snackbar(
            'Agendamento Confirmado',
            'Seu agendamento foi realizado com sucesso!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );

          // Navigate back or to confirmation screen
          Get.back();
        }
      }
    } catch (e) {
      Get.snackbar(
        'Erro no Agendamento',
        'Não foi possível completar o agendamento. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

}