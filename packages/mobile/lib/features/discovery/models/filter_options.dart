import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Comprehensive filter options for discovery search
class FilterOptions extends Equatable {
  final LocationFilter? location;
  final PriceRangeFilter priceRange;
  final RatingFilter rating;
  final CategoryFilter categories;
  final AvailabilityFilter availability;
  final DistanceFilter? distance;
  final SortOption sortBy;
  final bool onlyVerifiedClinics;
  final bool onlyAcceptingSG;
  final bool onlyWithPromotion;
  final List<String> amenities;

  const FilterOptions({
    this.location,
    this.priceRange = const PriceRangeFilter(),
    this.rating = const RatingFilter(),
    this.categories = const CategoryFilter(),
    this.availability = const AvailabilityFilter(),
    this.distance,
    this.sortBy = SortOption.relevance,
    this.onlyVerifiedClinics = false,
    this.onlyAcceptingSG = true,
    this.onlyWithPromotion = false,
    this.amenities = const [],
  });

  /// Check if any filters are active (not default)
  bool get hasActiveFilters {
    return location != null ||
           priceRange.hasRange ||
           rating.hasMinimum ||
           categories.hasSelection ||
           availability.hasRestriction ||
           distance != null ||
           onlyVerifiedClinics ||
           !onlyAcceptingSG ||
           onlyWithPromotion ||
           amenities.isNotEmpty;
  }

  /// Get count of active filter categories
  int get activeFiltersCount {
    int count = 0;
    if (location != null) count++;
    if (priceRange.hasRange) count++;
    if (rating.hasMinimum) count++;
    if (categories.hasSelection) count++;
    if (availability.hasRestriction) count++;
    if (distance != null) count++;
    if (onlyVerifiedClinics) count++;
    if (!onlyAcceptingSG) count++;
    if (onlyWithPromotion) count++;
    if (amenities.isNotEmpty) count++;
    return count;
  }

  /// Create default filter options
  static const FilterOptions defaultFilters = FilterOptions();

  /// Create filter options with only location
  FilterOptions withLocation(LocationFilter location) {
    return copyWith(location: location);
  }

  /// Clear all filters
  FilterOptions clearAll() {
    return const FilterOptions();
  }

  /// Create copy with updated fields
  FilterOptions copyWith({
    LocationFilter? location,
    PriceRangeFilter? priceRange,
    RatingFilter? rating,
    CategoryFilter? categories,
    AvailabilityFilter? availability,
    DistanceFilter? distance,
    SortOption? sortBy,
    bool? onlyVerifiedClinics,
    bool? onlyAcceptingSG,
    bool? onlyWithPromotion,
    List<String>? amenities,
  }) {
    return FilterOptions(
      location: location ?? this.location,
      priceRange: priceRange ?? this.priceRange,
      rating: rating ?? this.rating,
      categories: categories ?? this.categories,
      availability: availability ?? this.availability,
      distance: distance ?? this.distance,
      sortBy: sortBy ?? this.sortBy,
      onlyVerifiedClinics: onlyVerifiedClinics ?? this.onlyVerifiedClinics,
      onlyAcceptingSG: onlyAcceptingSG ?? this.onlyAcceptingSG,
      onlyWithPromotion: onlyWithPromotion ?? this.onlyWithPromotion,
      amenities: amenities ?? this.amenities,
    );
  }

  /// Convert to query parameters for API calls
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (location != null) {
      params.addAll(location!.toQueryParams());
    }
    
    if (priceRange.hasRange) {
      params['minPrice'] = priceRange.minPrice;
      params['maxPrice'] = priceRange.maxPrice;
    }
    
    if (rating.hasMinimum) {
      params['minRating'] = rating.minimumRating;
    }
    
    if (categories.hasSelection) {
      params['categories'] = categories.selectedCategories.join(',');
    }
    
    if (availability.hasRestriction) {
      if (availability.specificDate != null) {
        params['availableDate'] = availability.specificDate!.toIso8601String();
      }
      if (availability.specificTime != null) {
        params['availableTime'] = '${availability.specificTime!.hour}:${availability.specificTime!.minute}';
      }
      if (availability.todayOnly) {
        params['availableToday'] = true;
      }
      if (availability.thisWeekOnly) {
        params['availableThisWeek'] = true;
      }
    }
    
