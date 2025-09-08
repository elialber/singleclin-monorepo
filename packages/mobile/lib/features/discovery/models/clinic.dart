import 'package:flutter/material.dart';\nimport 'package:equatable/equatable.dart';
import 'service.dart';

/// Represents a clinic/healthcare facility in the SingleClin platform
class Clinic extends Equatable {
  final String id;
  final String name;
  final String description;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final double latitude;
  final double longitude;
  final String phone;
  final String email;
  final String? website;
  final List<String> images;
  final String? logoUrl;
  final double rating;
  final int reviewCount;
  final List<String> categories;
  final List<Service> services;
  final bool isVerified;
  final bool isActive;
  final bool acceptsSG;
  final ClinicSchedule schedule;
  final List<String> amenities;
  final String? specialtyDescription;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final double? distanceKm;

  const Clinic({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.email,
    this.website,
    required this.images,
    this.logoUrl,
    required this.rating,
    required this.reviewCount,
    required this.categories,
    required this.services,
    required this.isVerified,
    required this.isActive,
    required this.acceptsSG,
    required this.schedule,
    required this.amenities,
    this.specialtyDescription,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.distanceKm,
  });

  /// Full address formatted for display
  String get fullAddress => '$address, $city - $state, $zipCode';

  /// Location formatted for display
  String get location => '$city - $state';

  /// Formatted rating display
  String get formattedRating => rating.toStringAsFixed(1);

  /// Review count formatted for display
  String get formattedReviews {
    if (reviewCount == 0) return 'Sem avaliações';
    if (reviewCount == 1) return '1 avaliação';
    return '$reviewCount avaliações';
  }

