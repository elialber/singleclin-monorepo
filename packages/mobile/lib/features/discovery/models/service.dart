import 'package:equatable/equatable.dart';

/// Represents a medical/aesthetic service offered by a clinic
class Service extends Equatable {
  const Service({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.priceInSG,
    required this.durationMinutes,
    required this.isActive,
    required this.requiresConsultation,
    required this.createdAt,
    required this.updatedAt,
    this.subcategory,
    this.imageUrl,
    this.tags = const [],
    this.preparationInstructions,
    this.aftercareInstructions,
    this.minSessionGap = 0,
    this.recommendedSessions,
    this.pricing,
    this.availability = const [],
    this.isFeatured = false,
    this.isPopular = false,
  });

  /// Create from JSON
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      priceInSG: json['priceInSG'] as int,
      durationMinutes: json['durationMinutes'] as int,
      imageUrl: json['imageUrl'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      isActive: json['isActive'] as bool,
      requiresConsultation: json['requiresConsultation'] as bool? ?? false,
      preparationInstructions: json['preparationInstructions'] as String?,
      aftercareInstructions: json['aftercareInstructions'] as String?,
      minSessionGap: json['minSessionGap'] as int? ?? 0,
      recommendedSessions: json['recommendedSessions'] as int?,
      pricing: json['pricing'] != null
          ? ServicePricing.fromJson(json['pricing'] as Map<String, dynamic>)
          : null,
      availability: (json['availability'] as List? ?? [])
          .map((a) => ServiceAvailability.fromJson(a as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isFeatured: json['isFeatured'] as bool? ?? false,
      isPopular: json['isPopular'] as bool? ?? false,
    );
  }
  final String id;
  final String name;
  final String description;
  final String category;
  final String? subcategory;
  final int priceInSG;
  final int durationMinutes;
  final String? imageUrl;
  final List<String> tags;
  final bool isActive;
  final bool requiresConsultation;
  final String? preparationInstructions;
  final String? aftercareInstructions;
  final int minSessionGap; // Days between sessions
  final int? recommendedSessions;
  final ServicePricing? pricing;
  final List<ServiceAvailability> availability;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFeatured;
  final bool isPopular;

  /// Formatted duration display
  String get formattedDuration {
    if (durationMinutes < 60) return '${durationMinutes}min';
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}min';
  }

  /// Formatted price display
  String get formattedPrice => '${priceInSG}SG';

  /// Get session gap formatted text
  String get sessionGapText {
    if (minSessionGap == 0) return 'Pode ser repetido imediatamente';
    if (minSessionGap == 1) return 'Aguardar 1 dia entre sessões';
    if (minSessionGap < 7) return 'Aguardar $minSessionGap dias entre sessões';
    final weeks = minSessionGap ~/ 7;
    if (weeks == 1) return 'Aguardar 1 semana entre sessões';
    return 'Aguardar $weeks semanas entre sessões';
  }

  /// Get recommended sessions text
  String get recommendedSessionsText {
    if (recommendedSessions == null) return '';
    if (recommendedSessions == 1) return 'Sessão única';
    return '$recommendedSessions sessões recomendadas';
  }

  /// Check if service is available on a specific date
  bool isAvailableOn(DateTime date) {
    if (availability.isEmpty) return true;

    final weekday = date.weekday;
    return availability.any((avail) => avail.isAvailableOn(weekday));
  }

  /// Get next available date
  DateTime? getNextAvailableDate([DateTime? fromDate]) {
    if (availability.isEmpty) return fromDate ?? DateTime.now();

    final startDate = fromDate ?? DateTime.now();
    for (int i = 0; i < 30; i++) {
      // Check next 30 days
      final checkDate = startDate.add(Duration(days: i));
      if (isAvailableOn(checkDate)) return checkDate;
    }
    return null;
  }

