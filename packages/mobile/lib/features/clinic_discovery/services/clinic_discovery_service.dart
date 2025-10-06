import 'package:geolocator/geolocator.dart';
import 'package:singleclin_mobile/data/services/clinic_api_service.dart';
import 'package:singleclin_mobile/features/clinic_discovery/models/clinic.dart';

class ClinicDiscoveryService {
  final ClinicApiService _clinicApiService = ClinicApiService();

  // Cache for clinics to avoid excessive API calls
  List<Clinic>? _cachedClinics;
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiration = Duration(minutes: 5);

  Future<List<Clinic>> getNearbyClinics({Position? position}) async {
    try {
      // Check if we have cached data that's still valid
      if (_cachedClinics != null &&
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheExpiration) {
        print('📦 Using cached clinic data');
        return List.from(_cachedClinics!);
      }

      print('🌐 Fetching clinics from backend API...');

      // Fetch real clinics from backend
      final clinics = await _clinicApiService.getActiveClinics();

      // Cache the results
      _cachedClinics = clinics;
      _lastFetchTime = DateTime.now();

      print('✅ Fetched ${clinics.length} clinics from backend');

      // If no clinics from backend, return empty list
      if (clinics.isEmpty) {
        print('⚠️ No clinics from backend, returning empty list');
        return [];
      }

      return clinics;
    } catch (e) {
      print('❌ Error fetching clinics from backend: $e');
      // Return empty list on error
      print('🔄 Returning empty list due to error');
      return [];
    }
  }

  Future<List<Clinic>> searchClinicsByName(String name) async {
    try {
      print('🔍 Searching clinics by name: $name');

      // Use API search if available
      final searchResults = await _clinicApiService.searchClinics(name);

      if (searchResults.isNotEmpty) {
        return searchResults;
      }

      // Fallback to local search in cached data
      final allClinics = await getNearbyClinics();
      final query = name.toLowerCase();

      return allClinics.where((clinic) {
        return clinic.name.toLowerCase().contains(query) ||
            clinic.address.toLowerCase().contains(query);
      }).toList();
    } catch (e) {
      print('❌ Error searching clinics: $e');
      // Return empty list on error
      await Future.delayed(const Duration(milliseconds: 500));
      return [];
    }
  }

  Future<List<Clinic>> getClinicsBySpecialization(String specialization) async {
    try {
      print('🔍 Searching clinics by specialization: $specialization');

      // Use real API when available
      final allClinics = await getNearbyClinics();

      return allClinics.where((clinic) {
        return clinic.specializations.any(
          (spec) => spec.toLowerCase() == specialization.toLowerCase(),
        );
      }).toList();
    } catch (e) {
      print('❌ Error searching clinics by specialization: $e');
      return [];
    }
  }

  Future<List<Clinic>> getAvailableClinics() async {
    try {
      print('🔍 Getting available clinics');

      // Use real API when available
      final allClinics = await getNearbyClinics();

      return allClinics.where((clinic) => clinic.isAvailable).toList();
    } catch (e) {
      print('❌ Error getting available clinics: $e');
      return [];
    }
  }

  Future<List<Clinic>> getFavoriteClinics(List<String> favoriteIds) async {
    try {
      print('🔍 Getting favorite clinics for IDs: $favoriteIds');

      // Use real API when available
      final allClinics = await getNearbyClinics();

      return allClinics
          .where((clinic) => favoriteIds.contains(clinic.id))
          .toList();
    } catch (e) {
      print('❌ Error getting favorite clinics: $e');
      return [];
    }
  }

  Future<Clinic?> getClinicById(String id) async {
    try {
      print('🏥 Fetching clinic by ID: $id');

      // Try to get from API first
      final clinic = await _clinicApiService.getClinicById(id);

      if (clinic != null) {
        return clinic;
      }

      // Fallback to cached data
      final allClinics = await getNearbyClinics();
      try {
        return allClinics.firstWhere((clinic) => clinic.id == id);
      } catch (e) {
        return null;
      }
    } catch (e) {
      print('❌ Error fetching clinic by ID: $e');
      // Return null if not found
      await Future.delayed(const Duration(milliseconds: 300));
      return null;
    }
  }

  Future<List<String>> getAvailableSpecializations() async {
    try {
      print('🔍 Getting available specializations');

      // Use real API when available
      final allClinics = await getNearbyClinics();

      final Set<String> specializations = {};
      for (final clinic in allClinics) {
        specializations.addAll(clinic.specializations);
      }

      return specializations.toList()..sort();
    } catch (e) {
      print('❌ Error getting specializations: $e');
      return [];
    }
  }

  Future<List<Clinic>> getEmergencyClinics() async {
    try {
      print('🚨 Getting emergency clinics');

      // Use real API when available
      final allClinics = await getNearbyClinics();

      // Return clinics that are available now or have emergency services
      return allClinics.where((clinic) {
        return clinic.isAvailable &&
            (clinic.services.any(
                      (service) =>
                          (service['name'] ?? '').toLowerCase().contains(
                            'urgência',
                          ) ||
                          (service['name'] ?? '').toLowerCase().contains(
                            'pronto socorro',
                          ) ||
                          (service['name'] ?? '').toLowerCase().contains(
                            'emergência',
                          ),
                    ) ||
                    clinic.nextAvailableSlot?.isBefore(
                      DateTime.now().add(const Duration(hours: 2)),
                    ) ??
                false);
      }).toList();
    } catch (e) {
      print('❌ Error getting emergency clinics: $e');
      return [];
    }
  }

  // Method to update clinic availability - would typically call API
  Future<bool> updateClinicAvailability(
    String clinicId,
    bool isAvailable,
  ) async {
    try {
      print('🔄 Updating clinic availability: $clinicId to $isAvailable');

      // In a real implementation, this would call the backend API
      // For now, we'll simulate success since this would require
      // a PATCH /clinic/{id}/availability endpoint on the backend
      await Future.delayed(const Duration(milliseconds: 300));

      // Clear cache to force refresh on next request
      clearCache();

      return true;
    } catch (e) {
      print('❌ Error updating clinic availability: $e');
      return false;
    }
  }

  // Method to book appointment - would typically call API
  Future<bool> bookAppointment({
    required String clinicId,
    required DateTime dateTime,
    required String patientId,
    String? notes,
  }) async {
    try {
      print(
        '📅 Booking appointment at clinic $clinicId for patient $patientId',
      );

      // Verify clinic exists and is available
      final clinic = await getClinicById(clinicId);
      if (clinic == null) {
        print('❌ Clinic not found: $clinicId');
        return false;
      }

      if (!clinic.isAvailable) {
        print('❌ Clinic not available: $clinicId');
        return false;
      }

      // In a real implementation, this would make an API call to:
      // POST /appointment with { clinicId, dateTime, patientId, notes }
      // For now, we'll simulate the booking process

      await Future.delayed(const Duration(milliseconds: 1000));

      print('✅ Appointment booking simulation successful');
      return true;
    } catch (e) {
      print('❌ Error booking appointment: $e');
      return false;
    }
  }

  /// Clear the clinic cache to force fresh data on next request
  void clearCache() {
    _cachedClinics = null;
    _lastFetchTime = null;
    print('🗑️ Clinic cache cleared');
  }

  /// Check if backend API is available
  Future<bool> isBackendAvailable() async {
    try {
      await _clinicApiService.getActiveClinics();
      return true;
    } catch (e) {
      return false;
    }
  }
}
