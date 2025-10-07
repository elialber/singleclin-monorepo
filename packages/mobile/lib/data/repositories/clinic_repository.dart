import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:singleclin_mobile/core/repositories/base_repository.dart';
import 'package:singleclin_mobile/core/services/cache_service.dart';
import 'package:singleclin_mobile/core/services/network_service.dart';
import 'package:singleclin_mobile/features/discovery/models/clinic_model.dart';

/// Repository for clinic data with offline-first capabilities
///
/// Handles clinic discovery, details, favorites, and search with
/// geographic filtering and offline support.
class ClinicRepository extends BaseRepository<ClinicModel> {
  ClinicRepository({
    required super.cacheService,
    required super.networkService,
    required super.dio,
  });

  @override
  String get boxName => 'clinics';

  @override
  int get cacheTtlMinutes => 120; // Clinic data refreshed every 2 hours

  @override
  bool get isOfflineCapable => true; // Clinics should be searchable offline

  @override
  Map<String, dynamic> toMap(ClinicModel clinic) => clinic.toJson();

  @override
  ClinicModel fromMap(Map<String, dynamic> map) => ClinicModel.fromJson(map);

  @override
  Future<ClinicModel?> fetchFromNetwork(String id) async {
    try {
      final response = await dio.get('/api/clinics/$id');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ClinicModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('❌ Failed to fetch clinic from network: $e');
      rethrow;
    }
  }

