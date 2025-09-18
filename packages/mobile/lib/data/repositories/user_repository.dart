import 'package:dio/dio.dart';
import '../../core/repositories/base_repository.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/network_service.dart';
import '../models/user_model.dart';

/// Repository for user data with offline-first capabilities
///
/// Handles user profile, preferences, and authentication-related data
/// with automatic caching and offline support.
class UserRepository extends BaseRepository<UserModel> {
  UserRepository({
    required CacheService cacheService,
    required NetworkService networkService,
    required Dio dio,
  }) : super(
          cacheService: cacheService,
          networkService: networkService,
          dio: dio,
        );

  @override
  String get boxName => 'users';

  @override
  int get cacheTtlMinutes => 30; // User data refreshed every 30 minutes

  @override
  bool get isOfflineCapable => true; // User profile should always be available offline

  @override
  Map<String, dynamic> toMap(UserModel user) => user.toJson();

  @override
  UserModel fromMap(Map<String, dynamic> map) => UserModel.fromJson(map);

  @override
  Future<UserModel?> fetchFromNetwork(String id) async {
    try {
      final response = await _dio.get('/api/user/$id');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('❌ Failed to fetch user from network: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> fetchListFromNetwork({
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

      final response = await _dio.get('/api/users', queryParameters: queryParams);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> users = response.data['data']['users'] ?? [];
        return users.map((json) => UserModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Failed to fetch users list from network: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel?> saveToNetwork(UserModel user, String? id) async {
    try {
      final data = user.toJson();
      Response response;

      if (id != null) {
        // Update existing user
        response = await _dio.put('/api/user/$id', data: data);
      } else {
        // Create new user
        response = await _dio.post('/api/user', data: data);
      }

      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('❌ Failed to save user to network: $e');
      rethrow;
    }
  }

  @override
  Future<bool> deleteFromNetwork(String id) async {
    try {
      final response = await _dio.delete('/api/user/$id');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('❌ Failed to delete user from network: $e');
      rethrow;
    }
  }

  // User-specific methods

  /// Get current user profile (commonly used method)
  Future<UserModel?> getCurrentUser({bool forceRefresh = false}) async {
    // This would typically get the current user ID from auth service
    final currentUserId = await _getCurrentUserId();
    if (currentUserId == null) return null;

    return await get(currentUserId, forceRefresh: forceRefresh);
  }

  /// Update current user profile
  Future<UserModel?> updateCurrentUser(UserModel user) async {
    final currentUserId = await _getCurrentUserId();
    if (currentUserId == null) return null;

    return await save(user, currentUserId);
  }

  /// Search users by name or email
  Future<List<UserModel>> searchUsers(String query, {
    int limit = 20,
    bool offlineOnly = false,
  }) async {
    final filters = {
      'search': query,
    };

    return await getMany(
      filters: filters,
      limit: limit,
      offlineOnly: offlineOnly,
    );
  }

  /// Get users by role
  Future<List<UserModel>> getUsersByRole(String role, {
    int? limit,
    bool offlineOnly = false,
  }) async {
    final filters = {
      'role': role,
    };

    return await getMany(
      filters: filters,
      limit: limit,
      offlineOnly: offlineOnly,
    );
  }

  /// Get favorite/recently viewed users
  Future<List<UserModel>> getFavoriteUsers({bool offlineOnly = false}) async {
    // This could be a cached list of frequently accessed users
    return await getMany(
      filters: {'favorites': true},
      offlineOnly: offlineOnly,
    );
  }

  /// Cache user preferences locally
  Future<void> cacheUserPreferences(String userId, Map<String, dynamic> preferences) async {
    final cacheKey = getCacheKey('${userId}_preferences');
    await _cacheService.put(boxName, cacheKey, preferences);
  }

  /// Get cached user preferences
  Future<Map<String, dynamic>?> getCachedUserPreferences(String userId) async {
    final cacheKey = getCacheKey('${userId}_preferences');
    return await _cacheService.get(boxName, cacheKey);
  }

  /// Preload critical user data for offline usage
  Future<void> preloadCriticalUserData(String userId) async {
    try {
      // Load user profile
      await get(userId, forceRefresh: true);

      // Load user preferences
      await _preloadUserPreferences(userId);

      // Load recent activity or other critical data
      await _preloadUserActivity(userId);

      print('✅ Preloaded critical data for user: $userId');
    } catch (e) {
      print('❌ Failed to preload user data: $e');
    }
  }

  // Private helper methods

  Future<String?> _getCurrentUserId() async {
    // This would typically come from an auth service
    // For now, return a placeholder
    // TODO: Integrate with actual auth service
    return 'current_user_id';
  }

  Future<void> _preloadUserPreferences(String userId) async {
    try {
      final response = await _dio.get('/api/user/$userId/preferences');
      if (response.statusCode == 200) {
        await cacheUserPreferences(userId, response.data['data']);
      }
    } catch (e) {
      print('❌ Failed to preload user preferences: $e');
    }
  }

  Future<void> _preloadUserActivity(String userId) async {
    try {
      final response = await _dio.get('/api/user/$userId/activity',
        queryParameters: {'limit': 50});

      if (response.statusCode == 200) {
        final cacheKey = getCacheKey('${userId}_activity');
        await _cacheService.putList(boxName, cacheKey,
          List<Map<String, dynamic>>.from(response.data['data']));
      }
    } catch (e) {
      print('❌ Failed to preload user activity: $e');
    }
  }

  /// Custom sync method for user-specific logic
  @override
  Future<void> _syncCachedData() async {
    try {
      // Sync current user data first (highest priority)
      final currentUserId = await _getCurrentUserId();
      if (currentUserId != null) {
        await get(currentUserId, forceRefresh: true);
      }

      // Sync recently accessed users
      final recentUsers = await _getRecentlyAccessedUsers();
      for (final userId in recentUsers) {
        await get(userId, forceRefresh: true);
      }

      print('✅ User data sync completed');
    } catch (e) {
      print('❌ User data sync failed: $e');
    }
  }

  Future<List<String>> _getRecentlyAccessedUsers() async {
    // Return list of recently accessed user IDs based on cache metadata
    final keys = await _cacheService.getKeys(boxName);

    // Filter out non-user keys (preferences, activity, etc.)
    return keys
        .where((key) => !key.contains('preferences') && !key.contains('activity'))
        .take(10) // Limit to most recent 10 users
        .toList();
  }
}