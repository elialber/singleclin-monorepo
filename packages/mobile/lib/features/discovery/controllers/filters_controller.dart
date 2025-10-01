import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import 'package:singleclin_mobile/core/services/location_service.dart';
import 'package:singleclin_mobile/features/discovery/models/filter_options.dart';
import 'package:singleclin_mobile/features/discovery/controllers/discovery_controller.dart';

/// Filters controller managing advanced filtering options and search refinement
class FiltersController extends GetxController {
  final LocationService _locationService = Get.find<LocationService>();
  final DiscoveryController _discoveryController =
      Get.find<DiscoveryController>();

  // Current filter state
  final _currentFilters = FilterOptions.defaultFilters.obs;
  final _tempFilters = FilterOptions.defaultFilters.obs;
  final _isLocationLoading = false.obs;
  final _availableAmenities = <String>[].obs;

  // Filter UI state
  final _expandedSections = <String, bool>{}.obs;
  final _priceRangeValues = const RangeValues(0, 500).obs;
  final _distanceValue = 10.0.obs;
  final _minimumRating = 0.0.obs;

  // Getters
  FilterOptions get currentFilters => _currentFilters.value;
  FilterOptions get tempFilters => _tempFilters.value;
  bool get isLocationLoading => _isLocationLoading.value;
  List<String> get availableAmenities => _availableAmenities;
  RangeValues get priceRangeValues => _priceRangeValues.value;
  double get distanceValue => _distanceValue.value;
  double get minimumRating => _minimumRating.value;

  bool isSectionExpanded(String section) => _expandedSections[section] ?? false;

  @override
  void onInit() {
    super.onInit();
    _loadAvailableAmenities();
    _syncWithDiscoveryController();
  }

  /// Sync filters with discovery controller
  void _syncWithDiscoveryController() {
    _currentFilters.value = _discoveryController.filterOptions;
    _tempFilters.value = _discoveryController.filterOptions;
    _updateUIStateFromFilters(_currentFilters.value);
  }

  /// Load available amenities from API
  Future<void> _loadAvailableAmenities() async {
    try {
      // Mock amenities for now - would come from API
      _availableAmenities.value = [
        'Estacionamento',
        'WiFi Gratuito',
        'Ar Condicionado',
        'Sala de Espera',
        'Acessibilidade',
        'Pagamento PIX',
        'Cartão de Crédito',
        'Parcelamento',
        'Consultório Privado',
        'Equipamentos Modernos',
      ];
    } catch (e) {
      debugPrint('Erro ao carregar amenidades: $e');
    }
  }

  /// Initialize temporary filters for editing
  void initializeTempFilters() {
    _tempFilters.value = _currentFilters.value;
    _updateUIStateFromFilters(_tempFilters.value);
  }

  /// Update UI state from filter options
  void _updateUIStateFromFilters(FilterOptions filters) {
    // Update price range
    _priceRangeValues.value = RangeValues(
      filters.priceRange.minPrice?.toDouble() ?? 0,
      filters.priceRange.maxPrice?.toDouble() ?? 500,
    );

    // Update distance
    if (filters.distance != null) {
      _distanceValue.value = filters.distance!.maxDistanceKm;
    }

    // Update rating
    _minimumRating.value = filters.rating.minimumRating ?? 0.0;
  }

  /// Toggle filter section expansion
  void toggleSectionExpansion(String section) {
    _expandedSections[section] = !isSectionExpanded(section);
  }

