import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/clinic.dart';
import '../models/service.dart';
import '../models/filter_options.dart';

/// Main discovery controller managing clinic search, filtering, and display modes
class DiscoveryController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final LocationService _locationService = Get.find<LocationService>();

  // Observables
  final _isLoading = false.obs;
  final _isLoadingMore = false.obs;
  final _currentViewMode = ViewMode.list.obs;
  final _searchQuery = ''.obs;
  final _filterOptions = FilterOptions.defaultFilters.obs;
  final _clinics = <Clinic>[].obs;
  final _filteredClinics = <Clinic>[].obs;
  final _popularServices = <Service>[].obs;
  final _categories = <String>[].obs;
  final _hasMoreData = true.obs;
  final _currentPage = 1.obs;
  final _userLocation = Rxn<Position>();
  final _lastSearchTimestamp = Rxn<DateTime>();
  final _searchResultsCount = 0.obs;

  // Search debouncing
  Timer? _searchDebouncer;
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  // Cache management
  final Map<String, List<Clinic>> _searchCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  ViewMode get currentViewMode => _currentViewMode.value;
  String get searchQuery => _searchQuery.value;
  FilterOptions get filterOptions => _filterOptions.value;
  List<Clinic> get clinics => _clinics;
  List<Clinic> get filteredClinics => _filteredClinics;
  List<Service> get popularServices => _popularServices;
  List<String> get categories => _categories;
  bool get hasMoreData => _hasMoreData.value;
  Position? get userLocation => _userLocation.value;
  int get searchResultsCount => _searchResultsCount.value;
  bool get hasSearchQuery => _searchQuery.value.trim().isNotEmpty;
  bool get hasActiveFilters => _filterOptions.value.hasActiveFilters;

  @override
  void onInit() {
    super.onInit();
    _initializeDiscovery();
    
    // Set up reactive filtering
    debounce(_searchQuery, _performSearch, time: _debounceDelay);
    ever(_filterOptions, (_) => _applyFilters());
  }

  @override
  void onClose() {
    _searchDebouncer?.cancel();
    super.onClose();
  }

  /// Initialize discovery with location and initial data
  Future<void> _initializeDiscovery() async {
    try {
      _isLoading.value = true;
      
      // Load initial data concurrently
      await Future.wait([
        _loadUserLocation(),
        _loadCategories(),
        _loadPopularServices(),
        _loadInitialClinics(),
      ]);
      
    } catch (e) {
      _handleError('Erro ao inicializar descoberta', e);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load user's current location
  Future<void> _loadUserLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      _userLocation.value = position;
      
      // Update filters with user location if not set
      if (_filterOptions.value.location == null) {
        final locationFilter = LocationFilter(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _filterOptions.value = _filterOptions.value.copyWith(
          location: locationFilter,
        );
      }
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
      // Continue without location
    }
  }

  /// Load available categories
  Future<void> _loadCategories() async {
    try {
      final response = await _apiService.get('/categories');
      if (response.isSuccess && response.data != null) {
        _categories.value = List<String>.from(response.data['categories'] ?? []);
      }
    } catch (e) {
      debugPrint('Erro ao carregar categorias: $e');
      // Use fallback categories
      _categories.value = CategoryFilter.availableCategories;
    }
  }

  /// Load popular services for quick access
  Future<void> _loadPopularServices() async {
    try {
      final response = await _apiService.get('/services/popular');
      if (response.isSuccess && response.data != null) {
        final servicesData = response.data['services'] as List;
        _popularServices.value = servicesData
            .map((s) => Service.fromJson(s))
            .toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar serviços populares: $e');
    }
  }

  /// Load initial clinics based on location
  Future<void> _loadInitialClinics() async {
    try {
      final searchQuery = SearchQuery(
        filters: _filterOptions.value,
        page: 1,
        limit: 20,
      );
      
      final response = await _searchClinics(searchQuery);
      _clinics.value = response.clinics;
      _filteredClinics.value = response.clinics;
      _searchResultsCount.value = response.totalCount;
      _hasMoreData.value = response.hasMore;
      _currentPage.value = 1;
      
    } catch (e) {
      debugPrint('Erro ao carregar clínicas iniciais: $e');
    }
  }

  /// Toggle between list and map view
  void toggleViewMode() {
    _currentViewMode.value = _currentViewMode.value == ViewMode.list
        ? ViewMode.map
        : ViewMode.list;
  }

  /// Set specific view mode
  void setViewMode(ViewMode mode) {
    _currentViewMode.value = mode;
  }

  /// Update search query and trigger search
  void updateSearchQuery(String query) {
    _searchQuery.value = query;
  }

  /// Perform search with debouncing
  void _performSearch(String query) async {
    try {
      _lastSearchTimestamp.value = DateTime.now();
      
      // Check cache first
      final cacheKey = _buildCacheKey(query, _filterOptions.value);
      if (_isCacheValid(cacheKey)) {
        final cachedResults = _searchCache[cacheKey]!;
        _updateSearchResults(cachedResults, cachedResults.length, false);
        return;
      }

      _isLoading.value = true;
      _currentPage.value = 1;

      final searchQuery = SearchQuery(
        query: query,
        filters: _filterOptions.value,
        page: 1,
        limit: 20,
      );

      final response = await _searchClinics(searchQuery);
      
      // Cache results
      _searchCache[cacheKey] = response.clinics;
      _cacheTimestamps[cacheKey] = DateTime.now();

      _updateSearchResults(response.clinics, response.totalCount, response.hasMore);

    } catch (e) {
      _handleError('Erro na pesquisa', e);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Apply current filters to search results
  void _applyFilters() {
    if (_searchQuery.value.isEmpty && !_filterOptions.value.hasActiveFilters) {
      // Reset to initial results
      _loadInitialClinics();
      return;
    }

    // Trigger new search with filters
    _performSearch(_searchQuery.value);
  }

  /// Load more clinics for pagination
  Future<void> loadMoreClinics() async {
    if (_isLoadingMore.value || !_hasMoreData.value) return;

    try {
      _isLoadingMore.value = true;
      final nextPage = _currentPage.value + 1;

      final searchQuery = SearchQuery(
        query: _searchQuery.value,
        filters: _filterOptions.value,
        page: nextPage,
        limit: 20,
      );

      final response = await _searchClinics(searchQuery);
      
      _clinics.addAll(response.clinics);
      _filteredClinics.addAll(response.clinics);
      _hasMoreData.value = response.hasMore;
      _currentPage.value = nextPage;

    } catch (e) {
      _handleError('Erro ao carregar mais clínicas', e);
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Update filter options
  void updateFilters(FilterOptions newFilters) {
    _filterOptions.value = newFilters;
  }

  /// Clear all filters
  void clearAllFilters() {
    _filterOptions.value = FilterOptions.defaultFilters;
  }

  /// Apply quick filter preset
  void applyQuickFilter(FilterOptions preset) {
    _filterOptions.value = preset.copyWith(
      location: _filterOptions.value.location, // Keep current location
    );
  }

  /// Refresh discovery data
  Future<void> refreshDiscovery() async {
    _clearCache();
    _currentPage.value = 1;
    await _initializeDiscovery();
  }

  /// Search for specific service
  Future<void> searchForService(String serviceName) async {
    _searchQuery.value = serviceName;
  }

  /// Filter by category
  void filterByCategory(String category) {
    final categories = CategoryFilter(selectedCategories: [category]);
    _filterOptions.value = _filterOptions.value.copyWith(categories: categories);
  }

  /// Get clinic by ID with details
  Future<Clinic?> getClinicDetails(String clinicId) async {
    try {
      // First check if clinic is already in memory
      final existingClinic = _clinics.firstWhereOrNull((c) => c.id == clinicId);
      
      final response = await _apiService.get('/clinics/$clinicId');
      if (response.isSuccess && response.data != null) {
        final clinic = Clinic.fromJson(response.data);
        
        // Update clinic in local list if exists
        if (existingClinic != null) {
          final index = _clinics.indexWhere((c) => c.id == clinicId);
          if (index != -1) {
            _clinics[index] = clinic;
            _filteredClinics[index] = clinic;
          }
        }
        
        return clinic;
      }
    } catch (e) {
      _handleError('Erro ao carregar detalhes da clínica', e);
    }
    return null;
  }

  /// Toggle clinic favorite status
  Future<void> toggleClinicFavorite(String clinicId) async {
    try {
      final clinic = _clinics.firstWhereOrNull((c) => c.id == clinicId);
      if (clinic == null) return;

      final isFavorite = !clinic.isFavorite;
      
      // Optimistic update
      final updatedClinic = clinic.copyWith(isFavorite: isFavorite);
      final clinicIndex = _clinics.indexWhere((c) => c.id == clinicId);
      if (clinicIndex != -1) {
        _clinics[clinicIndex] = updatedClinic;
        _filteredClinics[clinicIndex] = updatedClinic;
      }

      // API call
      final endpoint = isFavorite ? '/clinics/$clinicId/favorite' : '/clinics/$clinicId/unfavorite';
      await _apiService.post(endpoint, {});

    } catch (e) {
      // Revert optimistic update on error
      final originalClinic = _clinics.firstWhereOrNull((c) => c.id == clinicId);
      if (originalClinic != null) {
        final revertedClinic = originalClinic.copyWith(isFavorite: !originalClinic.isFavorite);
        final clinicIndex = _clinics.indexWhere((c) => c.id == clinicId);
        if (clinicIndex != -1) {
          _clinics[clinicIndex] = revertedClinic;
          _filteredClinics[clinicIndex] = revertedClinic;
        }
      }
      _handleError('Erro ao atualizar favorito', e);
    }
  }

  /// Private helper methods

  Future<SearchResponse> _searchClinics(SearchQuery query) async {
    final response = await _apiService.get('/clinics/search', query.toQueryParams());
    
    if (!response.isSuccess) {
      throw Exception('Erro na busca de clínicas');
    }

    final data = response.data;
    final clinicsData = data['clinics'] as List;
    final clinics = clinicsData.map((c) => Clinic.fromJson(c)).toList();
    
    // Calculate distances if user location is available
    if (_userLocation.value != null) {
      clinics.forEach((clinic) {
        final distance = Geolocator.distanceBetween(
          _userLocation.value!.latitude,
          _userLocation.value!.longitude,
          clinic.latitude,
          clinic.longitude,
        ) / 1000; // Convert to km
        
        clinic = clinic.copyWith(distanceKm: distance);
      });
    }

    return SearchResponse(
      clinics: clinics,
      totalCount: data['totalCount'] as int? ?? clinics.length,
      hasMore: data['hasMore'] as bool? ?? false,
    );
  }

  void _updateSearchResults(List<Clinic> clinics, int totalCount, bool hasMore) {
    _clinics.value = clinics;
    _filteredClinics.value = clinics;
    _searchResultsCount.value = totalCount;
    _hasMoreData.value = hasMore;
  }

  String _buildCacheKey(String query, FilterOptions filters) {
    return '$query-${filters.hashCode}';
  }

  bool _isCacheValid(String cacheKey) {
    if (!_searchCache.containsKey(cacheKey)) return false;
    
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheValidityDuration;
  }

  void _clearCache() {
    _searchCache.clear();
    _cacheTimestamps.clear();
  }

  void _handleError(String message, dynamic error) {
    debugPrint('$message: $error');
    Get.snackbar(
      'Erro',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

/// View mode enumeration
enum ViewMode {
  list('Lista'),
  map('Mapa');

  const ViewMode(this.displayName);
  final String displayName;
}

/// Search response model
class SearchResponse {
  final List<Clinic> clinics;
  final int totalCount;
  final bool hasMore;

  const SearchResponse({
    required this.clinics,
    required this.totalCount,
    required this.hasMore,
  });
}