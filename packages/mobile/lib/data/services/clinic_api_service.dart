import 'package:singleclin_mobile/data/services/api_client.dart';
import 'package:singleclin_mobile/features/clinic_discovery/models/clinic.dart';

/// Service for clinic-related API operations
class ClinicApiService {
  final ApiClient _apiClient = ApiClient.instance;

  /// Get all active clinics from the backend
  Future<List<Clinic>> getActiveClinics() async {
    try {
      print('🌐 Fetching active clinics from API...');
      final response = await _apiClient.get('/Clinic/active');

      print('📊 API Response status: ${response.statusCode}');
      print('📋 API Response data type: ${response.data.runtimeType}');

      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> responseData = response.data;
        print('📄 Paginated response detected');

        if (responseData.containsKey('items') && responseData['items'] is List) {
          final List<dynamic> clinicsData = responseData['items'];
          print('✅ Found ${clinicsData.length} clinics from paginated API');
          print('📊 Total count: ${responseData['totalCount']}');
          print('📄 Page ${responseData['pageNumber']} of ${responseData['totalPages']}');

          final clinics = clinicsData
              .map((dto) {
                print('🏥 Processing clinic: ${dto['name'] ?? 'Unknown'}');
                return Clinic.fromBackendDto(dto as Map<String, dynamic>);
              })
              .toList();

          print('🎯 Successfully converted ${clinics.length} clinics');
          return clinics;
        } else {
          print('⚠️ Response structure does not contain items array');
          return [];
        }
      } else if (response.data is List) {
        // Fallback for direct array response
        final List<dynamic> clinicsData = response.data;
        print('✅ Found ${clinicsData.length} clinics from direct array API');

        final clinics = clinicsData
            .map((dto) {
              print('🏥 Processing clinic: ${dto['name'] ?? 'Unknown'}');
              return Clinic.fromBackendDto(dto as Map<String, dynamic>);
            })
            .toList();

        print('🎯 Successfully converted ${clinics.length} clinics');
        return clinics;
      }

      print('⚠️ No clinic data in response');
      return [];
    } catch (e) {
      print('❌ Error fetching active clinics: $e');
      print('🔍 Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Search clinics by name or address
  Future<List<Clinic>> searchClinics(String query) async {
    try {
      final response = await _apiClient.get(
        '/Clinic/active',
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
      final response = await _apiClient.get('/Clinic/$id');
      
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
        '/Clinic/active',
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