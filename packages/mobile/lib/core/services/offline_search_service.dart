import 'package:get/get.dart';
import '../models/cache_entity.dart';
import 'cache_service.dart';
import 'network_service.dart';
import '../../data/repositories/clinic_repository.dart';
import '../../features/discovery/models/clinic_model.dart';
import 'dart:async';
import 'dart:math';

/// Advanced offline search service for clinics
///
/// Provides sophisticated search capabilities including full-text search,
/// fuzzy matching, location-based filtering, and search result caching
/// for optimal offline experience.
class OfflineSearchService extends GetxService {
  final CacheService _cacheService;
  final NetworkService _networkService;
  final ClinicRepository _clinicRepository;

  // Search state
  final _isIndexing = false.obs;
  final _searchInProgress = false.obs;
  final _lastIndexUpdate = Rxn<DateTime>();
  final _indexedClinicsCount = 0.obs;

  // Search cache
  final Map<String, SearchIndex> _searchIndexes = {};
  final Map<String, SearchCacheEntry> _searchCache = {};

  // Configuration
  static const int _maxSearchResults = 50;
  static const int _maxCachedSearches = 100;
  static const Duration _searchCacheLifetime = Duration(minutes: 30);
  static const Duration _indexUpdateInterval = Duration(hours: 6);

  Timer? _indexUpdateTimer;

  OfflineSearchService({
    required CacheService cacheService,
    required NetworkService networkService,
    required ClinicRepository clinicRepository,
  })  : _cacheService = cacheService,
        _networkService = networkService,
        _clinicRepository = clinicRepository;

