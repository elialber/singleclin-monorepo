import 'package:singleclin_mobile/data/services/api_client.dart';
import 'package:singleclin_mobile/features/clinic_discovery/models/clinic.dart';

/// Service for clinic-related API operations
class ClinicApiService {
  final ApiClient _apiClient = ApiClient.instance;

  /// Get all active clinics from the backend
  Future<List<Clinic>> getActiveClinics() async {
    try {
      final response = await _apiClient.get('/clinic/active');
      
      if (response.data is List) {
        final List<dynamic> clinicsData = response.data;
        return clinicsData
            .map((dto) => Clinic.fromBackendDto(dto as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching active clinics: $e');
      rethrow;
    }
  }

  /// Search clinics by name or address
  Future<List<Clinic>> searchClinics(String query) async {
    try {
      final response = await _apiClient.get(
        '/clinic/active',
        queryParameters: {
          'search': query,
        },
      );
      
      if (response.data is List) {
        final List<dynamic> clinicsData = response.data;
        return clinicsData
            .map((dto) => Clinic.fromBackendDto(dto as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error searching clinics: $e');
      return [];
    }
  }

  /// Get clinic by ID
  Future<Clinic?> getClinicById(String id) async {
    try {
      final response = await _apiClient.get('/clinic/$id');
      
      if (response.data != null) {
        return Clinic.fromBackendDto(response.data as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      print('Error fetching clinic by ID: $e');
      return null;
    }
  }

  /// Get clinics by type
  Future<List<Clinic>> getClinicsByType(ClinicType type) async {
    try {
      final response = await _apiClient.get(
        '/clinic/active',
        queryParameters: {
          'type': type.toString(),
        },
      );
      
      if (response.data is List) {
        final List<dynamic> clinicsData = response.data;
        return clinicsData
            .map((dto) => Clinic.fromBackendDto(dto as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching clinics by type: $e');
      return [];
    }
  }
}