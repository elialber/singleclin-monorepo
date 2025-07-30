import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:mobile/data/services/token_refresh_service.dart';
import 'package:mobile/presentation/controllers/auth_controller.dart';

/// Test widget to verify token refresh and session persistence functionality
class TokenRefreshTestWidget extends StatefulWidget {
  const TokenRefreshTestWidget({super.key});

  @override
  State<TokenRefreshTestWidget> createState() => _TokenRefreshTestWidgetState();
}

class _TokenRefreshTestWidgetState extends State<TokenRefreshTestWidget> {
  final TokenRefreshService _tokenRefreshService = Get.find<TokenRefreshService>();
  final AuthController _authController = Get.find<AuthController>();
  
  String _testResults = 'No tests run yet';
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Refresh Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Token Refresh & Session Persistence Test',
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
                      _authController.isAuthenticated 
                          ? 'Authenticated: ${_authController.currentUser?.email}' 
                          : 'Not authenticated',
                    ),
                  ],
                ),
              ),
            )),
            
            const SizedBox(height: 16),
            
            // Token refresh service status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Token Refresh Service Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(_getServiceStatusText()),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test buttons
            ElevatedButton(
              onPressed: _isRunning ? null : _testTokenRefresh,
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
                  : const Text('Test Token Refresh'),
            ),
            
            ElevatedButton(
              onPressed: _isRunning || !_authController.isAuthenticated 
                  ? null 
                  : _testTokenExpiration,
              child: const Text('Check Token Expiration'),
            ),
            
            ElevatedButton(
              onPressed: _isRunning ? null : _testServiceStatus,
              child: const Text('Check Service Status'),
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

  /// Get token refresh service status as text
  String _getServiceStatusText() {
    final status = _tokenRefreshService.getStatus();
    return '''
Active: ${status['isActive']}
Has User: ${status['hasUser']}
Timer Active: ${status['timerActive']}
Refresh Interval: ${status['refreshIntervalMinutes']} minutes
''';
  }

  /// Test token refresh functionality
  Future<void> _testTokenRefresh() async {
    setState(() {
      _isRunning = true;
      _testResults = 'Starting token refresh tests...\\n\\n';
    });

    try {
      // Test 1: Get current token
      _appendResult('🧪 Test 1: Get current token');
      try {
        final token = await _authController.getCurrentToken();
        if (token != null) {
          _appendResult('✅ Current token retrieved successfully');
          _appendResult('Token length: ${token.length} characters');
          _appendResult('Token preview: ${token.substring(0, 20)}...\\n');
        } else {
          _appendResult('❌ Failed to get current token\\n');
        }
      } catch (e) {
        _appendResult('❌ Error getting current token: $e\\n');
      }

      // Test 2: Force refresh token
      _appendResult('🧪 Test 2: Force refresh token');
      try {
        final refreshedToken = await _authController.refreshToken();
        if (refreshedToken != null) {
          _appendResult('✅ Token refreshed successfully');
          _appendResult('Refreshed token length: ${refreshedToken.length} characters');
          _appendResult('Refreshed token preview: ${refreshedToken.substring(0, 20)}...\\n');
        } else {
          _appendResult('❌ Failed to refresh token\\n');
        }
      } catch (e) {
        _appendResult('❌ Error refreshing token: $e\\n');
      }

      // Test 3: Check token expiration
      _appendResult('🧪 Test 3: Check token expiration status');
      try {
        final isExpiring = await _authController.isTokenExpiringSoon();
        _appendResult('Token expiring soon: $isExpiring\\n');
      } catch (e) {
        _appendResult('❌ Error checking token expiration: $e\\n');
      }

      _appendResult('🏁 Token refresh tests completed');
    } catch (e) {
      _appendResult('💥 Unexpected error: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  /// Test token expiration check
  Future<void> _testTokenExpiration() async {
    setState(() {
      _isRunning = true;
      _testResults = 'Checking token expiration...\\n\\n';
    });

    try {
      final isExpiring = await _authController.isTokenExpiringSoon();
      _appendResult('🧪 Token Expiration Check');
      _appendResult('Token expiring soon: $isExpiring');
      
      if (isExpiring) {
        _appendResult('⚠️ Token is close to expiration, will be refreshed automatically');
        _appendResult('Getting fresh token...');
        
        final freshToken = await _authController.getCurrentToken();
        if (freshToken != null) {
          _appendResult('✅ Fresh token obtained successfully');
        } else {
          _appendResult('❌ Failed to get fresh token');
        }
      } else {
        _appendResult('✅ Token is still valid');
      }
    } catch (e) {
      _appendResult('❌ Error checking token expiration: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  /// Test service status
  Future<void> _testServiceStatus() async {
    setState(() {
      _isRunning = true;
      _testResults = 'Checking service status...\\n\\n';
    });

    try {
      _appendResult('🧪 Token Refresh Service Status');
      
      final status = _tokenRefreshService.getStatus();
      _appendResult('Service Active: ${status['isActive']}');
      _appendResult('Has Authenticated User: ${status['hasUser']}');
      _appendResult('Timer Running: ${status['timerActive']}');
      _appendResult('Refresh Interval: ${status['refreshIntervalMinutes']} minutes');
      
      if (status['isActive'] && status['hasUser'] && status['timerActive']) {
        _appendResult('\\n✅ Service is fully operational');
      } else {
        _appendResult('\\n⚠️ Service may not be fully operational');
        if (!status['isActive']) _appendResult('  - Service is not active');
        if (!status['hasUser']) _appendResult('  - No authenticated user');
        if (!status['timerActive']) _appendResult('  - Timer is not running');
      }
    } catch (e) {
      _appendResult('❌ Error checking service status: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  /// Append result to test output
  void _appendResult(String result) {
    setState(() {
      _testResults += '$result\\n';
    });
  }
}

/// Example of how to use token refresh in your app
class TokenRefreshUsageExample {
  final AuthController _authController = Get.find<AuthController>();

  /// Example: Make API call with fresh token
  Future<void> makeAuthenticatedApiCall() async {
    try {
      // Get current token (automatically refreshes if needed)
      final token = await _authController.getCurrentToken();
      
      if (token == null) {
        throw Exception('Unable to get authentication token');
      }
      
      // Use token for API call
      debugPrint('Making API call with token: ${token.substring(0, 20)}...');
      
      // Your API call logic here
      // await apiClient.get('/protected-endpoint', headers: {'Authorization': 'Bearer $token'});
      
    } catch (e) {
      debugPrint('API call failed: $e');
      // Handle authentication failure
    }
  }

  /// Example: Check if token needs refresh before critical operation
  Future<void> performCriticalOperation() async {
    try {
      // Check if token is expiring soon
      final isExpiring = await _authController.isTokenExpiringSoon();
      
      if (isExpiring) {
        debugPrint('Token expiring soon, refreshing...');
        final newToken = await _authController.refreshToken();
        
        if (newToken == null) {
          throw Exception('Failed to refresh token');
        }
      }
      
      // Proceed with critical operation
      debugPrint('Performing critical operation with valid token');
      
    } catch (e) {
      debugPrint('Critical operation failed: $e');
    }
  }
}