  // Getters
  bool get isIndexing => _isIndexing.value;
  bool get searchInProgress => _searchInProgress.value;
  DateTime? get lastIndexUpdate => _lastIndexUpdate.value;
  int get indexedClinicsCount => _indexedClinicsCount.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeSearchService();
  }

  Future<void> _initializeSearchService() async {
    try {
      // Load existing search indexes
      await _loadSearchIndexes();

      // Setup automatic index updates
      _setupIndexMaintenance();

      print('✅ OfflineSearchService initialized with $indexedClinicsCount clinics indexed');
    } catch (e) {
      print('❌ Failed to initialize OfflineSearchService: $e');
      rethrow;
    }
  }

  /// Perform offline-capable clinic search
  Future<OfflineSearchResult> searchClinics({
    required String query,
    double? latitude,
    double? longitude,
    double radiusKm = 25.0,
    List<String>? specialties,
    List<String>? services,
    PriceRange? priceRange,
    double? minRating,
    bool acceptsInsurance = false,
    ClinicSearchSort sortBy = ClinicSearchSort.relevance,
    int limit = 20,
    bool offlineOnly = false,
  }) async {
    _searchInProgress.value = true;

    try {
      final searchParams = ClinicSearchParams(
        query: query.trim(),
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        specialties: specialties,
        services: services,
        priceRange: priceRange,
        minRating: minRating,
        acceptsInsurance: acceptsInsurance,
        sortBy: sortBy,
        limit: limit,
        offlineOnly: offlineOnly,
      );

      // Check search cache first
      final cacheKey = _generateSearchCacheKey(searchParams);
      final cachedResult = _searchCache[cacheKey];

      if (cachedResult != null && cachedResult.isValid) {
        print('💾 Using cached search results for: "$query"');
        return OfflineSearchResult.fromCache(
          results: cachedResult.results.map((r) => ClinicModel.fromJson(r)).toList(),
          totalResults: cachedResult.totalResults,
          isFromCache: true,
          searchDuration: Duration.zero,
        );
      }

      // Perform search
      OfflineSearchResult searchResult;

      if (offlineOnly || !_networkService.isConnected) {
        searchResult = await _performOfflineSearch(searchParams);
      } else {
        searchResult = await _performHybridSearch(searchParams);
      }

      // Cache search results
      if (searchResult.success && searchResult.results.isNotEmpty) {
        await _cacheSearchResult(cacheKey, searchResult, searchParams);
      }

      return searchResult;

    } catch (e) {
      print('❌ Search failed: $e');
      return OfflineSearchResult.error('Erro na busca: $e');
    } finally {
      _searchInProgress.value = false;
    }
  }

  /// Get search suggestions based on query
  List<String> getSearchSuggestions(String query, {int limit = 5}) {
    if (query.length < 2) return [];

    final suggestions = <String>[];
    final queryLower = query.toLowerCase();

    // Get suggestions from indexed clinic names
    for (final index in _searchIndexes.values) {
      for (final term in index.terms.keys) {
        if (term.startsWith(queryLower) && !suggestions.contains(term)) {
          suggestions.add(term);
        }
      }

      if (suggestions.length >= limit) break;
    }

    // Sort by relevance (frequency of the term)
    suggestions.sort((a, b) {
      int scoreA = 0, scoreB = 0;

      for (final index in _searchIndexes.values) {
        scoreA += index.terms[a]?.length ?? 0;
        scoreB += index.terms[b]?.length ?? 0;
      }

      return scoreB.compareTo(scoreA);
    });

    return suggestions.take(limit).toList();
  }

  /// Get popular searches
  Future<List<String>> getPopularSearches({int limit = 10}) async {
    try {
      // Get from search cache frequency
      final searchFrequency = <String, int>{};

      for (final entry in _searchCache.values) {
        final query = entry.query.toLowerCase();
        searchFrequency[query] = (searchFrequency[query] ?? 0) + 1;
      }

      final popularSearches = searchFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return popularSearches.take(limit).map((e) => e.key).toList();

    } catch (e) {
      print('⚠️ Failed to get popular searches: $e');
      return [];
    }
  }

  /// Rebuild search index
  Future<void> rebuildSearchIndex({bool force = false}) async {
    if (_isIndexing.value && !force) {
      print('⚠️ Search index rebuild already in progress');
      return;
    }

    _isIndexing.value = true;

    try {
      print('🔄 Rebuilding search index...');

      // Clear existing indexes
      _searchIndexes.clear();

      // Get all cached clinics
      final clinics = await _clinicRepository.getMany(offlineOnly: true);

      // Build search indexes
      await _buildSearchIndexes(clinics);

      _lastIndexUpdate.value = DateTime.now();
      _indexedClinicsCount.value = clinics.length;

      // Save indexes to cache
      await _saveSearchIndexes();

      print('✅ Search index rebuilt with ${clinics.length} clinics');

    } catch (e) {
      print('❌ Failed to rebuild search index: $e');
      rethrow;
    } finally {
      _isIndexing.value = false;
    }
  }

  /// Clear search cache
  Future<void> clearSearchCache() async {
    _searchCache.clear();
    await _cacheService.clear('search_cache');
    print('🧹 Search cache cleared');
  }

  /// Get search analytics
  Future<SearchAnalytics> getSearchAnalytics() async {
    final analytics = SearchAnalytics();

    try {
      analytics.totalSearches = _searchCache.length;
      analytics.indexedClinics = indexedClinicsCount;
      analytics.lastIndexUpdate = lastIndexUpdate;

      // Calculate average search time
      double totalTime = 0;
      int validEntries = 0;

      for (final entry in _searchCache.values) {
        if (entry.queryDuration.inMilliseconds > 0) {
          totalTime += entry.queryDuration.inMilliseconds;
          validEntries++;
        }
      }

      analytics.averageSearchTime = validEntries > 0
          ? Duration(milliseconds: (totalTime / validEntries).round())
          : Duration.zero;

      // Most searched terms
      final queryFrequency = <String, int>{};
      for (final entry in _searchCache.values) {
        final query = entry.query.toLowerCase();
        queryFrequency[query] = (queryFrequency[query] ?? 0) + 1;
      }

      analytics.topSearchQueries = queryFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      analytics.topSearchQueries = analytics.topSearchQueries.take(10).toList();

      return analytics;

    } catch (e) {
      print('❌ Error generating search analytics: $e');
      analytics.hasError = true;
      analytics.errorMessage = e.toString();
      return analytics;
    }
  }

  // Private implementation

  Future<OfflineSearchResult> _performOfflineSearch(ClinicSearchParams params) async {
    final stopwatch = Stopwatch()..start();

    try {
      print('🔍 Performing offline search for: "${params.query}"');

      // Get base set of clinics
      final allClinics = await _clinicRepository.getMany(offlineOnly: true);

      // Apply filters and search
      List<ClinicModel> filteredClinics = allClinics;

      // Text search
      if (params.query.isNotEmpty) {
        filteredClinics = await _performTextSearch(filteredClinics, params.query);
      }

      // Location filter
      if (params.latitude != null && params.longitude != null) {
        filteredClinics = _filterByLocation(
          filteredClinics,
          params.latitude!,
          params.longitude!,
          params.radiusKm,
        );
      }

      // Specialty filter
      if (params.specialties != null && params.specialties!.isNotEmpty) {
        filteredClinics = _filterBySpecialties(filteredClinics, params.specialties!);
      }

      // Rating filter
      if (params.minRating != null) {
        filteredClinics = _filterByRating(filteredClinics, params.minRating!);
      }

      // Insurance filter
      if (params.acceptsInsurance) {
        filteredClinics = _filterByInsurance(filteredClinics);
      }

      // Sort results
      _sortResults(filteredClinics, params);

      // Limit results
      final results = filteredClinics.take(params.limit).toList();

      stopwatch.stop();

      return OfflineSearchResult.success(
        results: results,
        totalResults: filteredClinics.length,
        searchDuration: stopwatch.elapsed,
        isFromCache: false,
      );

    } catch (e) {
      stopwatch.stop();
      throw Exception('Offline search failed: $e');
    }
  }

  Future<OfflineSearchResult> _performHybridSearch(ClinicSearchParams params) async {
    try {
      // Try network search first
      final networkResults = await _clinicRepository.searchByText(
        query: params.query,
        latitude: params.latitude,
        longitude: params.longitude,
        radiusKm: params.radiusKm,
        limit: params.limit,
      );

      if (networkResults.isNotEmpty) {
        return OfflineSearchResult.success(
          results: networkResults,
          totalResults: networkResults.length,
          searchDuration: Duration(milliseconds: 500), // Estimate
          isFromCache: false,
        );
      }
    } catch (e) {
      print('⚠️ Network search failed, falling back to offline: $e');
    }

    // Fallback to offline search
    return await _performOfflineSearch(params);
  }

  Future<List<ClinicModel>> _performTextSearch(List<ClinicModel> clinics, String query) async {
    final queryTerms = query.toLowerCase().split(' ').where((term) => term.isNotEmpty).toList();

    if (queryTerms.isEmpty) return clinics;

    final scoredResults = <ScoredSearchResult>[];

    for (final clinic in clinics) {
      final score = _calculateSearchScore(clinic, queryTerms);
      if (score > 0) {
        scoredResults.add(ScoredSearchResult(clinic, score));
      }
    }

    // Sort by score (descending)
    scoredResults.sort((a, b) => b.score.compareTo(a.score));

    return scoredResults.map((r) => r.clinic).toList();
  }

  double _calculateSearchScore(ClinicModel clinic, List<String> queryTerms) {
    double score = 0.0;

    final clinicName = clinic.name.toLowerCase();
    final clinicDescription = clinic.description.toLowerCase();
    final clinicAddress = clinic.address.toLowerCase();
    final clinicSpecialties = clinic.specialties.map((s) => s.toLowerCase()).join(' ');

    for (final term in queryTerms) {
      // Exact matches get higher scores
      if (clinicName.contains(term)) {
        score += clinicName == term ? 10.0 : 5.0;
      }

      if (clinicDescription.contains(term)) {
        score += 3.0;
      }

      if (clinicSpecialties.contains(term)) {
        score += 4.0;
      }

      if (clinicAddress.contains(term)) {
        score += 2.0;
      }

      // Fuzzy matching bonus
      score += _calculateFuzzyScore(clinicName, term);
    }

    return score;
  }

  double _calculateFuzzyScore(String text, String term) {
    if (text.length < 3 || term.length < 3) return 0.0;

    final similarity = _calculateLevenshteinSimilarity(text, term);
    return similarity > 0.7 ? similarity : 0.0;
  }

  double _calculateLevenshteinSimilarity(String a, String b) {
    if (a == b) return 1.0;

    final maxLength = max(a.length, b.length);
    if (maxLength == 0) return 1.0;

    final distance = _levenshteinDistance(a, b);
    return 1.0 - (distance / maxLength);
  }

  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce(min);
      }
    }

    return matrix[a.length][b.length];
  }

  List<ClinicModel> _filterByLocation(
    List<ClinicModel> clinics,
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    return clinics.where((clinic) {
      final distance = clinic.distanceFrom(latitude, longitude);
      return distance <= radiusKm;
    }).toList();
  }

  List<ClinicModel> _filterBySpecialties(List<ClinicModel> clinics, List<String> specialties) {
    return clinics.where((clinic) {
      return specialties.any((specialty) =>
        clinic.specialties.any((s) => s.toLowerCase().contains(specialty.toLowerCase())));
    }).toList();
  }

  List<ClinicModel> _filterByRating(List<ClinicModel> clinics, double minRating) {
    return clinics.where((clinic) => clinic.rating >= minRating).toList();
  }

  List<ClinicModel> _filterByInsurance(List<ClinicModel> clinics) {
    return clinics.where((clinic) => clinic.acceptsInsurance).toList();
  }

  void _sortResults(List<ClinicModel> clinics, ClinicSearchParams params) {
    switch (params.sortBy) {
      case ClinicSearchSort.relevance:
        // Already sorted by search score
        break;
      case ClinicSearchSort.distance:
        if (params.latitude != null && params.longitude != null) {
          clinics.sort((a, b) => a.distanceFrom(params.latitude!, params.longitude!)
              .compareTo(b.distanceFrom(params.latitude!, params.longitude!)));
        }
        break;
      case ClinicSearchSort.rating:
        clinics.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ClinicSearchSort.name:
        clinics.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
  }

  Future<void> _buildSearchIndexes(List<ClinicModel> clinics) async {
    // This is a simplified implementation
    // In production, you'd want more sophisticated indexing
    _searchIndexes['clinics'] = SearchIndex();

    for (final clinic in clinics) {
      _addClinicToIndex(clinic);
    }
  }

  void _addClinicToIndex(ClinicModel clinic) {
    final index = _searchIndexes['clinics']!;

    // Index clinic name
    _addTermsToIndex(index, clinic.name, clinic.id);

    // Index specialties
    for (final specialty in clinic.specialties) {
      _addTermsToIndex(index, specialty, clinic.id);
    }

    // Index description words
    _addTermsToIndex(index, clinic.description, clinic.id);
  }

  void _addTermsToIndex(SearchIndex index, String text, String clinicId) {
    final words = text.toLowerCase().split(RegExp(r'\W+'));

    for (final word in words) {
      if (word.length >= 2) {
        index.terms[word] ??= <String>[];
        if (!index.terms[word]!.contains(clinicId)) {
          index.terms[word]!.add(clinicId);
        }
      }
    }
  }

  void _setupIndexMaintenance() {
    _indexUpdateTimer = Timer.periodic(_indexUpdateInterval, (timer) {
      if (_networkService.isConnected) {
        rebuildSearchIndex();
      }
    });
  }

  String _generateSearchCacheKey(ClinicSearchParams params) {
    return '${params.query}_${params.latitude}_${params.longitude}_${params.radiusKm}_${params.specialties?.join(',')}_${params.minRating}_${params.acceptsInsurance}_${params.sortBy.name}_${params.limit}'.hashCode.toString();
  }

  Future<void> _cacheSearchResult(
    String cacheKey,
    OfflineSearchResult result,
    ClinicSearchParams params,
  ) async {
    final cacheEntry = SearchCacheEntry(
      query: params.query,
      filters: {
        'latitude': params.latitude,
        'longitude': params.longitude,
        'radiusKm': params.radiusKm,
        'specialties': params.specialties,
        'minRating': params.minRating,
        'acceptsInsurance': params.acceptsInsurance,
        'sortBy': params.sortBy.name,
      },
      results: result.results.map((r) => r.toJson()).toList(),
      cachedAt: DateTime.now(),
      totalResults: result.totalResults,
      queryDuration: result.searchDuration,
    );

    _searchCache[cacheKey] = cacheEntry;

    // Maintain cache size
    if (_searchCache.length > _maxCachedSearches) {
      final oldestKey = _searchCache.entries
          .reduce((a, b) => a.value.cachedAt.isBefore(b.value.cachedAt) ? a : b)
          .key;
      _searchCache.remove(oldestKey);
    }
  }

  Future<void> _loadSearchIndexes() async {
    // Implementation would load indexes from cache
    // For now, trigger a rebuild if needed
    if (_searchIndexes.isEmpty) {
      await rebuildSearchIndex();
    }
  }

  Future<void> _saveSearchIndexes() async {
    // Implementation would save indexes to cache
    // This is complex for a real implementation
  }

  @override
  void onClose() {
    _indexUpdateTimer?.cancel();
    super.onClose();
  }
}