    if (distance != null) {
      params.addAll(distance!.toQueryParams());
    }
    
    params['sortBy'] = sortBy.name;
    
    if (onlyVerifiedClinics) {
      params['verifiedOnly'] = true;
    }
    
    if (!onlyAcceptingSG) {
      params['acceptsSG'] = false;
    }
    
    if (onlyWithPromotion) {
      params['promotionOnly'] = true;
    }
    
    if (amenities.isNotEmpty) {
      params['amenities'] = amenities.join(',');
    }
    
    return params;
  }

  /// Create from query parameters
  factory FilterOptions.fromQueryParams(Map<String, dynamic> params) {
    return FilterOptions(
      location: params.containsKey('latitude') && params.containsKey('longitude')
          ? LocationFilter.fromQueryParams(params)
          : null,
      priceRange: params.containsKey('minPrice') || params.containsKey('maxPrice')
          ? PriceRangeFilter.fromQueryParams(params)
          : const PriceRangeFilter(),
      rating: params.containsKey('minRating')
          ? RatingFilter.fromQueryParams(params)
          : const RatingFilter(),
      categories: params.containsKey('categories')
          ? CategoryFilter.fromQueryParams(params)
          : const CategoryFilter(),
      availability: AvailabilityFilter.fromQueryParams(params),
      distance: params.containsKey('maxDistance')
          ? DistanceFilter.fromQueryParams(params)
          : null,
      sortBy: params.containsKey('sortBy')
          ? SortOption.fromString(params['sortBy'] as String)
          : SortOption.relevance,
      onlyVerifiedClinics: params['verifiedOnly'] as bool? ?? false,
      onlyAcceptingSG: params['acceptsSG'] as bool? ?? true,
      onlyWithPromotion: params['promotionOnly'] as bool? ?? false,
      amenities: params.containsKey('amenities')
          ? (params['amenities'] as String).split(',')
          : const [],
    );
  }

  @override
  List<Object?> get props => [
        location,
        priceRange,
        rating,
        categories,
        availability,
        distance,
        sortBy,
        onlyVerifiedClinics,
        onlyAcceptingSG,
        onlyWithPromotion,
        amenities,
      ];
}

/// Location-based filtering
class LocationFilter extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;

  const LocationFilter({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
  });

  String get displayText {
    if (address != null) return address!;
    if (city != null && state != null) return '$city, $state';
    if (city != null) return city!;
    return 'Localização atual';
  }

  Map<String, dynamic> toQueryParams() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
    };
  }

  factory LocationFilter.fromQueryParams(Map<String, dynamic> params) {
    return LocationFilter(
      latitude: params['latitude'] as double,
      longitude: params['longitude'] as double,
      address: params['address'] as String?,
      city: params['city'] as String?,
      state: params['state'] as String?,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, address, city, state];
}

/// Price range filtering in SG credits
class PriceRangeFilter extends Equatable {
  final int? minPrice;
  final int? maxPrice;

  const PriceRangeFilter({
    this.minPrice,
    this.maxPrice,
  });

  bool get hasRange => minPrice != null || maxPrice != null;

  String get displayText {
    if (minPrice != null && maxPrice != null) {
      return '${minPrice}SG - ${maxPrice}SG';
    } else if (minPrice != null) {
      return 'A partir de ${minPrice}SG';
    } else if (maxPrice != null) {
      return 'Até ${maxPrice}SG';
    }
    return 'Qualquer preço';
  }

  /// Common price ranges for quick selection
  static const List<PriceRangeFilter> commonRanges = [
    PriceRangeFilter(), // Any price
    PriceRangeFilter(maxPrice: 50),
    PriceRangeFilter(minPrice: 50, maxPrice: 100),
    PriceRangeFilter(minPrice: 100, maxPrice: 200),
    PriceRangeFilter(minPrice: 200, maxPrice: 500),
    PriceRangeFilter(minPrice: 500),
  ];

  factory PriceRangeFilter.fromQueryParams(Map<String, dynamic> params) {
    return PriceRangeFilter(
      minPrice: params['minPrice'] as int?,
      maxPrice: params['maxPrice'] as int?,
    );
  }

