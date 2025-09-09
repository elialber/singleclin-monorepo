import 'package:get/get.dart';
import '../models/clinic_service.dart';
import '../../../core/services/api_service.dart';

class ClinicServicesApi {
  static final ApiService _apiService = Get.find<ApiService>();
  
  static Future<List<ClinicService>> getClinicServices(String clinicId) async {
    try {
      print('DEBUG: Making API call to get services for clinic: $clinicId');
      final response = await _apiService.get('/clinics/$clinicId/services');
      
      print('DEBUG: API response: $response');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final services = data.map((json) => ClinicService.fromJson(json)).toList();
        print('DEBUG: Converted ${services.length} services from API');
        return services;
      } else {
        throw Exception('Failed to load clinic services: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: API error: $e');
      throw Exception('Error fetching clinic services: $e');
    }
  }

  static Future<bool> bookService({
    required String clinicId,
    required String serviceId,
    required String userId,
    required DateTime appointmentDate,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post('/appointments', data: {
        'clinicId': clinicId,
        'serviceId': serviceId,
        'userId': userId,
        'appointmentDate': appointmentDate.toIso8601String(),
        'notes': notes,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to book service: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error booking service: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserCredits(String userId) async {
    try {
      final response = await _apiService.get('/users/$userId/credits');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load user credits: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user credits: $e');
    }
  }

  static Future<bool> consumeCredits({
    required String userId,
    required String serviceId,
    required double amount,
  }) async {
    try {
      final response = await _apiService.post('/users/$userId/credits/consume', data: {
        'serviceId': serviceId,
        'amount': amount,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to consume credits: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error consuming credits: $e');
    }
  }
}