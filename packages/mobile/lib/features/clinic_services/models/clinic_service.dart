class ClinicService {
  ClinicService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.category,
    required this.isAvailable,
    this.imageUrl,
  });

  factory ClinicService.fromJson(Map<String, dynamic> json) {
    return ClinicService(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      category: json['category'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      imageUrl: json['imageUrl'],
    );
  }
  final String id;
  final String name;
  final String description;
  final double price;
  final int duration; // Duration in minutes
  final String category;
  final bool isAvailable;
  final String? imageUrl;

  /// Factory method to create services from clinic data
  static List<ClinicService> fromClinicServices(List<dynamic>? servicesJson) {
    if (servicesJson == null || servicesJson.isEmpty) {
      return [];
    }

    return servicesJson
        .whereType<Map<String, dynamic>>()
        .map(ClinicService.fromJson)
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'category': category,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
    };
  }

  String get formattedPrice {
    // Format price as SG (SingleClin Gold) instead of R$ (Reais)
    if (price == 1.0) {
      return '1 SG';
    } else if (price == price.toInt()) {
      return '${price.toInt()} SG';
    } else {
      return '${price.toStringAsFixed(1)} SG';
    }
  }

  String get formattedDuration {
    if (duration < 60) {
      return '${duration}min';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}min';
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClinicService && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ClinicService(id: $id, name: $name, price: $price)';
  }
}
