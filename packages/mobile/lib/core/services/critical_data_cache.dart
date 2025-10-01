import 'package:get/get.dart';
import 'package:singleclin_mobile/core/models/cache_entity.dart';
import 'package:singleclin_mobile/core/services/network_service.dart';
import 'package:singleclin_mobile/core/services/cache_service.dart';
import 'package:singleclin_mobile/data/repositories/user_repository.dart';
import 'package:singleclin_mobile/data/repositories/credit_repository.dart';
import 'package:singleclin_mobile/data/repositories/clinic_repository.dart';
import 'dart:async';

/// Critical Data Cache Manager
///
/// Manages preloading and maintenance of essential user data for offline access.
/// Ensures profile, credits, transaction history, and frequently used clinics
/// are always available offline.
class CriticalDataCache extends GetxService {
  CriticalDataCache({
    required NetworkService networkService,
    required CacheService cacheService,
    required UserRepository userRepository,
    required CreditRepository creditRepository,
    required ClinicRepository clinicRepository,
  }) : _networkService = networkService,
       _cacheService = cacheService,
       _userRepository = userRepository,
       _creditRepository = creditRepository,
       _clinicRepository = clinicRepository;
  final NetworkService _networkService;
  final CacheService _cacheService;
  final UserRepository _userRepository;
  final CreditRepository _creditRepository;
  final ClinicRepository _clinicRepository;

  // Cache state
  final _isPreloading = false.obs;
  final _lastPreloadTime = Rxn<DateTime>();
  final _preloadProgress = 0.0.obs;
  final _criticalDataStatus = <String, bool>{}.obs;

  // Configuration
  static const Duration _preloadInterval = Duration(hours: 4);
  static const Duration _criticalDataTtl = Duration(hours: 24);

  Timer? _preloadTimer;

