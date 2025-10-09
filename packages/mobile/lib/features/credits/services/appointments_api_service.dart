import 'package:get/get.dart';
import 'package:singleclin_mobile/core/services/api_service.dart';
import 'package:singleclin_mobile/features/credits/models/appointment_model.dart';

/// Service to fetch appointments for transactions/history view
class AppointmentsApiService {
  static ApiService get _apiService => Get.find<ApiService>();

  /// Get user's appointments (all or filtered by status)
  static Future<List<AppointmentModel>> getMyAppointments({
    bool? includeCompleted,
  }) async {
    try {
      print('DEBUG: Fetching appointments from API...');
      final queryParameters = <String, dynamic>{};
      if (includeCompleted != null) {
        queryParameters['includeCompleted'] = includeCompleted.toString();
      }

      // Try new endpoint first, fallback to old one
      final response = await _apiService.get(
        '/Appointments/my-appointments',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      print('DEBUG: API Response status: ${response.statusCode}');
      print('DEBUG: API Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle both direct array and nested data structure
        List<dynamic> appointmentsJson;
        if (data is Map<String, dynamic>) {
          print('DEBUG: Response is Map, keys: ${data.keys}');
          if (data.containsKey('data')) {
            appointmentsJson = data['data'] as List<dynamic>;
          } else if (data.containsKey('appointments')) {
            appointmentsJson = data['appointments'] as List<dynamic>;
          } else {
            appointmentsJson = [];
          }
        } else if (data is List) {
          print('DEBUG: Response is List with ${data.length} items');
          appointmentsJson = data;
        } else {
          print('DEBUG: Response is unknown type, returning empty');
          appointmentsJson = [];
        }

        print(
          'DEBUG: Parsing ${appointmentsJson.length} appointments from JSON',
        );
        final appointments = appointmentsJson
            .map(
              (json) => AppointmentModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        print('DEBUG: Successfully parsed ${appointments.length} appointments');
        return appointments;
      } else {
        throw Exception('Failed to load appointments: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error fetching appointments: $e');
      print('DEBUG: Stack trace: $stackTrace');
      
      // Re-throw the original exception for better error handling upstream
      rethrow;
    }
  }

  /// Get appointment by ID
  static Future<AppointmentModel?> getAppointmentById(
    String appointmentId,
  ) async {
    try {
      final response = await _apiService.get('/Appointments/$appointmentId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final appointmentJson = data.containsKey('data')
              ? data['data']
              : data;
          return AppointmentModel.fromJson(
            appointmentJson as Map<String, dynamic>,
          );
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load appointment: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error fetching appointment by ID: $e');
      throw Exception('Error fetching appointment: $e');
    }
  }
}