  @override
  Future<List<ClinicModel>> fetchListFromNetwork({
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (filters != null) ...filters,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      };

      final response = await dio.get(
        '/api/clinics',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> clinics = response.data['data']['clinics'] ?? [];
        return clinics.map((json) => ClinicModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Failed to fetch clinics list from network: $e');
      rethrow;
    }
  }

  @override
  Future<ClinicModel?> saveToNetwork(ClinicModel clinic, String? id) async {
    try {
      final data = clinic.toJson();
      Response response;

      if (id != null) {
        // Update existing clinic (admin only)
        response = await dio.put('/api/clinics/$id', data: data);
      } else {
        // Create new clinic (admin only)
        response = await dio.post('/api/clinics', data: data);
      }

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ClinicModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('❌ Failed to save clinic to network: $e');
      rethrow;
    }
  }

  @override
  Future<bool> deleteFromNetwork(String id) async {
    try {
      final response = await dio.delete('/api/clinics/$id');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('❌ Failed to delete clinic from network: $e');
      rethrow;
    }
  }

  // Clinic-specific methods

  /// Search clinics by location with offline support
  Future<List<ClinicModel>> searchByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 20,
    bool offlineOnly = false,
  }) async {
    final filters = {
      'lat': latitude,
      'lng': longitude,
      'radius': radiusKm,
      'search_type': 'location',
    };

    final clinics = await getMany(
      filters: filters,
      limit: limit,
      offlineOnly: offlineOnly,
    );

    // If we have offline data, filter by distance
    if (offlineOnly || clinics.isNotEmpty) {
      return _filterByDistance(clinics, latitude, longitude, radiusKm);
    }

    return clinics;
  }

  /// Search clinics by text query with offline fallback
  Future<List<ClinicModel>> searchByText({
    required String query,
    double? latitude,
    double? longitude,
    double radiusKm = 50.0,
    int limit = 20,
    bool offlineOnly = false,
  }) async {
    final filters = <String, dynamic>{
      'q': query,
      'search_type': 'text',
      if (latitude != null) 'lat': latitude,
      if (longitude != null) 'lng': longitude,
      if (latitude != null && longitude != null) 'radius': radiusKm,
    };

    if (offlineOnly || !networkService.isConnected) {
      // Perform offline text search
      return _performOfflineTextSearch(
        query,
        latitude,
        longitude,
        radiusKm,
        limit,
      );
    }

    return getMany(filters: filters, limit: limit, offlineOnly: offlineOnly);
  }

  /// Get clinics by specialty
  Future<List<ClinicModel>> getBySpecialty({
    required String specialty,
    double? latitude,
    double? longitude,
    double radiusKm = 20.0,
    int limit = 20,
    bool offlineOnly = false,
  }) async {
    final filters = {
      'specialty': specialty,
      'search_type': 'specialty',
      if (latitude != null) 'lat': latitude,
      if (longitude != null) 'lng': longitude,
      if (latitude != null && longitude != null) 'radius': radiusKm,
    };

    final clinics = await getMany(
      filters: filters,
      limit: limit,
      offlineOnly: offlineOnly,
    );

    // Filter by specialty offline if needed
    if (offlineOnly || !networkService.isConnected) {
      return clinics
          .where(
            (clinic) => clinic.specialties.any(
              (s) => s.toLowerCase().contains(specialty.toLowerCase()),
            ),
          )
          .toList();
    }

    return clinics;
  }

  /// Get featured/promoted clinics
  Future<List<ClinicModel>> getFeaturedClinics({
    double? latitude,
    double? longitude,
    int limit = 10,
    bool offlineOnly = false,
  }) async {
    final filters = {
      'featured': true,
      'search_type': 'featured',
      if (latitude != null) 'lat': latitude,
      if (longitude != null) 'lng': longitude,
    };

    return getMany(filters: filters, limit: limit, offlineOnly: offlineOnly);
  }

  /// Get recently viewed clinics (local only)
  Future<List<ClinicModel>> getRecentlyViewed({int limit = 10}) async {
    try {
      final recentIds = await _getRecentlyViewedIds();
      final clinics = <ClinicModel>[];

      for (final id in recentIds.take(limit)) {
        final clinic = await get(id, offlineOnly: true);
        if (clinic != null) {
          clinics.add(clinic);
        }
      }

      return clinics;
    } catch (e) {
      print('❌ Failed to get recently viewed clinics: $e');
      return [];
    }
  }

  /// Mark clinic as viewed (for recent history)
  Future<void> markAsViewed(String clinicId) async {
    try {
      final recentIds = await _getRecentlyViewedIds();

      // Remove if already exists and add to front
      recentIds.remove(clinicId);
      recentIds.insert(0, clinicId);

      // Keep only last 20 items
      final limitedIds = recentIds.take(20).toList();

      await cacheService.putList(
        boxName,
        'recently_viewed',
        limitedIds
            .map(
              (id) => {'id': id, 'viewedAt': DateTime.now().toIso8601String()},
            )
            .toList(),
      );
    } catch (e) {
      print('❌ Failed to mark clinic as viewed: $e');
    }
  }

  /// Get user's favorite clinics
  Future<List<ClinicModel>> getFavorites({bool offlineOnly = true}) async {
    try {
      final favoriteIds = await _getFavoriteIds();
      final clinics = <ClinicModel>[];

      for (final id in favoriteIds) {
        final clinic = await get(id, offlineOnly: offlineOnly);
        if (clinic != null) {
          clinics.add(clinic);
        }
      }

      return clinics;
    } catch (e) {
      print('❌ Failed to get favorite clinics: $e');
      return [];
    }
  }

  /// Add clinic to favorites
  Future<void> addToFavorites(String clinicId) async {
    try {
      final favoriteIds = await _getFavoriteIds();

      if (!favoriteIds.contains(clinicId)) {
        favoriteIds.add(clinicId);
        await _saveFavoriteIds(favoriteIds);

        // Try to sync with server if online
        if (networkService.isConnected) {
          await _syncFavoritesToServer(favoriteIds);
        }
      }
    } catch (e) {
      print('❌ Failed to add clinic to favorites: $e');
    }
  }

  /// Remove clinic from favorites
  Future<void> removeFromFavorites(String clinicId) async {
    try {
      final favoriteIds = await _getFavoriteIds();

      if (favoriteIds.remove(clinicId)) {
        await _saveFavoriteIds(favoriteIds);

        // Try to sync with server if online
        if (networkService.isConnected) {
          await _syncFavoritesToServer(favoriteIds);
        }
      }
    } catch (e) {
      print('❌ Failed to remove clinic from favorites: $e');
    }
  }

  /// Check if clinic is in favorites
  Future<bool> isFavorite(String clinicId) async {
    final favoriteIds = await _getFavoriteIds();
    return favoriteIds.contains(clinicId);
  }

  /// Preload clinics for offline usage (by area)
  Future<void> preloadClinicsForArea({
    required double latitude,
    required double longitude,
    double radiusKm = 25.0,
  }) async {
    try {
      if (!networkService.isConnected) return;

      print(
        '📥 Preloading clinics for area (lat: $latitude, lng: $longitude, radius: ${radiusKm}km)',
      );

      // Fetch clinics in the area
      final clinics = await searchByLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: 100,
      );

      print('✅ Preloaded ${clinics.length} clinics for offline usage');
    } catch (e) {
      print('❌ Failed to preload clinics: $e');
    }
  }

  // Private helper methods

  List<ClinicModel> _filterByDistance(
    List<ClinicModel> clinics,
    double userLat,
    double userLng,
    double radiusKm,
  ) {
    return clinics.where((clinic) {
      final distance = clinic.distanceFrom(userLat, userLng);
      return distance <= radiusKm;
    }).toList()..sort(
      (a, b) => a
          .distanceFrom(userLat, userLng)
          .compareTo(b.distanceFrom(userLat, userLng)),
    );
  }

  Future<List<ClinicModel>> _performOfflineTextSearch(
    String query,
    double? latitude,
    double? longitude,
    double radiusKm,
    int limit,
  ) async {
    try {
      // Get all cached clinics
      final allClinics = await getMany(offlineOnly: true);

      // Filter by text query
      final lowerQuery = query.toLowerCase();
      var filteredClinics = allClinics.where((clinic) {
        return clinic.name.toLowerCase().contains(lowerQuery) ||
            clinic.description.toLowerCase().contains(lowerQuery) ||
            clinic.address.toLowerCase().contains(lowerQuery) ||
            clinic.specialties.any((s) => s.toLowerCase().contains(lowerQuery));
      }).toList();

      // Filter by location if provided
      if (latitude != null && longitude != null) {
        filteredClinics = _filterByDistance(
          filteredClinics,
          latitude,
          longitude,
          radiusKm,
        );
      }

      return filteredClinics.take(limit).toList();
    } catch (e) {
      print('❌ Offline text search failed: $e');
      return [];
    }
  }

  Future<List<String>> _getRecentlyViewedIds() async {
    final data = await cacheService.getList(boxName, 'recently_viewed');
    return data.map((item) => item['id'] as String).toList();
  }

  Future<List<String>> _getFavoriteIds() async {
    final data = await cacheService.getList(boxName, 'favorites');
    return data.map((item) => item as String).toList();
  }

  Future<void> _saveFavoriteIds(List<String> favoriteIds) async {
    await cacheService.putList(
      boxName,
      'favorites',
      favoriteIds.map((id) => id).toList(),
    );
  }

  Future<void> _syncFavoritesToServer(List<String> favoriteIds) async {
    try {
      await dio.put(
        '/api/user/favorites/clinics',
        data: {'clinicIds': favoriteIds},
      );
    } catch (e) {
      print('⚠️ Failed to sync favorites to server: $e');
      // Not critical, will retry next time
    }
  }
}
