import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Service category model for the SingleClin dashboard
class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String imageAsset;
  final int serviceCount;
  final double averageRating;
  final bool isPopular;
  final bool isNew;
  final List<String> popularServices;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.imageAsset,
    this.serviceCount = 0,
    this.averageRating = 0.0,
    this.isPopular = false,
    this.isNew = false,
    this.popularServices = const [],
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: _getIconFromString(json['icon'] ?? 'default'),
      color: _getColorFromString(json['color'] ?? 'default'),
      imageAsset: json['imageAsset'] ?? '',
      serviceCount: json['serviceCount'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      isPopular: json['isPopular'] ?? false,
      isNew: json['isNew'] ?? false,
      popularServices: json['popularServices'] != null
          ? List<String>.from(json['popularServices'])
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': _getStringFromIcon(icon),
      'color': _getStringFromColor(color),
      'imageAsset': imageAsset,
      'serviceCount': serviceCount,
      'averageRating': averageRating,
      'isPopular': isPopular,
      'isNew': isNew,
      'popularServices': popularServices,
    };
  }

  ServiceCategory copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    String? imageAsset,
    int? serviceCount,
    double? averageRating,
    bool? isPopular,
    bool? isNew,
    List<String>? popularServices,
  }) {
    return ServiceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      imageAsset: imageAsset ?? this.imageAsset,
      serviceCount: serviceCount ?? this.serviceCount,
      averageRating: averageRating ?? this.averageRating,
      isPopular: isPopular ?? this.isPopular,
      isNew: isNew ?? this.isNew,
      popularServices: popularServices ?? this.popularServices,
    );
  }

  /// Get display badges for category
  List<String> get badges {
    final badges = <String>[];
    if (isNew) badges.add('Novo');
    if (isPopular) badges.add('Popular');
    if (averageRating >= 4.5) badges.add('Top Rated');
    return badges;
  }

  /// Get formatted rating string
  String get formattedRating {
    if (averageRating == 0.0) return 'Sem avaliações';
    return '${averageRating.toStringAsFixed(1)} ⭐';
  }

  /// Get formatted service count
  String get formattedServiceCount {
    if (serviceCount == 0) return 'Nenhum serviço';
    if (serviceCount == 1) return '1 serviço';
    return '$serviceCount serviços';
  }

  // Helper methods for icon mapping
  static IconData _getIconFromString(String iconString) {
    switch (iconString.toLowerCase()) {
      case 'face':
      case 'aesthetic':
        return Icons.face;
      case 'medical_services':
      case 'injectable':
        return Icons.medical_services;
      case 'science':
      case 'diagnostic':
        return Icons.science;
      case 'fitness_center':
      case 'performance':
        return Icons.fitness_center;
      case 'spa':
        return Icons.spa;
      case 'healing':
        return Icons.healing;
      default:
        return Icons.category;
    }
  }

  static String _getStringFromIcon(IconData icon) {
    if (icon == Icons.face) return 'face';
    if (icon == Icons.medical_services) return 'medical_services';
    if (icon == Icons.science) return 'science';
    if (icon == Icons.fitness_center) return 'fitness_center';
    if (icon == Icons.spa) return 'spa';
    if (icon == Icons.healing) return 'healing';
    return 'category';
  }

  static Color _getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'aesthetic':
        return AppColors.categoryAesthetic;
      case 'injectable':
        return AppColors.categoryInjectable;
      case 'diagnostic':
        return AppColors.categoryDiagnostic;
      case 'performance':
        return AppColors.categoryPerformance;
      default:
        return AppColors.categoryGeneral;
    }
  }

  static String _getStringFromColor(Color color) {
    if (color == AppColors.categoryAesthetic) return 'aesthetic';
    if (color == AppColors.categoryInjectable) return 'injectable';
    if (color == AppColors.categoryDiagnostic) return 'diagnostic';
    if (color == AppColors.categoryPerformance) return 'performance';
    return 'general';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceCategory &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.icon == icon &&
        other.color == color;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, description, icon, color);
  }

  @override
  String toString() {
    return 'ServiceCategory(id: $id, name: $name, serviceCount: $serviceCount)';
  }

  /// Default categories for SingleClin
  static List<ServiceCategory> get defaultCategories => [
    const ServiceCategory(
      id: 'aesthetic',
      name: 'Estética Facial',
      description: 'Tratamentos faciais e rejuvenescimento',
      icon: Icons.face,
      color: AppColors.categoryAesthetic,
      imageAsset: 'assets/images/categories/aesthetic.png',
      isPopular: true,
      popularServices: [
        'Botox',
        'Preenchimento Facial',
        'Limpeza de Pele',
        'Peeling Químico',
      ],
    ),
    const ServiceCategory(
      id: 'injectable',
      name: 'Terapias Injetáveis',
      description: 'Aplicações e procedimentos injetáveis',
      icon: Icons.medical_services,
      color: AppColors.categoryInjectable,
      imageAsset: 'assets/images/categories/injectable.png',
      isPopular: true,
      popularServices: [
        'Aplicação de Toxina Botulínica',
        'Preenchimento com Ácido Hialurônico',
        'Bioestimuladores',
        'Mesoterapia',
      ],
    ),
    const ServiceCategory(
      id: 'diagnostic',
      name: 'Diagnósticos',
      description: 'Exames e avaliações especializadas',
      icon: Icons.science,
      color: AppColors.categoryDiagnostic,
      imageAsset: 'assets/images/categories/diagnostic.png',
      popularServices: [
        'Avaliação Facial',
        'Análise de Pele',
        'Ultrassom Estético',
        'Bioimpedância',
      ],
    ),
    const ServiceCategory(
      id: 'performance',
      name: 'Performance & Saúde',
      description: 'Otimização da performance e bem-estar',
      icon: Icons.fitness_center,
      color: AppColors.categoryPerformance,
      imageAsset: 'assets/images/categories/performance.png',
      isNew: true,
      popularServices: [
        'Terapia Hormonal',
        'Suplementação',
        'Check-up Preventivo',
        'Coaching Nutricional',
      ],
    ),
  ];
}