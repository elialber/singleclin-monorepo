import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;

import 'package:singleclin_mobile/core/constants/api_constants.dart';
import 'package:singleclin_mobile/core/constants/app_constants.dart';
import 'package:singleclin_mobile/core/errors/api_exceptions.dart';
import 'package:singleclin_mobile/core/services/storage_service.dart';
import 'package:singleclin_mobile/data/models/user_model.dart';
import 'package:singleclin_mobile/data/services/api_client.dart';

/// User API service for backend communication
///
/// This service demonstrates how to use the ApiClient with automatic
/// JWT authentication for user-related API operations.
class UserApiService {
  final ApiClient _apiClient = ApiClient.instance;
  final StorageService _storageService = getx.Get.find<StorageService>();

  /// Get current user profile
  Future<UserModel> getCurrentUserProfile() async {
    try {
      final Response response = await _apiClient.get(
        ApiConstants.profileEndpoint,
      );

      if (response.data == null) {
        throw const GenericApiException('No user data received', 'no_data');
      }

      return UserModel.fromJson((response.data as Map<String, dynamic>)[ApiConstants.dataKey] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw GenericApiException(
        e.message ?? 'Failed to get user profile',
        'get_profile_error',
      );
    }
  }

  /// Update user profile
  Future<UserModel> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (displayName != null) {
        data['displayName'] = displayName;
      }
      if (phoneNumber != null) {
        data['phoneNumber'] = phoneNumber;
      }
      if (photoUrl != null) {
        data['photoUrl'] = photoUrl;
      }

      final Response response = await _apiClient.put(
        ApiConstants.updateProfileEndpoint,
        data: data,
      );

      if (response.data == null) {
        throw const GenericApiException('No user data received', 'no_data');
      }

      return UserModel.fromJson((response.data as Map<String, dynamic>)[ApiConstants.dataKey] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw GenericApiException(
        e.message ?? 'Failed to update user profile',
        'update_profile_error',
      );
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.changePasswordEndpoint,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw GenericApiException(
        e.message ?? 'Failed to change password',
        'change_password_error',
      );
    }
  }

  /// Delete user account
  Future<void> deleteAccount({required String password}) async {
    try {
      await _apiClient.delete(
        ApiConstants.deleteAccountEndpoint,
        data: {'password': password},
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw GenericApiException(
        e.message ?? 'Failed to delete account',
        'delete_account_error',
      );
    }
  }

  /// Upload user profile photo
  Future<UserModel> uploadProfilePhoto(String filePath) async {
    try {
      final Response response = await _apiClient.uploadFile(
        '/auth/profile/photo',
        filePath,
        fieldName: 'photo',
      );

      if (response.data == null) {
        throw const GenericApiException('No user data received', 'no_data');
      }

      return UserModel.fromJson((response.data as Map<String, dynamic>)[ApiConstants.dataKey] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw GenericApiException(
        e.message ?? 'Failed to upload profile photo',
        'upload_photo_error',
      );
    }
  }

  /// Get user by ID (admin only)
  Future<UserModel> getUserById(int userId) async {
    try {
      final Response response = await _apiClient.get(
        '${ApiConstants.userByIdEndpoint}/$userId',
      );

      if (response.data == null) {
        throw const GenericApiException('No user data received', 'no_data');
      }

      return UserModel.fromJson((response.data as Map<String, dynamic>)[ApiConstants.dataKey] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw GenericApiException(
        e.message ?? 'Failed to get user',
        'get_user_error',
      );
    }
  }

  /// Get users list with pagination (admin only)
  Future<List<UserModel>> getUsers({
    int page = 1,
    int limit = ApiConstants.defaultPageSize,
    String? search,
    String? role,
    bool? isActive,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        ApiConstants.pageKey: page,
        ApiConstants.limitKey: limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      if (role != null && role.isNotEmpty) {
        queryParameters['role'] = role;
      }
      if (isActive != null) {
        queryParameters['isActive'] = isActive;
      }

      final Response response = await _apiClient.get(
        ApiConstants.usersEndpoint,
        queryParameters: queryParameters,
      );

      if (response.data == null ||
          (response.data as Map<String, dynamic>?)?[ApiConstants.dataKey] == null) {
        throw const GenericApiException('No users data received', 'no_data');
      }

      final List<dynamic> usersData = (response.data as Map<String, dynamic>)[ApiConstants.dataKey] as List<dynamic>;
      return usersData.map((userData) => UserModel.fromJson(userData as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw GenericApiException(
        e.message ?? 'Failed to get users',
        'get_users_error',
      );
    }
  }

  /// Sync user data with Firebase
  /// This method can be called after Firebase authentication
  /// to sync the user data with your backend and store the JWT token
  Future<UserModel> syncUserWithBackend({
    required String firebaseUid,
    required String email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
  }) async {
    try {
      final Response response = await _apiClient.post(
        '/auth/sync',
        data: {
          'firebaseUid': firebaseUid,
          'email': email,
          if (displayName != null) 'displayName': displayName,
          if (photoUrl != null) 'photoUrl': photoUrl,
          if (isEmailVerified != null) 'isEmailVerified': isEmailVerified,
        },
      );

      if (response.data == null) {
        throw const GenericApiException('No user data received', 'no_data');
      }

      final responseData = response.data as Map<String, dynamic>;

      // Extract and store JWT token from sync response
      if (responseData.containsKey('data') && responseData['data'] != null) {
        final data = responseData['data'] as Map<String, dynamic>;

        // Check for JWT token in the response
        if (data.containsKey('token') && data['token'] != null) {
          final jwtToken = data['token'] as String;

          // Store the JWT token for future API calls
          await _storageService.setString(AppConstants.tokenKey, jwtToken);

          print('DEBUG: JWT token from sync endpoint stored successfully');
        } else {
          print('DEBUG: No JWT token found in sync response');
        }

        // Check for user data
        if (data.containsKey('user') && data['user'] != null) {
          return UserModel.fromJson(data['user'] as Map<String, dynamic>);
        }
      }

      // Fallback to existing structure
      if (responseData.containsKey(ApiConstants.dataKey)) {
        return UserModel.fromJson(responseData[ApiConstants.dataKey] as Map<String, dynamic>);
      }

      throw const GenericApiException('Invalid response structure', 'invalid_response');

    } on DioException catch (e) {
      if (e.error is ApiException) {
        rethrow;
      }
      throw GenericApiException(
        e.message ?? 'Failed to sync user with backend',
        'sync_user_error',
      );
    }
  }
}
