import 'package:get/get.dart';
import 'package:singleclin_mobile/core/services/api_service.dart';
import 'package:singleclin_mobile/features/clinic_discovery/models/clinic.dart';
import 'package:singleclin_mobile/features/clinic_services/models/clinic_service.dart';

class ClinicServicesApi {
  static final ApiService _apiService = Get.find<ApiService>();

  static Future<List<Clinic>> getClinics() async {
    try {
      print('DEBUG: Making API call to get all clinics');
      // Use dev endpoint which doesn't require admin auth
      final response = await _apiService.get('/clinic/dev');

      print('DEBUG: API response: $response');

      if (response.statusCode == 200) {
        // Response is paginated: {items: [...], pageNumber, pageSize, totalPages, totalCount}
        final responseData = response.data;
        print('DEBUG: Response data type: ${responseData.runtimeType}');
        print(
          'DEBUG: Response keys: ${responseData is Map ? responseData.keys : 'Not a map'}',
        );

        final List<dynamic> data =
            responseData is Map && responseData.containsKey('items')
            ? responseData['items']
            : (responseData is List ? responseData : []);

        print('DEBUG: Data list length: ${data.length}');
        // Use fromBackendDto to properly parse backend response
        final clinics = data
            .map((json) => Clinic.fromBackendDto(json as Map<String, dynamic>))
            .toList();
        print('DEBUG: Converted ${clinics.length} clinics from API');
        return clinics;
      } else {
        throw Exception('Failed to load clinics: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: API error: $e');
      throw Exception('Error fetching clinics: $e');
    }
  }

  static Future<List<ClinicService>> getClinicServices(String clinicId) async {
    try {
      print('DEBUG: Making API call to get services for clinic: $clinicId');
      final response = await _apiService.get('/clinic/$clinicId/services');

      print('DEBUG: API response: $response');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final services = data
            .map((json) => ClinicService.fromJson(json))
            .toList();
        print('DEBUG: Converted ${services.length} services from API');
        return services;
      } else {
        throw Exception(
          'Failed to load clinic services: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('DEBUG: API error: $e');
      throw Exception('Error fetching clinic services: $e');
    }
  }

  static Future<Map<String, dynamic>> scheduleAppointment({
    required String clinicId,
    required String serviceId,
    required DateTime appointmentDate,
  }) async {
    try {
      final response = await _apiService.post(
        '/Appointments/schedule',
        data: {
          'ClinicId': clinicId,
          'ServiceId': serviceId,
          'ScheduledDate': appointmentDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'] ?? response.data;
      } else {
        throw Exception(
          'Failed to schedule appointment: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error scheduling appointment: $e');
    }
  }

  static Future<Map<String, dynamic>> confirmAppointment({
    required String confirmationToken,
  }) async {
    try {
      final response = await _apiService.post(
        '/Appointments/confirm',
        data: {'confirmationToken': confirmationToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'] ?? response.data;
      } else {
        throw Exception(
          'Failed to confirm appointment: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error confirming appointment: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserCredits(String userId) async {
    try {
      final response = await _apiService.get('/Appointments/my-credits');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load user credits: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user credits: $e');
    }
  }
}