/// Search parameters container
class ClinicSearchParams {
  final String query;
  final double? latitude;
  final double? longitude;
  final double radiusKm;
  final List<String>? specialties;
  final List<String>? services;
  final PriceRange? priceRange;
  final double? minRating;
  final bool acceptsInsurance;
  final ClinicSearchSort sortBy;
  final int limit;
  final bool offlineOnly;

  ClinicSearchParams({
    required this.query,
    this.latitude,
    this.longitude,
    this.radiusKm = 25.0,
    this.specialties,
    this.services,
    this.priceRange,
    this.minRating,
    this.acceptsInsurance = false,
    this.sortBy = ClinicSearchSort.relevance,
    this.limit = 20,
    this.offlineOnly = false,
  });
}

/// Search result with scoring
class ScoredSearchResult {
  final ClinicModel clinic;
  final double score;

  ScoredSearchResult(this.clinic, this.score);
}

/// Search index for full-text search
class SearchIndex {
  final Map<String, List<String>> terms = {}; // term -> clinic IDs
}

/// Search result container
class OfflineSearchResult {
  final bool success;
  final List<ClinicModel> results;
  final int totalResults;
  final Duration searchDuration;
  final bool isFromCache;
  final String? errorMessage;

  OfflineSearchResult({
    required this.success,
    this.results = const [],
    this.totalResults = 0,
    this.searchDuration = Duration.zero,
    this.isFromCache = false,
    this.errorMessage,
  });