  /// Create copy with updated fields
  Service copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? subcategory,
    int? priceInSG,
    int? durationMinutes,
    String? imageUrl,
    List<String>? tags,
    bool? isActive,
    bool? requiresConsultation,
    String? preparationInstructions,
    String? aftercareInstructions,
    int? minSessionGap,
    int? recommendedSessions,
    ServicePricing? pricing,
    List<ServiceAvailability>? availability,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFeatured,
    bool? isPopular,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      priceInSG: priceInSG ?? this.priceInSG,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      requiresConsultation: requiresConsultation ?? this.requiresConsultation,
      preparationInstructions:
          preparationInstructions ?? this.preparationInstructions,
      aftercareInstructions:
          aftercareInstructions ?? this.aftercareInstructions,
      minSessionGap: minSessionGap ?? this.minSessionGap,
      recommendedSessions: recommendedSessions ?? this.recommendedSessions,
      pricing: pricing ?? this.pricing,
      availability: availability ?? this.availability,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFeatured: isFeatured ?? this.isFeatured,
      isPopular: isPopular ?? this.isPopular,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'priceInSG': priceInSG,
      'durationMinutes': durationMinutes,
      'imageUrl': imageUrl,
      'tags': tags,
      'isActive': isActive,
      'requiresConsultation': requiresConsultation,
      'preparationInstructions': preparationInstructions,
      'aftercareInstructions': aftercareInstructions,
      'minSessionGap': minSessionGap,
      'recommendedSessions': recommendedSessions,
      'pricing': pricing?.toJson(),
      'availability': availability.map((a) => a.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFeatured': isFeatured,
      'isPopular': isPopular,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    category,
    subcategory,
    priceInSG,
    durationMinutes,
    imageUrl,
    tags,
    isActive,
    requiresConsultation,
    preparationInstructions,
    aftercareInstructions,
    minSessionGap,
    recommendedSessions,
    pricing,
    availability,
    createdAt,
    updatedAt,
    isFeatured,
    isPopular,
  ];
}

/// Represents service pricing options
class ServicePricing extends Equatable {
  const ServicePricing({
    required this.singleSessionPrice,
    this.package3Sessions,
    this.package5Sessions,
    this.package10Sessions,
    this.hasConsultationFee = false,
    this.consultationFeeInSG,
  });

  factory ServicePricing.fromJson(Map<String, dynamic> json) {
    return ServicePricing(
      singleSessionPrice: json['singleSessionPrice'] as int,
      package3Sessions: json['package3Sessions'] != null
          ? PackageDeal.fromJson(
              json['package3Sessions'] as Map<String, dynamic>,
            )
          : null,
      package5Sessions: json['package5Sessions'] != null
          ? PackageDeal.fromJson(
              json['package5Sessions'] as Map<String, dynamic>,
            )
          : null,
      package10Sessions: json['package10Sessions'] != null
          ? PackageDeal.fromJson(
              json['package10Sessions'] as Map<String, dynamic>,
            )
          : null,
      hasConsultationFee: json['hasConsultationFee'] as bool? ?? false,
      consultationFeeInSG: json['consultationFeeInSG'] as int?,
    );
  }
  final int singleSessionPrice;
  final PackageDeal? package3Sessions;
  final PackageDeal? package5Sessions;
  final PackageDeal? package10Sessions;
  final bool hasConsultationFee;
  final int? consultationFeeInSG;

  /// Get best deal for given number of sessions
  PackageDeal? getBestDealFor(int sessions) {
    final deals = [package3Sessions, package5Sessions, package10Sessions]
        .where((deal) => deal != null && deal.sessions <= sessions)
        .cast<PackageDeal>()
        .toList();

    if (deals.isEmpty) return null;

    // Return the deal with best price per session
    deals.sort((a, b) => a.pricePerSession.compareTo(b.pricePerSession));
    return deals.first;
  }

  Map<String, dynamic> toJson() {
    return {
      'singleSessionPrice': singleSessionPrice,
      'package3Sessions': package3Sessions?.toJson(),
      'package5Sessions': package5Sessions?.toJson(),
      'package10Sessions': package10Sessions?.toJson(),
      'hasConsultationFee': hasConsultationFee,
      'consultationFeeInSG': consultationFeeInSG,
    };
  }

  @override
  List<Object?> get props => [
    singleSessionPrice,
    package3Sessions,
    package5Sessions,
    package10Sessions,
    hasConsultationFee,
    consultationFeeInSG,
  ];
}

/// Represents a package deal for multiple sessions
class PackageDeal extends Equatable {
  const PackageDeal({
    required this.sessions,
    required this.totalPrice,
    required this.originalPrice,
    this.description,
  });

  factory PackageDeal.fromJson(Map<String, dynamic> json) {
    return PackageDeal(
      sessions: json['sessions'] as int,
      totalPrice: json['totalPrice'] as int,
      originalPrice: json['originalPrice'] as int,
      description: json['description'] as String?,
    );
  }
  final int sessions;
  final int totalPrice;
  final int originalPrice;
  final String? description;

