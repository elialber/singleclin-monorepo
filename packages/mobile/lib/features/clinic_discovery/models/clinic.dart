class Clinic {
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
    required this.type, required this.services, required this.contact, required this.coordinates, required this.isPartner, this.nextAvailableSlot,
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
      services: List<Map<String, dynamic>>.from(
        (json['services'] ?? []).map(
          (service) => service is Map<String, dynamic>
              ? service
              : {'name': service.toString(), 'price': 1.0},
        ),
      ),
      contact: ContactInfo.fromJson(json['contact'] ?? {}),
      coordinates: Location.fromJson(json['coordinates'] ?? {}),
      isPartner: json['isPartner'] ?? false,
      description: json['description'],
    );
  }

  /// Factory method to create from backend API response
  factory Clinic.fromBackendDto(Map<String, dynamic> dto) {
    print('🏥 Converting backend DTO for clinic: ${dto['name']}');
    print('📄 Full DTO: $dto');

    // Extract all image URLs from backend - using featuredImage from real API
    List<String> allImages = [];
    String mainImageUrl = '';

    print('🔍 Checking for images in DTO...');

    // First check for featuredImage from real API response
    if (dto['featuredImage'] != null &&
        dto['featuredImage'] is Map<String, dynamic>) {
      final featuredImage = dto['featuredImage'] as Map<String, dynamic>;
      if (featuredImage['imageUrl'] != null &&
          featuredImage['imageUrl'].toString().isNotEmpty) {
        mainImageUrl = featuredImage['imageUrl'];
        allImages.add(mainImageUrl);
        print('✅ Found featuredImage URL: $mainImageUrl');
      }
    }

    // Also check for additional images array
    if (dto['images'] != null &&
        dto['images'] is List &&
        (dto['images'] as List).isNotEmpty) {
      final imagesList = dto['images'] as List;
      print('📸 Found additional images list with ${imagesList.length} items');

      // Extract all image URLs from ClinicImageDto objects
      for (final imageItem in imagesList) {
        if (imageItem is Map<String, dynamic> &&
            imageItem['imageUrl'] != null) {
          final String imageUrl = imageItem['imageUrl'];
          if (!allImages.contains(imageUrl)) {
            print('🖼️ Adding additional image URL: $imageUrl');
            allImages.add(imageUrl);
          }
        }
      }
    }

    // Fallback to legacy imageUrl field if no featuredImage found
    if (mainImageUrl.isEmpty && dto['imageUrl'] != null) {
      mainImageUrl = dto['imageUrl'];
      allImages = [mainImageUrl];
      print('📷 Using fallback imageUrl: $mainImageUrl');
    }

    if (mainImageUrl.isEmpty) {
      print('⚠️ No images found in DTO');
    }

    // Parse clinic type from enum int value
    ClinicType clinicType = ClinicType.partner;
    if (dto['type'] is int) {
      clinicType = ClinicType.fromInt(dto['type']);
    } else if (dto['type'] is String) {
      clinicType = ClinicType.fromString(dto['type']);
    }

    // Parse services and extract categories from backend
    List<Map<String, dynamic>> clinicServices = [];
    final Set<String> serviceCategories = {};

    print('🛠️ Processing services for clinic: ${dto['name']}');
    if (dto['services'] != null && dto['services'] is List) {
      final servicesList = dto['services'] as List;
      print('📋 Found ${servicesList.length} services');

      for (final service in servicesList) {
        if (service is Map<String, dynamic>) {
          // Map service data from API format (capitalCase) to mobile format (camelCase)
          final mappedService = {
            'id': service['id'] ?? service['Id'],
            'name': service['name'] ?? service['Name'] ?? 'Unknown Service',
            'price': (service['price'] ?? service['Price'] ?? 0).toDouble(),
            'category': service['category'] ?? service['Category'] ?? 'Geral',
            'description': service['description'] ?? service['Description'],
          };

          print(
            '🔧 Processing service: ${mappedService['name']} - category: ${mappedService['category']}',
          );
          clinicServices.add(mappedService);

          // Extract service category for quick filters
          final String category = mappedService['category'] as String;
          if (category.isNotEmpty) {
            serviceCategories.add(category);
            print('🏷️ Added category: $category');
          }
        }
      }
    } else {
      print('⚠️ No services found in DTO');
    }

    print('🎯 Final categories for ${dto['name']}: $serviceCategories');

    // Create contact info from backend fields
    final ContactInfo contact = ContactInfo(
      phone: dto['phoneNumber'] ?? '',
      email: dto['email'] ?? '',
      whatsapp: dto['phoneNumber'], // Use phone as whatsapp fallback
    );

    // Create coordinates from backend latitude/longitude
    final Location coordinates = Location(
      latitude: (dto['latitude'] ?? 0).toDouble(),
      longitude: (dto['longitude'] ?? 0).toDouble(),
    );

    // Use real data from API, only add fallback if completely missing
    final bool needsFallback = allImages.isEmpty && clinicServices.isEmpty;

    print(
      '🧪 Using real API data for ${dto['name']}. Needs fallback: $needsFallback',
    );

    if (needsFallback) {
      print('⚠️ No real data available, using fallback');
      // Only use fallback data if API completely fails to provide data
      if (allImages.isEmpty) {
        allImages = [
          'https://images.unsplash.com/photo-1551076805-e1869033e561?w=800',
        ];
        mainImageUrl = allImages.first;
      }

      if (clinicServices.isEmpty) {
        clinicServices = [
          {'name': 'Consulta', 'price': 1.0, 'category': 'Geral'},
        ];
        serviceCategories.add('Geral');
      }
    }

    return Clinic(
      id: dto['id'] ?? '',
      name: dto['name'] ?? '',
      address: dto['address'] ?? '',
      distance: 0.0, // Will be calculated later based on user location
      rating: 4.5, // Default rating - TODO: implement real ratings
      reviewCount: 23, // Default review count - TODO: implement real reviews
      specializations: serviceCategories
          .toList(), // Use service categories as specializations
      imageUrl: mainImageUrl,
      images: allImages,
      isAvailable: dto['isActive'] ?? false,
      nextAvailableSlot: DateTime.now().add(
        const Duration(hours: 2),
      ), // Default next slot
      type: clinicType,
      services: clinicServices, // Use real services from backend
      contact: contact,
      coordinates: coordinates,
      isPartner: clinicType == ClinicType.partner,
    );
  }
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
  final List<Map<String, dynamic>> services;
  final ContactInfo contact;
  final Location coordinates;
  final bool isPartner;
  final String? description;

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
  final String phone;
  final String email;
  final String? whatsapp;
  final String? website;

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
  const Location({required this.latitude, required this.longitude});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }
  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}

class AppointmentSlot {
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
  final String id;
  final DateTime dateTime;
  final String doctorName;
  final String specialization;
  final Duration duration;
  final bool isAvailable;
  final double price;
  final String? notes;

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
