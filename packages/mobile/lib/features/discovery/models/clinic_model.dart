class ClinicModel {
  ClinicModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.email,
    this.website,
    required this.imageUrls,
    required this.rating,
    required this.reviewCount,
    required this.services,
    required this.specialties,
    required this.schedule,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClinicModel.fromJson(Map<String, dynamic> json) {
    return ClinicModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      phone: json['phone'] ?? '',
      email: json['email'],
      website: json['website'],
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : [],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      services: json['services'] != null
          ? List<ServiceModel>.from(
              json['services'].map((x) => ServiceModel.fromJson(x)),
            )
          : [],
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'])
          : [],
      schedule: ClinicSchedule.fromJson(json['schedule'] ?? {}),
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
  final String id;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String? email;
  final String? website;
  final List<String> imageUrls;
  final double rating;
  final int reviewCount;
  final List<ServiceModel> services;
  final List<String> specialties;
  final ClinicSchedule schedule;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'website': website,
      'imageUrls': imageUrls,
      'rating': rating,
      'reviewCount': reviewCount,
      'services': services.map((x) => x.toJson()).toList(),
      'specialties': specialties,
      'schedule': schedule.toJson(),
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  double distanceFrom(double userLat, double userLng) {
    // Implementar cálculo de distância usando fórmula de Haversine
    const double earthRadius = 6371; // km

    final double dLat = _toRadians(latitude - userLat);
    final double dLng = _toRadians(longitude - userLng);

    final double a =
        (dLat / 2) * (dLat / 2) +
        (dLng / 2) * (dLng / 2) * (latitude.toDouble() * userLat.toDouble());

    final double c = 2 * (a.squareRoot().asin());

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.14159265359 / 180);
  }
}

class ServiceModel {
  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.sgCost,
    required this.durationMinutes,
    required this.category,
    required this.imageUrls,
    required this.isActive,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      sgCost: json['sgCost'] ?? 0,
      durationMinutes: json['durationMinutes'] ?? 60,
      category: json['category'] ?? '',
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : [],
      isActive: json['isActive'] ?? true,
    );
  }
  final String id;
  final String name;
  final String description;
  final int sgCost;
  final int durationMinutes;
  final String category;
  final List<String> imageUrls;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sgCost': sgCost,
      'durationMinutes': durationMinutes,
      'category': category,
      'imageUrls': imageUrls,
      'isActive': isActive,
    };
  }
}

class ClinicSchedule {
  ClinicSchedule({required this.weekdays});

  factory ClinicSchedule.fromJson(Map<String, dynamic> json) {
    Map<String, DaySchedule> schedules = {};
    json.forEach((key, value) {
      if (value != null) {
        schedules[key] = DaySchedule.fromJson(value);
      }
    });
    return ClinicSchedule(weekdays: schedules);
  }
  final Map<String, DaySchedule> weekdays;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    weekdays.forEach((key, value) {
      json[key] = value.toJson();
    });
    return json;
  }

  bool isOpenAt(DateTime dateTime) {
    final String weekday = _getWeekdayString(dateTime.weekday);
    final DaySchedule? daySchedule = weekdays[weekday];

    if (daySchedule == null || !daySchedule.isOpen) {
      return false;
    }

    final String currentTime =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return currentTime.compareTo(daySchedule.openTime) >= 0 &&
        currentTime.compareTo(daySchedule.closeTime) < 0;
  }

  String _getWeekdayString(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }
}

class DaySchedule {
  DaySchedule({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
    this.breakStart,
    this.breakEnd,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      isOpen: json['isOpen'] ?? false,
      openTime: json['openTime'] ?? '09:00',
      closeTime: json['closeTime'] ?? '18:00',
      breakStart: json['breakStart'],
      breakEnd: json['breakEnd'],
    );
  }
  final bool isOpen;
  final String openTime;
  final String closeTime;
  final String? breakStart;
  final String? breakEnd;

  Map<String, dynamic> toJson() {
    return {
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
      'breakStart': breakStart,
      'breakEnd': breakEnd,
    };
  }
}
