class Clinic {
  final String id;
  final String name;
  final String address;
  final double distance; // in kilometers
  final double rating;
  final int reviewCount;
  final List<String> specializations;
  final String imageUrl;
  final List<String> images; // All images from backend
  final bool isAvailable;
  final DateTime? nextAvailableSlot;
  final ClinicType type;
  final List<String> services;
  final ContactInfo contact;
  final Location coordinates;
  final bool isPartner;
  final String? description;

  const Clinic({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.specializations,
    required this.imageUrl,
    required this.images,
    required this.isAvailable,
    this.nextAvailableSlot,
    required this.type,
    required this.services,
    required this.contact,
    required this.coordinates,
    required this.isPartner,
    this.description,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      distance: (json['distance'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      specializations: List<String>.from(json['specializations'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      isAvailable: json['isAvailable'] ?? false,
      nextAvailableSlot: json['nextAvailableSlot'] != null 
          ? DateTime.parse(json['nextAvailableSlot'])
          : null,
      type: ClinicType.fromString(json['type'] ?? 'partner'),
      services: List<String>.from(json['services'] ?? []),
      contact: ContactInfo.fromJson(json['contact'] ?? {}),
      coordinates: Location.fromJson(json['coordinates'] ?? {}),
      isPartner: json['isPartner'] ?? false,
      description: json['description'],
    );
  }

  /// Factory method to create from backend API response
  factory Clinic.fromBackendDto(Map<String, dynamic> dto) {
    // Extract all image URLs from backend
    List<String> allImages = [];
    String mainImageUrl = '';
    
    if (dto['images'] != null && dto['images'] is List && (dto['images'] as List).isNotEmpty) {
      var imagesList = dto['images'] as List;
      
      // Extract all image URLs
      for (var imageItem in imagesList) {
        if (imageItem is Map<String, dynamic> && imageItem['imageUrl'] != null) {
          allImages.add(imageItem['imageUrl']);
        }
      }
      
      // Set main image as the first one
      if (allImages.isNotEmpty) {
        mainImageUrl = allImages.first;
      }
    } else if (dto['imageUrl'] != null) {
      mainImageUrl = dto['imageUrl'];
      allImages = [mainImageUrl];
    }

    // Parse clinic type from enum int value
    ClinicType clinicType = ClinicType.partner;
    if (dto['type'] is int) {
      clinicType = ClinicType.fromInt(dto['type']);
    } else if (dto['type'] is String) {
      clinicType = ClinicType.fromString(dto['type']);
    }

    // Parse services and extract categories from backend
    List<String> clinicServices = [];
    Set<String> serviceCategories = {};

    if (dto['services'] != null && dto['services'] is List) {
      for (var service in dto['services'] as List) {
        if (service is Map<String, dynamic>) {
          // Extract service name
          if (service['name'] != null) {
            clinicServices.add(service['name']);
          }

          // Extract service category for quick filters
          if (service['category'] != null) {
            serviceCategories.add(service['category']);
          }
        }
      }
    }

    // Create contact info from backend fields
    ContactInfo contact = ContactInfo(
      phone: dto['phoneNumber'] ?? '',
      email: dto['email'] ?? '',
      whatsapp: dto['phoneNumber'], // Use phone as whatsapp fallback
      website: null,
    );

    // Create coordinates from backend latitude/longitude
    Location coordinates = Location(
      latitude: (dto['latitude'] ?? 0).toDouble(),
      longitude: (dto['longitude'] ?? 0).toDouble(),
    );

    return Clinic(
      id: dto['id'] ?? '',
      name: dto['name'] ?? '',
      address: dto['address'] ?? '',
      distance: 0.0, // Will be calculated later based on user location
      rating: 4.5, // Default rating - TODO: implement real ratings
      reviewCount: 0, // Default review count - TODO: implement real reviews
      specializations: serviceCategories.toList(), // Use service categories as specializations
      imageUrl: mainImageUrl,
      images: allImages,
      isAvailable: dto['isActive'] ?? false,
      nextAvailableSlot: DateTime.now().add(const Duration(hours: 2)), // Default next slot
      type: clinicType,
      services: clinicServices.isNotEmpty ? clinicServices : ['Consulta', 'Exames'], // Use real services from backend
      contact: contact,
      coordinates: coordinates,
      isPartner: clinicType == ClinicType.partner,
      description: null, // TODO: add description field to backend
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'distance': distance,
      'rating': rating,
      'reviewCount': reviewCount,
      'specializations': specializations,
      'imageUrl': imageUrl,
      'images': images,
      'isAvailable': isAvailable,
      'nextAvailableSlot': nextAvailableSlot?.toIso8601String(),
      'type': type.toString(),
      'services': services,
      'contact': contact.toJson(),
      'coordinates': coordinates.toJson(),
      'isPartner': isPartner,
      'description': description,
    };
  }
}

enum ClinicType {
  origin,
  partner,
  regular,
  administrative;

  static ClinicType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'origin':
        return ClinicType.origin;
      case 'partner':
        return ClinicType.partner;
      case 'regular':
        return ClinicType.regular;
      case 'administrative':
        return ClinicType.administrative;
      default:
        return ClinicType.partner;
    }
  }

  static ClinicType fromInt(int value) {
    switch (value) {
      case 0:
        return ClinicType.regular;
      case 1:
        return ClinicType.origin;
      case 2:
        return ClinicType.partner;
      case 3:
        return ClinicType.administrative;
      default:
        return ClinicType.partner;
    }
  }

  @override
  String toString() {
    switch (this) {
      case ClinicType.origin:
        return 'origin';
      case ClinicType.partner:
        return 'partner';
      case ClinicType.regular:
        return 'regular';
      case ClinicType.administrative:
        return 'administrative';
    }
  }
}

class ContactInfo {
  final String phone;
  final String email;
  final String? whatsapp;
  final String? website;

  const ContactInfo({
    required this.phone,
    required this.email,
    this.whatsapp,
    this.website,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      whatsapp: json['whatsapp'],
      website: json['website'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
      'whatsapp': whatsapp,
      'website': website,
    };
  }
}

class Location {
  final double latitude;
  final double longitude;

  const Location({
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class AppointmentSlot {
  final String id;
  final DateTime dateTime;
  final String doctorName;
  final String specialization;
  final Duration duration;
  final bool isAvailable;
  final double price;
  final String? notes;

  const AppointmentSlot({
    required this.id,
    required this.dateTime,
    required this.doctorName,
    required this.specialization,
    required this.duration,
    required this.isAvailable,
    required this.price,
    this.notes,
  });

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    return AppointmentSlot(
      id: json['id'] ?? '',
      dateTime: DateTime.parse(json['dateTime']),
      doctorName: json['doctorName'] ?? '',
      specialization: json['specialization'] ?? '',
      duration: Duration(minutes: json['duration'] ?? 30),
      isAvailable: json['isAvailable'] ?? false,
      price: (json['price'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'doctorName': doctorName,
      'specialization': specialization,
      'duration': duration.inMinutes,
      'isAvailable': isAvailable,
      'price': price,
      'notes': notes,
    };
  }
}