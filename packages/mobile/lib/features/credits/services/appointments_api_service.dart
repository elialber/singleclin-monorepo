import 'package:singleclin_mobile/core/services/api_service.dart';
import 'package:singleclin_mobile/features/credits/models/appointment_model.dart';

/// Service to fetch appointments for transactions/history view
class AppointmentsApiService {
  static final ApiService _apiService = ApiService();

  /// Get user's appointments (all or filtered by status)
  static Future<List<AppointmentModel>> getMyAppointments({
    bool? includeCompleted,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (includeCompleted != null) {
        queryParameters['includeCompleted'] = includeCompleted.toString();
      }

      final response = await _apiService.get(
        '/Appointments/my-appointments',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle both direct array and nested data structure
        List<dynamic> appointmentsJson;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            appointmentsJson = data['data'] as List<dynamic>;
          } else if (data.containsKey('appointments')) {
            appointmentsJson = data['appointments'] as List<dynamic>;
          } else {
            appointmentsJson = [];
          }
        } else if (data is List) {
          appointmentsJson = data;
        } else {
          appointmentsJson = [];
        }

        return appointmentsJson
            .map((json) => AppointmentModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load appointments: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error fetching appointments: $e');
      throw Exception('Error fetching appointments: $e');
    }
  }

  /// Get appointment by ID
  static Future<AppointmentModel?> getAppointmentById(String appointmentId) async {
    try {
      final response = await _apiService.get(
        '/Appointments/$appointmentId',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final appointmentJson = data.containsKey('data') ? data['data'] : data;
          return AppointmentModel.fromJson(appointmentJson as Map<String, dynamic>);
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

