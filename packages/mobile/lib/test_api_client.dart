import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'data/services/api_client.dart';
import 'data/services/user_api_service.dart';
import 'presentation/controllers/auth_controller.dart';
import 'core/errors/api_exceptions.dart';

/// Test widget to verify HTTP interceptor and API client functionality
class ApiTestWidget extends StatefulWidget {
  const ApiTestWidget({super.key});

  @override
  State<ApiTestWidget> createState() => _ApiTestWidgetState();
}

class _ApiTestWidgetState extends State<ApiTestWidget> {
  final ApiClient apiClient = ApiClient.instance;
  final UserApiService userApiService = UserApiService();
  final AuthController authController = Get.find<AuthController>();
  
  String _testResults = 'No tests run yet';
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Client Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'API Client & Interceptor Test',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Current auth status
            Obx(() => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentication Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authController.isAuthenticated 
                          ? 'Authenticated: ${authController.currentUser?.email}' 
                          : 'Not authenticated',
                    ),
                  ],
                ),
              ),
            )),
            
            const SizedBox(height: 16),
            
            // Test buttons
            ElevatedButton(
              onPressed: _isRunning ? null : _testApiClient,
              child: _isRunning 
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Running Tests...'),
                      ],
                    )
                  : const Text('Test API Client'),
            ),
            
            ElevatedButton(
              onPressed: _isRunning || !authController.isAuthenticated 
                  ? null 
                  : _testAuthenticatedRequest,
              child: const Text('Test Authenticated Request'),
            ),
            
            ElevatedButton(
              onPressed: _isRunning ? null : _testTokenRefresh,
              child: const Text('Test Token Refresh'),
            ),
            
            const SizedBox(height: 16),
            
            // Test results
            Card(
              child: Container(
                width: double.infinity,
                height: 300,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Results',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _testResults,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Test basic API client functionality
  Future<void> _testApiClient() async {
    setState(() {
      _isRunning = true;
      _testResults = 'Starting API Client tests...\n\n';
    });

    try {
      // Test 1: Basic GET request
      _appendResult('🧪 Test 1: Basic GET request');
      try {
        final response = await apiClient.get('/test');
        _appendResult('✅ GET request successful');
        _appendResult('Status: ${response.statusCode}');
        _appendResult('Data: ${response.data}\n');
      } catch (e) {
        _appendResult('❌ GET request failed: $e\n');
      }

      // Test 2: POST request with data
      _appendResult('🧪 Test 2: POST request with data');
      try {
        final response = await apiClient.post(
          '/test',
          data: {'test': 'data', 'timestamp': DateTime.now().toIso8601String()},
        );
        _appendResult('✅ POST request successful');
        _appendResult('Status: ${response.statusCode}');
        _appendResult('Data: ${response.data}\n');
      } catch (e) {
        _appendResult('❌ POST request failed: $e\n');
      }

      // Test 3: Request with custom headers
      _appendResult('🧪 Test 3: Request with custom headers');
      try {
        apiClient.addHeader('X-Test-Header', 'test-value');
        final response = await apiClient.get('/test');
        _appendResult('✅ Custom header request successful');
        _appendResult('Status: ${response.statusCode}\n');
      } catch (e) {
        _appendResult('❌ Custom header request failed: $e\n');
      }

      _appendResult('🏁 API Client tests completed');
    } catch (e) {
      _appendResult('💥 Unexpected error: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  /// Test authenticated request (requires user to be logged in)
  Future<void> _testAuthenticatedRequest() async {
    setState(() {
      _isRunning = true;
      _testResults = 'Starting authenticated request test...\n\n';
    });

    try {
      _appendResult('🧪 Testing authenticated API request');
      _appendResult('Current user: ${authController.currentUser?.email}');

      try {
        final userProfile = await userApiService.getCurrentUserProfile();
        _appendResult('✅ Authenticated request successful');
        _appendResult('User profile loaded:');
        _appendResult('  ID: ${userProfile.id}');
        _appendResult('  Email: ${userProfile.email}');
        _appendResult('  Name: ${userProfile.displayName ?? "Not set"}');
        _appendResult('  Email Verified: ${userProfile.isEmailVerified}');
      } on ApiException catch (e) {
        _appendResult('❌ API Exception: ${e.message}');
        _appendResult('Code: ${e.code}');
        _appendResult('Localized: ${ApiExceptionLocalizer.getLocalizedMessage(e)}');
      } catch (e) {
        _appendResult('❌ Unexpected error: $e');
      }

      _appendResult('\n🏁 Authenticated request test completed');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  /// Test token refresh mechanism
  Future<void> _testTokenRefresh() async {
    setState(() {
      _isRunning = true;
      _testResults = 'Starting token refresh test...\n\n';
    });

    try {
      _appendResult('🧪 Testing token refresh mechanism');
      
      // This will trigger a 401 response to test token refresh
      try {
        final response = await apiClient.get('/auth/test-token-refresh');
        _appendResult('✅ Token refresh test successful');
        _appendResult('Status: ${response.statusCode}');
      } catch (e) {
        _appendResult('❌ Token refresh test failed: $e');
      }

      _appendResult('\n🏁 Token refresh test completed');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  /// Append result to test output
  void _appendResult(String result) {
    setState(() {
      _testResults += '$result\n';
    });
  }
}

/// Example of how to use the ApiClient in your app
class ApiUsageExample {
  final ApiClient _apiClient = ApiClient.instance;

  /// Example: Get user data
  Future<Map<String, dynamic>> getUserData(int userId) async {
    try {
      final response = await _apiClient.get('/users/$userId');
      return response.data;
    } on ApiException catch (e) {
      // Handle API-specific errors
      print('API Error: ${ApiExceptionLocalizer.getLocalizedMessage(e)}');
      rethrow;
    }
  }

  /// Example: Create user
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.post('/users', data: userData);
      return response.data;
    } on ApiValidationException catch (e) {
      // Handle validation errors specifically
      final errors = ApiValidationException.extractValidationErrors(e.message);
      print('Validation errors: $errors');
      rethrow;
    } on ApiException catch (e) {
      print('API Error: ${ApiExceptionLocalizer.getLocalizedMessage(e)}');
      rethrow;
    }
  }

  /// Example: Upload file with progress
  Future<void> uploadFile(String filePath, Function(double) onProgress) async {
    try {
      await _apiClient.uploadFile(
        '/upload',
        filePath,
        onSendProgress: (sent, total) {
          final progress = sent / total;
          onProgress(progress);
        },
      );
    } on ApiException catch (e) {
      print('Upload failed: ${ApiExceptionLocalizer.getLocalizedMessage(e)}');
      rethrow;
    }
  }
}