  /// Update location filter
  Future<void> updateLocationFilter() async {
    try {
      _isLocationLoading.value = true;

      final position = await _locationService.getCurrentPosition();
      final locationFilter = LocationFilter(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _tempFilters.value = _tempFilters.value.copyWith(
        location: locationFilter,
      );
    } catch (e) {
      Get.snackbar(
        'Erro de Localização',
        'Não foi possível obter sua localização atual',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLocationLoading.value = false;
    }
  }

  /// Update price range filter
  void updatePriceRange(RangeValues values) {
    _priceRangeValues.value = values;

    final priceFilter = PriceRangeFilter(
      minPrice: values.start > 0 ? values.start.toInt() : null,
      maxPrice: values.end < 500 ? values.end.toInt() : null,
    );

    _tempFilters.value = _tempFilters.value.copyWith(priceRange: priceFilter);
  }

  /// Update distance filter
  void updateDistance(double distance) {
    _distanceValue.value = distance;

    final userLocation = _discoveryController.userLocation;
    final distanceFilter = userLocation != null
        ? DistanceFilter(
            maxDistanceKm: distance,
            centerLatitude: userLocation.latitude,
            centerLongitude: userLocation.longitude,
          )
        : DistanceFilter(maxDistanceKm: distance);

    _tempFilters.value = _tempFilters.value.copyWith(distance: distanceFilter);
  }

  /// Update minimum rating filter
  void updateMinimumRating(double rating) {
    _minimumRating.value = rating;

    final ratingFilter = rating > 0
        ? RatingFilter(minimumRating: rating)
        : const RatingFilter();

    _tempFilters.value = _tempFilters.value.copyWith(rating: ratingFilter);
  }

  /// Toggle category selection
  void toggleCategory(String category) {
    final currentCategories = _tempFilters.value.categories;
    final updatedCategories = currentCategories.toggleCategory(category);

    _tempFilters.value = _tempFilters.value.copyWith(
      categories: updatedCategories,
    );
  }

  /// Clear all selected categories
  void clearAllCategories() {
    _tempFilters.value = _tempFilters.value.copyWith(
      categories: const CategoryFilter(),
    );
  }

  /// Select all categories
  void selectAllCategories() {
    const allCategories = CategoryFilter(
      selectedCategories: CategoryFilter.availableCategories,
    );
    _tempFilters.value = _tempFilters.value.copyWith(categories: allCategories);
  }

  /// Update availability filter for today
  void setAvailabilityToday(bool value) {
    final availability = value
        ? const AvailabilityFilter(todayOnly: true)
        : const AvailabilityFilter();

    _tempFilters.value = _tempFilters.value.copyWith(
      availability: availability,
    );
  }

  /// Update availability filter for this week
  void setAvailabilityThisWeek(bool value) {
    final availability = value
        ? const AvailabilityFilter(thisWeekOnly: true)
        : const AvailabilityFilter();

    _tempFilters.value = _tempFilters.value.copyWith(
      availability: availability,
    );
  }

  /// Set specific date availability
  void setSpecificDateAvailability(DateTime? date, TimeOfDay? time) {
    final availability = AvailabilityFilter(
      specificDate: date,
      specificTime: time,
    );

    _tempFilters.value = _tempFilters.value.copyWith(
      availability: availability,
    );
  }

  /// Toggle verified clinics only
  void toggleVerifiedClinicsOnly(bool value) {
    _tempFilters.value = _tempFilters.value.copyWith(
      onlyVerifiedClinics: value,
    );
  }

  /// Toggle accepting SG only
  void toggleAcceptingSGOnly(bool value) {
    _tempFilters.value = _tempFilters.value.copyWith(onlyAcceptingSG: value);
  }

  /// Toggle promotion only
  void togglePromotionOnly(bool value) {
    _tempFilters.value = _tempFilters.value.copyWith(onlyWithPromotion: value);
  }

  /// Toggle amenity selection
  void toggleAmenity(String amenity) {
    final currentAmenities = List<String>.from(_tempFilters.value.amenities);

    if (currentAmenities.contains(amenity)) {
      currentAmenities.remove(amenity);
    } else {
      currentAmenities.add(amenity);
    }

    _tempFilters.value = _tempFilters.value.copyWith(
      amenities: currentAmenities,
    );
  }

  /// Clear all amenities
  void clearAllAmenities() {
    _tempFilters.value = _tempFilters.value.copyWith(amenities: const []);
  }

  /// Update sort option
  void updateSortOption(SortOption sortBy) {
    _tempFilters.value = _tempFilters.value.copyWith(sortBy: sortBy);
  }

  /// Apply quick filter preset
  void applyQuickFilter(String presetName) {
    final preset = QuickFilters.presets
        .firstWhereOrNull((p) => p.key == presetName)
        ?.value;

    if (preset != null) {
      _tempFilters.value = preset.copyWith(
        location: _tempFilters.value.location, // Keep current location
      );
      _updateUIStateFromFilters(_tempFilters.value);
    }
  }

  /// Apply filters and update discovery controller
  void applyFilters() {
    _currentFilters.value = _tempFilters.value;
    _discoveryController.updateFilters(_currentFilters.value);

    Get.back(); // Close filters screen

    Get.snackbar(
      'Filtros Aplicados',
      _getFiltersAppliedMessage(),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  /// Reset all filters to default
  void resetFilters() {
    _tempFilters.value = FilterOptions.defaultFilters.copyWith(
      location: _currentFilters.value.location, // Keep current location
    );
    _updateUIStateFromFilters(_tempFilters.value);
  }

  /// Clear all filters
  void clearAllFilters() {
    _tempFilters.value = const FilterOptions();
    _updateUIStateFromFilters(_tempFilters.value);
  }

  /// Cancel filter editing
  void cancelFilters() {
    _tempFilters.value = _currentFilters.value;
    _updateUIStateFromFilters(_tempFilters.value);
    Get.back();
  }

  /// Get count of active filters
  int get activeFiltersCount => _tempFilters.value.activeFiltersCount;

  /// Check if filters have changes
  bool get hasChanges => _tempFilters.value != _currentFilters.value;

  /// Get formatted price range text
  String get priceRangeText {
    final values = _priceRangeValues.value;
    if (values.start <= 0 && values.end >= 500) {
      return 'Qualquer preço';
    } else if (values.start <= 0) {
      return 'Até ${values.end.toInt()}SG';
    } else if (values.end >= 500) {
      return 'A partir de ${values.start.toInt()}SG';
    } else {
      return '${values.start.toInt()}SG - ${values.end.toInt()}SG';
    }
  }

  /// Get formatted distance text
  String get distanceText {
    if (_distanceValue.value >= 50) {
      return 'Qualquer distância';
    } else if (_distanceValue.value < 1) {
      return '${(_distanceValue.value * 1000).toInt()}m';
    } else {
      return '${_distanceValue.value.toStringAsFixed(1)}km';
    }
  }

  /// Get formatted rating text
  String get ratingText {
    if (_minimumRating.value <= 0) {
      return 'Qualquer avaliação';
    } else {
      return '${_minimumRating.value.toStringAsFixed(1)}+ estrelas';
    }
  }

  /// Get selected categories count text
  String get selectedCategoriesText {
    final count = _tempFilters.value.categories.selectedCategories.length;
    if (count == 0) {
      return 'Todas as categorias';
    } else if (count == 1) {
      return _tempFilters.value.categories.selectedCategories.first;
    } else {
      return '$count categorias selecionadas';
    }
  }

  /// Get selected amenities count text
  String get selectedAmenitiesText {
    final count = _tempFilters.value.amenities.length;
    if (count == 0) {
      return 'Nenhuma amenidade selecionada';
    } else if (count == 1) {
      return _tempFilters.value.amenities.first;
    } else {
      return '$count amenidades selecionadas';
    }
  }

  /// Private helper to generate filters applied message
  String _getFiltersAppliedMessage() {
    final activeCount = activeFiltersCount;
    if (activeCount == 0) {
      return 'Todos os filtros removidos';
    } else if (activeCount == 1) {
      return '1 filtro aplicado';
    } else {
      return '$activeCount filtros aplicados';
    }
  }

  /// Save current filters as preset (for future implementation)
  Future<void> saveAsPreset(String name) async {
    // This would save to local storage or API
    Get.snackbar(
      'Preset Salvo',
      'Filtro personalizado "$name" foi salvo',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Load saved preset (for future implementation)
  Future<void> loadPreset(String name) async {
    // This would load from local storage or API
    Get.snackbar(
      'Preset Carregado',
      'Filtro personalizado "$name" foi aplicado',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