  /// Distance formatted for display
  String get formattedDistance {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) return '${(distanceKm! * 1000).toInt()}m';
    return '${distanceKm!.toStringAsFixed(1)}km';
  }

  /// Get minimum service price in SG credits
  int get minPrice {
    if (services.isEmpty) return 0;
    return services.map((s) => s.priceInSG).reduce((a, b) => a < b ? a : b);
  }

  /// Get maximum service price in SG credits
  int get maxPrice {
    if (services.isEmpty) return 0;
    return services.map((s) => s.priceInSG).reduce((a, b) => a > b ? a : b);
  }

  /// Get price range formatted for display
  String get priceRange {
    if (services.isEmpty) return 'Preços sob consulta';
    if (minPrice == maxPrice) return '${minPrice}SG';
    return '${minPrice}SG - ${maxPrice}SG';
  }

  /// Check if clinic is currently open
  bool get isCurrentlyOpen => schedule.isOpenNow();

  /// Get next opening time
  String get nextOpeningTime => schedule.getNextOpeningTime();

  /// Get main category for display
  String get mainCategory => categories.isNotEmpty ? categories.first : 'Geral';

  /// Create copy with updated fields
  Clinic copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? website,
    List<String>? images,
    String? logoUrl,
    double? rating,
    int? reviewCount,
    List<String>? categories,
    List<Service>? services,
    bool? isVerified,
    bool? isActive,
    bool? acceptsSG,
    ClinicSchedule? schedule,
    List<String>? amenities,
    String? specialtyDescription,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    double? distanceKm,
  }) {
    return Clinic(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      images: images ?? this.images,
      logoUrl: logoUrl ?? this.logoUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      categories: categories ?? this.categories,
      services: services ?? this.services,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      acceptsSG: acceptsSG ?? this.acceptsSG,
      schedule: schedule ?? this.schedule,
      amenities: amenities ?? this.amenities,
      specialtyDescription: specialtyDescription ?? this.specialtyDescription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  /// Create from JSON
  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String,
      email: json['email'] as String,
      website: json['website'] as String?,
      images: List<String>.from(json['images'] as List? ?? []),
      logoUrl: json['logoUrl'] as String?,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      categories: List<String>.from(json['categories'] as List? ?? []),
      services: (json['services'] as List? ?? [])
          .map((s) => Service.fromJson(s as Map<String, dynamic>))
          .toList(),
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      acceptsSG: json['acceptsSG'] as bool? ?? true,
      schedule: ClinicSchedule.fromJson(json['schedule'] as Map<String, dynamic>),
      amenities: List<String>.from(json['amenities'] as List? ?? []),
      specialtyDescription: json['specialtyDescription'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      distanceKm: json['distanceKm'] as double?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'website': website,
      'images': images,
      'logoUrl': logoUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'categories': categories,
      'services': services.map((s) => s.toJson()).toList(),
      'isVerified': isVerified,
      'isActive': isActive,
      'acceptsSG': acceptsSG,
      'schedule': schedule.toJson(),
      'amenities': amenities,
      'specialtyDescription': specialtyDescription,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFavorite': isFavorite,
      'distanceKm': distanceKm,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        address,
        city,
        state,
        zipCode,
        latitude,
        longitude,
        phone,
        email,
        website,
        images,
        logoUrl,
        rating,
        reviewCount,
        categories,
        services,
        isVerified,
        isActive,
        acceptsSG,
        schedule,
        amenities,
        specialtyDescription,
        createdAt,
        updatedAt,
        isFavorite,
        distanceKm,
      ];
}

/// Represents clinic operating schedule
class ClinicSchedule extends Equatable {
  final Map<String, DaySchedule> weekSchedule;
  final List<String> holidays;
  final String? specialNotes;

  const ClinicSchedule({
    required this.weekSchedule,
    this.holidays = const [],
    this.specialNotes,
  });

  /// Check if clinic is open now
  bool isOpenNow() {
    final now = DateTime.now();
    final weekday = _getWeekdayKey(now.weekday);
    final daySchedule = weekSchedule[weekday];
    
    if (daySchedule == null || !daySchedule.isOpen) return false;
    
    final currentTime = TimeOfDay.fromDateTime(now);
    return daySchedule.isOpenAt(currentTime);
  }

  /// Get next opening time as formatted string
  String getNextOpeningTime() {
    if (isOpenNow()) return 'Aberto agora';
    
    final now = DateTime.now();
    // Check today first
    for (int i = 0; i < 7; i++) {
      final checkDate = now.add(Duration(days: i));
      final weekday = _getWeekdayKey(checkDate.weekday);
      final daySchedule = weekSchedule[weekday];
      
      if (daySchedule?.isOpen == true) {
        if (i == 0) return 'Abre às ${daySchedule!.openTime.format()}';
        if (i == 1) return 'Abre amanhã às ${daySchedule!.openTime.format()}';
        return 'Abre ${_getWeekdayName(checkDate.weekday)} às ${daySchedule!.openTime.format()}';
      }
    }
    
    return 'Fechado';
  }

  String _getWeekdayKey(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return 'segunda';
      case 2: return 'terça';
      case 3: return 'quarta';
      case 4: return 'quinta';
      case 5: return 'sexta';
      case 6: return 'sábado';
      case 7: return 'domingo';
      default: return '';
    }
  }

  factory ClinicSchedule.fromJson(Map<String, dynamic> json) {
    final weekScheduleData = json['weekSchedule'] as Map<String, dynamic>? ?? {};
    final weekSchedule = <String, DaySchedule>{};
    
    for (final entry in weekScheduleData.entries) {
      weekSchedule[entry.key] = DaySchedule.fromJson(entry.value);
    }
    
    return ClinicSchedule(
      weekSchedule: weekSchedule,
      holidays: List<String>.from(json['holidays'] as List? ?? []),
      specialNotes: json['specialNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final weekScheduleData = <String, dynamic>{};
    for (final entry in weekSchedule.entries) {
      weekScheduleData[entry.key] = entry.value.toJson();
    }
    
    return {
      'weekSchedule': weekScheduleData,
      'holidays': holidays,
      'specialNotes': specialNotes,
    };
  }

  @override
  List<Object?> get props => [weekSchedule, holidays, specialNotes];
}

/// Represents a single day schedule
class DaySchedule extends Equatable {
  final bool isOpen;
  final TimeOfDay openTime;
  final TimeOfDay closeTime;
  final TimeOfDay? lunchBreakStart;
  final TimeOfDay? lunchBreakEnd;

  const DaySchedule({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
    this.lunchBreakStart,
    this.lunchBreakEnd,
  });

  /// Check if open at specific time
  bool isOpenAt(TimeOfDay time) {
    if (!isOpen) return false;
    
    final timeMinutes = time.hour * 60 + time.minute;
    final openMinutes = openTime.hour * 60 + openTime.minute;
    final closeMinutes = closeTime.hour * 60 + closeTime.minute;
    
    // Check if within lunch break
    if (lunchBreakStart != null && lunchBreakEnd != null) {
      final lunchStartMinutes = lunchBreakStart!.hour * 60 + lunchBreakStart!.minute;
      final lunchEndMinutes = lunchBreakEnd!.hour * 60 + lunchBreakEnd!.minute;
      
      if (timeMinutes >= lunchStartMinutes && timeMinutes <= lunchEndMinutes) {
        return false;
      }
    }
    
    return timeMinutes >= openMinutes && timeMinutes <= closeMinutes;
  }

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      isOpen: json['isOpen'] as bool,
      openTime: TimeOfDay(
        hour: json['openHour'] as int,
        minute: json['openMinute'] as int,
      ),
      closeTime: TimeOfDay(
        hour: json['closeHour'] as int,
        minute: json['closeMinute'] as int,
      ),
      lunchBreakStart: json['lunchStartHour'] != null
          ? TimeOfDay(
              hour: json['lunchStartHour'] as int,
              minute: json['lunchStartMinute'] as int? ?? 0,
            )
          : null,
      lunchBreakEnd: json['lunchEndHour'] != null
          ? TimeOfDay(
              hour: json['lunchEndHour'] as int,
              minute: json['lunchEndMinute'] as int? ?? 0,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOpen': isOpen,
      'openHour': openTime.hour,
      'openMinute': openTime.minute,
      'closeHour': closeTime.hour,
      'closeMinute': closeTime.minute,
      'lunchStartHour': lunchBreakStart?.hour,
      'lunchStartMinute': lunchBreakStart?.minute,
      'lunchEndHour': lunchBreakEnd?.hour,
      'lunchEndMinute': lunchBreakEnd?.minute,
    };
  }

  @override
  List<Object?> get props => [
        isOpen,
        openTime,
        closeTime,
        lunchBreakStart,
        lunchBreakEnd,
      ];
}

/// Extension for TimeOfDay formatting
extension TimeOfDayExtension on TimeOfDay {
  String format() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}