import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:io';

/// Service for monitoring network connectivity and status
///
/// Provides real-time connectivity monitoring, connection quality detection,
/// and network-aware functionality for offline-first operations.
class NetworkService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final Dio _dio = Dio();

  // Reactive state
  final _isConnected = true.obs;
  final _connectionType = ConnectivityResult.wifi.obs;
  final _connectionQuality = ConnectionQuality.good.obs;

  // Stream subscription
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Connection test settings
  static const String _testUrl = 'https://www.google.com';
  static const Duration _testTimeout = Duration(seconds: 5);
  static const Duration _qualityTestInterval = Duration(minutes: 2);

  Timer? _qualityTestTimer;
  DateTime? _lastQualityTest;

  // Getters for reactive state
  bool get isConnected => _isConnected.value;
  ConnectivityResult get connectionType => _connectionType.value;
  ConnectionQuality get connectionQuality => _connectionQuality.value;

  // Reactive getters
  RxBool get isConnectedRx => _isConnected;
  Rx<ConnectivityResult> get connectionTypeRx => _connectionType;
  Rx<ConnectionQuality> get connectionQualityRx => _connectionQuality;

  // Convenience getters
  bool get isWifi => connectionType == ConnectivityResult.wifi;
  bool get isMobile => connectionType == ConnectivityResult.mobile;
  bool get isEthernet => connectionType == ConnectivityResult.ethernet;
  bool get isOffline => !isConnected;
  bool get hasGoodConnection =>
      isConnected && connectionQuality != ConnectionQuality.poor;
  bool get shouldLimitData =>
      isMobile && connectionQuality == ConnectionQuality.poor;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeNetworkMonitoring();
  }

  Future<void> _initializeNetworkMonitoring() async {
    try {
      // Check initial connectivity
      await _checkInitialConnectivity();

      // Start monitoring connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          print('❌ Connectivity monitoring error: $error');
        },
      );

      // Start periodic quality testing
      _startQualityTesting();

      print(
        '✅ NetworkService initialized - Connected: $isConnected, Type: $connectionType',
      );
    } catch (e) {
      print('❌ NetworkService initialization failed: $e');
      // Set default offline state
      _isConnected.value = false;
      _connectionType.value = ConnectivityResult.none;
      _connectionQuality.value = ConnectionQuality.none;
    }
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _connectionType.value = result;

    if (result == ConnectivityResult.none) {
      _isConnected.value = false;
      _connectionQuality.value = ConnectionQuality.none;
    } else {
      // Test actual internet connectivity
      final isActuallyConnected = await _testInternetConnection();
      _isConnected.value = isActuallyConnected;

      if (isActuallyConnected) {
        await _testConnectionQuality();
      } else {
        _connectionQuality.value = ConnectionQuality.none;
      }
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    print('📶 Connectivity changed to: $result');
    _connectionType.value = result;

    if (result == ConnectivityResult.none) {
      _isConnected.value = false;
      _connectionQuality.value = ConnectionQuality.none;
    } else {
      // Test actual connection when connectivity is detected
      _testAndUpdateConnection();
    }
  }

  Future<void> _testAndUpdateConnection() async {
    final isActuallyConnected = await _testInternetConnection();
    _isConnected.value = isActuallyConnected;

    if (isActuallyConnected) {
      await _testConnectionQuality();
    } else {
      _connectionQuality.value = ConnectionQuality.none;
    }
  }

  /// Test actual internet connectivity (not just network interface)
  Future<bool> _testInternetConnection() async {
    try {
      final response = await _dio.get(
        _testUrl,
        options: Options(
          connectTimeout: _testTimeout,
          receiveTimeout: _testTimeout,
          sendTimeout: _testTimeout,
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Test connection quality based on response time
  Future<void> _testConnectionQuality() async {
    try {
      final stopwatch = Stopwatch()..start();

      final response = await _dio.get(
        _testUrl,
        options: Options(
          connectTimeout: _testTimeout,
          receiveTimeout: _testTimeout,
        ),
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
        final responseTime = stopwatch.elapsedMilliseconds;
        _connectionQuality.value = _determineConnectionQuality(responseTime);
        _lastQualityTest = DateTime.now();
      } else {
        _connectionQuality.value = ConnectionQuality.poor;
      }
    } catch (e) {
      _connectionQuality.value = ConnectionQuality.poor;
    }
  }

  ConnectionQuality _determineConnectionQuality(int responseTimeMs) {
    if (responseTimeMs < 500) {
      return ConnectionQuality.excellent;
    } else if (responseTimeMs < 1000) {
      return ConnectionQuality.good;
    } else if (responseTimeMs < 3000) {
      return ConnectionQuality.fair;
    } else {
      return ConnectionQuality.poor;
    }
  }

  void _startQualityTesting() {
    _qualityTestTimer = Timer.periodic(_qualityTestInterval, (timer) {
      if (isConnected) {
        _testConnectionQuality();
      }
    });
  }

  /// Force refresh network status
  Future<void> refreshNetworkStatus() async {
    await _checkInitialConnectivity();
  }

  /// Check if device has any network interface (not necessarily internet)
  Future<bool> hasNetworkInterface() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Get network type as human-readable string
  String get connectionTypeString {
    switch (connectionType) {
      case ConnectivityResult.wifi:
        return 'Wi-Fi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
      default:
        return 'No Connection';
    }
  }

  /// Get connection quality as human-readable string
  String get connectionQualityString {
    switch (connectionQuality) {
      case ConnectionQuality.excellent:
        return 'Excellent';
      case ConnectionQuality.good:
        return 'Good';
      case ConnectionQuality.fair:
        return 'Fair';
      case ConnectionQuality.poor:
        return 'Poor';
      case ConnectionQuality.none:
      default:
        return 'No Connection';
    }
  }

  /// Get connection status summary
  Map<String, dynamic> get connectionStatus => {
    'isConnected': isConnected,
    'connectionType': connectionTypeString,
    'connectionQuality': connectionQualityString,
    'lastQualityTest': _lastQualityTest?.toIso8601String(),
    'shouldLimitData': shouldLimitData,
  };

  /// Wait for network connection to be available
  Future<void> waitForConnection({Duration? timeout}) async {
    if (isConnected) return;

    final completer = Completer<void>();
    late StreamSubscription subscription;

    subscription = _isConnected.listen((connected) {
      if (connected) {
        subscription.cancel();
        completer.complete();
      }
    });

    if (timeout != null) {
      Timer(timeout, () {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.completeError(
            TimeoutException('Network connection timeout', timeout),
          );
        }
      });
    }

    return completer.future;
  }

  /// Execute function when network becomes available
  Future<T?> executeWhenOnline<T>(
    Future<T> Function() function, {
    Duration? timeout,
    T? fallback,
  }) async {
    try {
      await waitForConnection(timeout: timeout);
      return await function();
    } catch (e) {
      print('❌ executeWhenOnline failed: $e');
      return fallback;
    }
  }

  /// Check if we should perform data-intensive operations
  bool shouldPerformDataIntensiveOperation() {
    if (!isConnected) return false;
    if (shouldLimitData) return false;
    return connectionQuality != ConnectionQuality.poor;
  }

  /// Get recommended timeout based on connection quality
  Duration get recommendedTimeout {
    switch (connectionQuality) {
      case ConnectionQuality.excellent:
        return const Duration(seconds: 5);
      case ConnectionQuality.good:
        return const Duration(seconds: 10);
      case ConnectionQuality.fair:
        return const Duration(seconds: 15);
      case ConnectionQuality.poor:
        return const Duration(seconds: 30);
      case ConnectionQuality.none:
      default:
        return const Duration(seconds: 60);
    }
  }

  /// Get recommended retry count based on connection quality
  int get recommendedRetryCount {
    switch (connectionQuality) {
      case ConnectionQuality.excellent:
      case ConnectionQuality.good:
        return 2;
      case ConnectionQuality.fair:
        return 3;
      case ConnectionQuality.poor:
        return 5;
      case ConnectionQuality.none:
      default:
        return 0;
    }
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _qualityTestTimer?.cancel();
    _dio.close();
    super.onClose();
  }
}

/// Enum for connection quality levels
enum ConnectionQuality { none, poor, fair, good, excellent }

/// Exception for network timeout
class NetworkTimeoutException implements Exception {
  NetworkTimeoutException(this.message);
  final String message;

  @override
  String toString() => 'NetworkTimeoutException: $message';
}