  // Getters
  bool get isPreloading => _isPreloading.value;
  DateTime? get lastPreloadTime => _lastPreloadTime.value;
  double get preloadProgress => _preloadProgress.value;
  Map<String, bool> get criticalDataStatus => _criticalDataStatus;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeCriticalDataCache();
  }

  Future<void> _initializeCriticalDataCache() async {
    try {
      // Load cache metadata
      await _loadCacheMetadata();

      // Check critical data availability
      await _checkCriticalDataStatus();

      // Setup automatic preloading
      _setupAutomaticPreloading();

      // Setup network listener for preloading when connection is available
      _networkService.isConnectedRx.listen((isConnected) {
        if (isConnected && _needsPreload()) {
          _schedulePreload(immediate: true);
        }
      });

      print('✅ CriticalDataCache initialized');
    } catch (e) {
      print('❌ Failed to initialize CriticalDataCache: $e');
      rethrow;
    }
  }

  /// Preload all critical data
  Future<PreloadResult> preloadCriticalData({
    bool force = false,
    bool userTriggered = false,
  }) async {
    if (_isPreloading.value && !force) {
      return PreloadResult.alreadyInProgress();
    }

    if (!_networkService.isConnected && !force) {
      return PreloadResult.noConnection();
    }

    return _performPreload(userTriggered: userTriggered);
  }

  /// Check if critical data is available offline
  Future<CriticalDataAvailability> checkCriticalDataAvailability() async {
    final availability = CriticalDataAvailability();

    try {
      // Check user profile
      final profile = await _userRepository.getCurrentUser(offlineOnly: true);
      availability.hasProfile = profile != null;

      // Check wallet balance
      final balance = await _creditRepository.getWalletBalance();
      availability.hasWalletBalance = balance != null;

      // Check transaction history
      final transactions = await _creditRepository.getRecentTransactions(
        offlineOnly: true,
      );
      availability.hasTransactionHistory = transactions.isNotEmpty;

      // Check clinic data
      final clinics = await _clinicRepository.getMany(
        limit: 10,
        offlineOnly: true,
      );
      availability.hasClinicData = clinics.isNotEmpty;

      // Check favorites
      final favorites = await _clinicRepository.getFavorites();
      availability.hasFavorites = favorites.isNotEmpty;

      // Calculate overall score
      availability.calculateOverallScore();

      return availability;
    } catch (e) {
      print('❌ Error checking critical data availability: $e');
      return CriticalDataAvailability(); // Returns all false
    }
  }

  /// Preload user-specific critical data
  Future<void> preloadUserData() async {
    try {
      print('📥 Preloading user profile data...');

      // Preload user profile with preferences
      await _userRepository.getCurrentUser(forceRefresh: true);

      // Preload user preferences and settings
      await _userRepository.getUserPreferences(forceRefresh: true);

      _criticalDataStatus['profile'] = true;
      _updatePreloadProgress(0.2);
    } catch (e) {
      print('❌ Failed to preload user data: $e');
      _criticalDataStatus['profile'] = false;
      rethrow;
    }
  }

  /// Preload credit and financial data
  Future<void> preloadCreditData() async {
    try {
      print('📥 Preloading credit data...');

      // Preload wallet balance
      await _creditRepository.getWalletBalance(forceRefresh: true);

      // Preload recent transaction history (last 30 days)
      await _creditRepository.getTransactionHistory(
        limit: 50,
        endDate: DateTime.now(),
        startDate: DateTime.now().subtract(const Duration(days: 30)),
      );

      // Preload available credit packages
      await _creditRepository.getAvailableCreditPackages();

      _criticalDataStatus['credits'] = true;
      _updatePreloadProgress(0.5);
    } catch (e) {
      print('❌ Failed to preload credit data: $e');
      _criticalDataStatus['credits'] = false;
      rethrow;
    }
  }

  /// Preload clinic and discovery data
  Future<void> preloadClinicData() async {
    try {
      print('📥 Preloading clinic data...');

      // Preload user's favorite clinics
      await _clinicRepository.getFavorites();

      // Preload recently viewed clinics
      await _clinicRepository.getRecentlyViewed();

      // Preload featured clinics
      await _clinicRepository.getFeaturedClinics(limit: 20);

      _criticalDataStatus['clinics'] = true;
      _updatePreloadProgress(0.8);
    } catch (e) {
      print('❌ Failed to preload clinic data: $e');
      _criticalDataStatus['clinics'] = false;
      rethrow;
    }
  }

  /// Preload location-based clinic data
  Future<void> preloadLocationBasedData({
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('📥 Preloading location-based clinic data...');

      // Preload clinics in user's area
      await _clinicRepository.preloadClinicsForArea(
        latitude: latitude,
        longitude: longitude,
        radiusKm: 15.0,
      );

      _criticalDataStatus['location_data'] = true;
      _updatePreloadProgress(1.0);
    } catch (e) {
      print('❌ Failed to preload location data: $e');
      _criticalDataStatus['location_data'] = false;
    }
  }

  /// Get cache health report
  Future<CacheHealthReport> getCacheHealthReport() async {
    final report = CacheHealthReport();

    try {
      // Get cache statistics from each repository
      final userCacheInfo = await _userRepository.getCacheInfo();
      final creditCacheInfo = await _creditRepository.getCacheInfo();
      final clinicCacheInfo = await _clinicRepository.getCacheInfo();

      report.userDataHealth = _calculateDataHealth(userCacheInfo);
      report.creditDataHealth = _calculateDataHealth(creditCacheInfo);
      report.clinicDataHealth = _calculateDataHealth(clinicCacheInfo);

      // Overall health score
      report.overallHealthScore =
          (report.userDataHealth +
              report.creditDataHealth +
              report.clinicDataHealth) /
          3;

      // Check data freshness
      report.lastPreloadTime = lastPreloadTime;
      report.isDataFresh = _isDataFresh();

      // Storage usage
      report.totalCacheSize =
          userCacheInfo['size'] +
          creditCacheInfo['size'] +
          clinicCacheInfo['size'];

      return report;
    } catch (e) {
      print('❌ Error generating cache health report: $e');
      report.hasErrors = true;
      report.errorMessage = e.toString();
      return report;
    }
  }

  /// Clear non-critical cached data to free space
  Future<void> optimizeCache() async {
    try {
      print('🧹 Optimizing cache...');

      // Clear old search results
      await _cacheService.clearExpiredItems(BoxType.searchCache);

      // Clear old QR codes
      await _cacheService.clearExpiredItems(BoxType.qrCodes);

      // Compress frequently used data
      // (Implementation depends on specific compression needs)

      print('✅ Cache optimization completed');
    } catch (e) {
      print('❌ Cache optimization failed: $e');
    }
  }

  /// Force refresh all critical data
  Future<PreloadResult> refreshAllCriticalData() async {
    return preloadCriticalData(force: true, userTriggered: true);
  }

  // Private implementation

  Future<PreloadResult> _performPreload({bool userTriggered = false}) async {
    _isPreloading.value = true;
    _preloadProgress.value = 0.0;
    _criticalDataStatus.clear();

    final stopwatch = Stopwatch()..start();

    try {
      print('🔄 Starting critical data preload...');

      // Step 1: User data
      await preloadUserData();

      // Step 2: Credit data
      await preloadCreditData();

      // Step 3: Clinic data
      await preloadClinicData();

      // Step 4: Location data (if permission available)
      // This would typically get location from a location service
      // For now, skip or use cached location

      _preloadProgress.value = 1.0;
      _lastPreloadTime.value = DateTime.now();

      await _saveCacheMetadata();

      stopwatch.stop();
      print(
        '✅ Critical data preload completed in ${stopwatch.elapsed.inSeconds}s',
      );

      return PreloadResult.success(
        duration: stopwatch.elapsed,
        itemsPreloaded: _criticalDataStatus.length,
      );
    } catch (e) {
      print('❌ Critical data preload failed: $e');
      return PreloadResult.error(e.toString());
    } finally {
      _isPreloading.value = false;
    }
  }

  void _setupAutomaticPreloading() {
    _preloadTimer = Timer.periodic(_preloadInterval, (timer) {
      if (_networkService.isConnected && _needsPreload()) {
        preloadCriticalData();
      }
    });
  }

  void _schedulePreload({bool immediate = false}) {
    final delay = immediate ? Duration.zero : const Duration(seconds: 30);

    Timer(delay, () {
      if (_networkService.isConnected && !_isPreloading.value) {
        preloadCriticalData();
      }
    });
  }

  bool _needsPreload() {
    if (lastPreloadTime == null) return true;

    final timeSinceLastPreload = DateTime.now().difference(lastPreloadTime!);
    return timeSinceLastPreload > _preloadInterval;
  }

  bool _isDataFresh() {
    if (lastPreloadTime == null) return false;

    final age = DateTime.now().difference(lastPreloadTime!);
    return age < _criticalDataTtl;
  }

  void _updatePreloadProgress(double progress) {
    _preloadProgress.value = progress;
  }

  Future<void> _checkCriticalDataStatus() async {
    final availability = await checkCriticalDataAvailability();

    _criticalDataStatus['profile'] = availability.hasProfile;
    _criticalDataStatus['credits'] = availability.hasWalletBalance;
    _criticalDataStatus['history'] = availability.hasTransactionHistory;
    _criticalDataStatus['clinics'] = availability.hasClinicData;
    _criticalDataStatus['favorites'] = availability.hasFavorites;
  }

  double _calculateDataHealth(Map<String, dynamic> cacheInfo) {
    // Simple health calculation based on cache hit rate and freshness
    final hitRate = (cacheInfo['hitRate'] ?? 0.0) as double;
    final freshness = (cacheInfo['freshness'] ?? 0.0) as double;

    return (hitRate * 0.6) + (freshness * 0.4);
  }

  Future<void> _loadCacheMetadata() async {
    try {
      final metadata = await _cacheService.get(
        'critical_cache',
        'last_preload',
      );
      if (metadata != null) {
        _lastPreloadTime.value = DateTime.parse(metadata['timestamp']);
      }
    } catch (e) {
      print('⚠️ Failed to load cache metadata: $e');
    }
  }

  Future<void> _saveCacheMetadata() async {
    try {
      await _cacheService.put('critical_cache', 'last_preload', {
        'timestamp': DateTime.now().toIso8601String(),
        'status': _criticalDataStatus,
      });
    } catch (e) {
      print('⚠️ Failed to save cache metadata: $e');
    }
  }

  @override
  void onClose() {
    _preloadTimer?.cancel();
    super.onClose();
  }
}