  @override
  List<Object?> get props => [minPrice, maxPrice];
}

/// Rating-based filtering
class RatingFilter extends Equatable {
  final double? minimumRating;

  const RatingFilter({this.minimumRating});

  bool get hasMinimum => minimumRating != null;

  String get displayText {
    if (minimumRating != null) {
      return '${minimumRating!.toStringAsFixed(1)}+ estrelas';
    }
    return 'Qualquer avaliação';
  }

  /// Common rating filters
  static const List<RatingFilter> commonFilters = [
    RatingFilter(), // Any rating
    RatingFilter(minimumRating: 3.0),
    RatingFilter(minimumRating: 4.0),
    RatingFilter(minimumRating: 4.5),
  ];

  factory RatingFilter.fromQueryParams(Map<String, dynamic> params) {
    return RatingFilter(
      minimumRating: params['minRating'] as double?,
    );
  }

  @override
  List<Object?> get props => [minimumRating];
}

/// Category-based filtering
class CategoryFilter extends Equatable {
  final List<String> selectedCategories;

  const CategoryFilter({this.selectedCategories = const []});

  bool get hasSelection => selectedCategories.isNotEmpty;

  String get displayText {
    if (selectedCategories.isEmpty) return 'Todas as categorias';
    if (selectedCategories.length == 1) return selectedCategories.first;
    return '${selectedCategories.length} categorias';
  }

  /// Available service categories
  static const List<String> availableCategories = [
    'Estética Facial',
    'Estética Corporal',
    'Terapias Injetáveis',
    'Dermatologia',
    'Bem-estar',
    'Diagnósticos',
    'Performance',
    'Fisioterapia',
  ];

  CategoryFilter toggleCategory(String category) {
    final newCategories = List<String>.from(selectedCategories);
    if (newCategories.contains(category)) {
      newCategories.remove(category);
    } else {
      newCategories.add(category);
    }
    return CategoryFilter(selectedCategories: newCategories);
  }

  CategoryFilter clearAll() {
    return const CategoryFilter();
  }

  factory CategoryFilter.fromQueryParams(Map<String, dynamic> params) {
    return CategoryFilter(
      selectedCategories: (params['categories'] as String).split(','),
    );
  }

  @override
  List<Object?> get props => [selectedCategories];
}

/// Availability-based filtering
class AvailabilityFilter extends Equatable {
  final DateTime? specificDate;
  final TimeOfDay? specificTime;
  final bool todayOnly;
  final bool thisWeekOnly;

  const AvailabilityFilter({
    this.specificDate,
    this.specificTime,
    this.todayOnly = false,
    this.thisWeekOnly = false,
  });

  bool get hasRestriction => 
      specificDate != null || 
      specificTime != null || 
      todayOnly || 
      thisWeekOnly;

  String get displayText {
    if (todayOnly) return 'Disponível hoje';
    if (thisWeekOnly) return 'Disponível esta semana';
    if (specificDate != null && specificTime != null) {
      final dateStr = '${specificDate!.day}/${specificDate!.month}';
      final timeStr = '${specificTime!.hour.toString().padLeft(2, '0')}:${specificTime!.minute.toString().padLeft(2, '0')}';
      return '$dateStr às $timeStr';
    }
    if (specificDate != null) {
      return '${specificDate!.day}/${specificDate!.month}';
    }
    return 'Qualquer horário';
  }

  factory AvailabilityFilter.fromQueryParams(Map<String, dynamic> params) {
    return AvailabilityFilter(
      specificDate: params['availableDate'] != null
          ? DateTime.parse(params['availableDate'] as String)
          : null,
      specificTime: params['availableTime'] != null
          ? _parseTimeFromString(params['availableTime'] as String)
          : null,
      todayOnly: params['availableToday'] as bool? ?? false,
      thisWeekOnly: params['availableThisWeek'] as bool? ?? false,
    );
  }

  static TimeOfDay _parseTimeFromString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  @override
  List<Object?> get props => [specificDate, specificTime, todayOnly, thisWeekOnly];
}

/// Distance-based filtering
class DistanceFilter extends Equatable {
  final double maxDistanceKm;
  final double? centerLatitude;
  final double? centerLongitude;