  /// Price per session in this package
  double get pricePerSession => totalPrice / sessions;

  /// Savings amount
  int get savings => originalPrice - totalPrice;

  /// Savings percentage
  double get savingsPercentage => (savings / originalPrice) * 100;

  /// Formatted savings display
  String get formattedSavings =>
      'Economize ${savings}SG (${savingsPercentage.toStringAsFixed(0)}%)';

  Map<String, dynamic> toJson() {
    return {
      'sessions': sessions,
      'totalPrice': totalPrice,
      'originalPrice': originalPrice,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [sessions, totalPrice, originalPrice, description];
}

/// Represents service availability schedule
class ServiceAvailability extends Equatable {
  const ServiceAvailability({
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.unavailableTimes,
  });

  factory ServiceAvailability.fromJson(Map<String, dynamic> json) {
    return ServiceAvailability(
      weekday: json['weekday'] as int,
      startTime: TimeOfDay(
        hour: json['startHour'] as int,
        minute: json['startMinute'] as int,
      ),
      endTime: TimeOfDay(
        hour: json['endHour'] as int,
        minute: json['endMinute'] as int,
      ),
      unavailableTimes: (json['unavailableTimes'] as List?)
          ?.map(
            (time) => TimeOfDay(
              hour: time['hour'] as int,
              minute: time['minute'] as int,
            ),
          )
          .toList(),
    );
  }
  final int weekday; // 1-7 (Monday to Sunday)
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<TimeOfDay>? unavailableTimes;

  /// Check if available on specific weekday
  bool isAvailableOn(int checkWeekday) => weekday == checkWeekday;

  /// Check if available at specific time on the weekday
  bool isAvailableAt(TimeOfDay time) {
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (timeMinutes < startMinutes || timeMinutes > endMinutes) return false;

    if (unavailableTimes != null) {
      for (final unavailableTime in unavailableTimes!) {
        final unavailableMinutes =
            unavailableTime.hour * 60 + unavailableTime.minute;
        if (timeMinutes == unavailableMinutes) return false;
      }
    }

    return true;
  }

  /// Get available time slots for this weekday
  List<TimeOfDay> getAvailableTimeSlots(int slotDurationMinutes) {
    final slots = <TimeOfDay>[];
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    for (
      int minutes = startMinutes;
      minutes < endMinutes;
      minutes += slotDurationMinutes
    ) {
      final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
      if (isAvailableAt(time)) {
        slots.add(time);
      }
    }

    return slots;
  }

  Map<String, dynamic> toJson() {
    return {
      'weekday': weekday,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'unavailableTimes': unavailableTimes
          ?.map((time) => {'hour': time.hour, 'minute': time.minute})
          .toList(),
    };
  }

  @override
  List<Object?> get props => [weekday, startTime, endTime, unavailableTimes];
}

/// Service categories enum for easy categorization
enum ServiceCategory {
  facialAesthetics('Estética Facial'),
  bodyAesthetics('Estética Corporal'),
  injectableTherapies('Terapias Injetáveis'),
  dermatology('Dermatologia'),
  wellness('Bem-estar'),
  diagnostics('Diagnósticos'),
  performance('Performance'),
  physiotherapy('Fisioterapia');

  const ServiceCategory(this.displayName);
  final String displayName;

  static ServiceCategory fromString(String category) {
    switch (category.toLowerCase()) {
      case 'estética facial':
      case 'estetica facial':
      case 'facial':
        return ServiceCategory.facialAesthetics;
      case 'estética corporal':
      case 'estetica corporal':
      case 'corporal':
        return ServiceCategory.bodyAesthetics;
      case 'terapias injetáveis':
      case 'terapias injetaveis':
      case 'injetável':
      case 'injetaveis':
        return ServiceCategory.injectableTherapies;
      case 'dermatologia':
        return ServiceCategory.dermatology;
      case 'bem-estar':
      case 'bem estar':
      case 'wellness':
        return ServiceCategory.wellness;
      case 'diagnósticos':
      case 'diagnosticos':
        return ServiceCategory.diagnostics;
      case 'performance':
      case 'performance e saúde':
        return ServiceCategory.performance;
      case 'fisioterapia':
        return ServiceCategory.physiotherapy;
      default:
        return ServiceCategory.wellness;
    }
  }
}
