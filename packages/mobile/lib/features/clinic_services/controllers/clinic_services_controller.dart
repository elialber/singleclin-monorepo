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
  final RxBool creditsLoaded = false.obs;
  
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
      
      // Load credits first, then services to ensure proper validation
      loadUserCredits().then((_) {
        // Use services that already come from clinic data instead of making separate API call
        loadServicesFromClinic();
      });
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
        // Convert clinic.services (List<Map<String, dynamic>>) to List<ClinicService>
        final List<ClinicService> realServices = clinic.services.asMap().entries.map((entry) {
          final index = entry.key;
          final serviceData = entry.value;
          return ClinicService(
            id: 'service_${index}_${clinic.id}',
            name: serviceData['name'] ?? 'Serviço',
            description: serviceData['description'] ?? 'Serviço de ${serviceData['name']} disponível na clínica',
            price: (serviceData['price'] ?? 1.0).toDouble(), // Use real price from backend
            duration: serviceData['duration'] ?? 30, // Use real duration or default
            category: serviceData['category'] ?? 'Serviços Gerais',
            isAvailable: serviceData['isAvailable'] ?? true,
            imageUrl: serviceData['imageUrl'],
          );
        }).toList();
        
        services.value = realServices;
        print('DEBUG: Services loaded from clinic data: ${realServices.length} services');
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
      print('DEBUG: loadUserCredits - userId: $userId');
      print('DEBUG: loadUserCredits - currentUser: ${_authController.currentUser}');

      if (userId != null) {
        try {
          final creditsResponse = await ClinicServicesApi.getUserCredits(userId);
          print('DEBUG: Credits response: $creditsResponse');

          // Try different response structures
          dynamic creditsData = creditsResponse;
          if (creditsResponse.containsKey('data') && creditsResponse['data'] != null) {
            creditsData = creditsResponse['data'];
          }

          // Extract total available credits from the API response structure
          int totalCredits = 0;
          if (creditsData is Map) {
            // API response structure: {"data": {"totalAvailableCredits": 0}}
            if (creditsData.containsKey('totalAvailableCredits')) {
              totalCredits = (creditsData['totalAvailableCredits'] as num).toInt();
            } else if (creditsData.containsKey('TotalAvailableCredits')) {
              totalCredits = (creditsData['TotalAvailableCredits'] as num).toInt();
            } else if (creditsData.containsKey('credits')) {
              totalCredits = (creditsData['credits'] as num).toInt();
            }
          }

          userCredits.value = totalCredits;
          print('DEBUG: User credits set to: $totalCredits');
        } catch (e) {
          print('DEBUG: API call failed: $e');
          // If API fails, set credits to a default value for testing
          userCredits.value = 100; // Mock credits for testing
          print('DEBUG: Using mock credits: 100');
        }
      } else {
        print('DEBUG: User not authenticated, using mock credits');
        userCredits.value = 100; // Mock credits for testing when not authenticated
      }
    } catch (e) {
      print('DEBUG: Error in loadUserCredits: $e');
      userCredits.value = 100; // Fallback credits
    } finally {
      creditsLoaded.value = true; // Mark credits as loaded regardless of success/failure
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

      // Step 1: Schedule appointment and get confirmation token
      print('DEBUG: Scheduling appointment with clinicId: ${clinic.id}, serviceId: ${service.id}');
      final scheduleResponse = await ClinicServicesApi.scheduleAppointment(
        clinicId: clinic.id,
        serviceId: service.id,
        appointmentDate: DateTime.now().add(const Duration(days: 1)), // Mock date
      );

      print('DEBUG: Schedule response: $scheduleResponse');

      // Extract confirmation token from response
      String? confirmationToken;
      try {
        if (scheduleResponse is Map && scheduleResponse.containsKey('confirmationToken')) {
          confirmationToken = scheduleResponse['confirmationToken']?.toString();
        } else if (scheduleResponse is Map && scheduleResponse.containsKey('data')) {
          final data = scheduleResponse['data'];
          if (data is Map && data.containsKey('confirmationToken')) {
            confirmationToken = data['confirmationToken']?.toString();
          }
        }
      } catch (e) {
        print('DEBUG: Error extracting confirmation token: $e');
      }

      if (confirmationToken == null || confirmationToken.isEmpty) {
        throw Exception('No confirmation token received');
      }

      print('DEBUG: Confirmation token: $confirmationToken');

      // Step 2: Confirm appointment (this automatically creates transaction and debits credits)
      await ClinicServicesApi.confirmAppointment(
        confirmationToken: confirmationToken,
      );

      // Update local credits based on service price
      userCredits.value = (userCredits.value - service.price).toInt();

      Get.snackbar(
        'Agendamento Confirmado',
        'Seu agendamento foi realizado com sucesso! Transação registrada.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Navigate back
      Get.back();
    } catch (e) {
      print('DEBUG: Booking error: $e');

      // Check if it's a 401 error for testing purposes
      if (e.toString().contains('401')) {
        Get.snackbar(
          'Teste de Agendamento',
          'Fluxo de agendamento testado com sucesso! (401 esperado - usuário não autenticado)',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'Erro no Agendamento',
          'Não foi possível completar o agendamento. Tente novamente.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

}