  const DistanceFilter({
    required this.maxDistanceKm,
    this.centerLatitude,
    this.centerLongitude,
  });

  String get displayText {
    if (maxDistanceKm < 1) {
      return '${(maxDistanceKm * 1000).toInt()}m';
    }
    return '${maxDistanceKm.toStringAsFixed(1)}km';
  }

  /// Common distance options
  static const List<double> commonDistances = [
    0.5, 1.0, 2.0, 5.0, 10.0, 25.0, 50.0
  ];

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'maxDistance': maxDistanceKm,
    };
    
    if (centerLatitude != null && centerLongitude != null) {
      params['centerLat'] = centerLatitude;
      params['centerLng'] = centerLongitude;
    }
    
    return params;
  }

  factory DistanceFilter.fromQueryParams(Map<String, dynamic> params) {
    return DistanceFilter(
      maxDistanceKm: params['maxDistance'] as double,
      centerLatitude: params['centerLat'] as double?,
      centerLongitude: params['centerLng'] as double?,
    );
  }

  @override
  List<Object?> get props => [maxDistanceKm, centerLatitude, centerLongitude];
}

/// Sorting options for search results
enum SortOption {
  relevance('Relevância'),
  distance('Distância'),
  rating('Avaliação'),
  priceAsc('Menor preço'),
  priceDesc('Maior preço'),
  newest('Mais recentes'),
  popular('Mais populares');

  const SortOption(this.displayName);
  final String displayName;

  static SortOption fromString(String value) {
    for (final option in SortOption.values) {
      if (option.name == value) return option;
    }
    return SortOption.relevance;
  }
}

/// Search query model
class SearchQuery extends Equatable {
  final String query;
  final FilterOptions filters;
  final int page;
  final int limit;

  const SearchQuery({
    this.query = '',
    this.filters = const FilterOptions(),
    this.page = 1,
    this.limit = 20,
  });

  bool get hasQuery => query.trim().isNotEmpty;

  SearchQuery copyWith({
    String? query,
    FilterOptions? filters,
    int? page,
    int? limit,
  }) {
    return SearchQuery(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  /// Next page query
  SearchQuery nextPage() => copyWith(page: page + 1);

  /// Reset to first page
  SearchQuery resetPage() => copyWith(page: 1);

  Map<String, dynamic> toQueryParams() {
    final params = filters.toQueryParams();
    
    if (hasQuery) {
      params['q'] = query;
    }
    
    params['page'] = page;
    params['limit'] = limit;
    
    return params;
  }

  @override
  List<Object?> get props => [query, filters, page, limit];
}

/// Quick filter presets for common use cases
class QuickFilters {
  static const FilterOptions nearbyToday = FilterOptions(
    availability: AvailabilityFilter(todayOnly: true),
    onlyVerifiedClinics: true,
  );

  static const FilterOptions affordable = FilterOptions(
    priceRange: PriceRangeFilter(maxPrice: 100),
    onlyAcceptingSG: true,
  );

  static const FilterOptions premium = FilterOptions(
    priceRange: PriceRangeFilter(minPrice: 200),
    rating: RatingFilter(minimumRating: 4.5),
    onlyVerifiedClinics: true,
  );

  static const FilterOptions facialAesthetics = FilterOptions(
    categories: CategoryFilter(selectedCategories: ['Estética Facial']),
    onlyVerifiedClinics: true,
  );

  static const FilterOptions injectableTherapies = FilterOptions(
    categories: CategoryFilter(selectedCategories: ['Terapias Injetáveis']),
    onlyVerifiedClinics: true,
  );

  static const FilterOptions wellness = FilterOptions(
    categories: CategoryFilter(selectedCategories: ['Bem-estar']),
    rating: RatingFilter(minimumRating: 4.0),
  );

  static List<MapEntry<String, FilterOptions>> get presets => [
        const MapEntry('Próximo e disponível hoje', nearbyToday),
        const MapEntry('Até 100 SG', affordable),
        const MapEntry('Premium (4.5★+)', premium),
        const MapEntry('Estética Facial', facialAesthetics),
        const MapEntry('Terapias Injetáveis', injectableTherapies),
        const MapEntry('Bem-estar', wellness),
      ];
}