  factory OfflineSearchResult.success({
    required List<ClinicModel> results,
    required int totalResults,
    required Duration searchDuration,
    required bool isFromCache,
  }) {
    return OfflineSearchResult(
      success: true,
      results: results,
      totalResults: totalResults,
      searchDuration: searchDuration,
      isFromCache: isFromCache,
    );
  }

  factory OfflineSearchResult.fromCache({
    required List<ClinicModel> results,
    required int totalResults,
    required bool isFromCache,
    required Duration searchDuration,
  }) {
    return OfflineSearchResult(
      success: true,
      results: results,
      totalResults: totalResults,
      searchDuration: searchDuration,
      isFromCache: isFromCache,
    );
  }

  factory OfflineSearchResult.error(String message) {
    return OfflineSearchResult(
      success: false,
      errorMessage: message,
    );
  }
}

/// Search analytics data
class SearchAnalytics {
  int totalSearches = 0;
  int indexedClinics = 0;
  DateTime? lastIndexUpdate;
  Duration averageSearchTime = Duration.zero;
  List<MapEntry<String, int>> topSearchQueries = [];
  bool hasError = false;
  String? errorMessage;
}

/// Search sort options
enum ClinicSearchSort {
  relevance,
  distance,
  rating,
  name,
}

/// Price range filter
class PriceRange {
  final double min;
  final double max;

  PriceRange(this.min, this.max);
}