/// Result of preload operation
class PreloadResult {
  PreloadResult({
    required this.success,
    this.itemsPreloaded = 0,
    this.errorMessage,
    this.duration,
  });

  factory PreloadResult.success({int itemsPreloaded = 0, Duration? duration}) {
    return PreloadResult(
      success: true,
      itemsPreloaded: itemsPreloaded,
      duration: duration,
    );
  }

  factory PreloadResult.error(String message) {
    return PreloadResult(success: false, errorMessage: message);
  }

  factory PreloadResult.noConnection() {
    return PreloadResult(
      success: false,
      errorMessage: 'No network connection available',
    );
  }

  factory PreloadResult.alreadyInProgress() {
    return PreloadResult(
      success: false,
      errorMessage: 'Preload already in progress',
    );
  }
  final bool success;
  final int itemsPreloaded;
  final String? errorMessage;
  final Duration? duration;
}

/// Critical data availability status
class CriticalDataAvailability {
  bool hasProfile = false;
  bool hasWalletBalance = false;
  bool hasTransactionHistory = false;
  bool hasClinicData = false;
  bool hasFavorites = false;
  double overallScore = 0.0;

  void calculateOverallScore() {
    final items = [
      hasProfile,
      hasWalletBalance,
      hasTransactionHistory,
      hasClinicData,
      hasFavorites,
    ];

    final availableCount = items.where((item) => item).length;
    overallScore = availableCount / items.length;
  }

  bool get isComplete => overallScore >= 0.8;
  bool get hasBasicData => hasProfile && hasWalletBalance;
  bool get isOfflineReady => overallScore >= 0.6;
}

/// Cache health report
class CacheHealthReport {
  double userDataHealth = 0.0;
  double creditDataHealth = 0.0;
  double clinicDataHealth = 0.0;
  double overallHealthScore = 0.0;

  DateTime? lastPreloadTime;
  bool isDataFresh = false;
  int totalCacheSize = 0;

  bool hasErrors = false;
  String? errorMessage;

  bool get isHealthy => overallHealthScore >= 0.7;
  bool get needsAttention => overallHealthScore < 0.5;
}
