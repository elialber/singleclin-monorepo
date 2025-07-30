import '../../domain/entities/plan_entity.dart';

/// Plan model for data layer with JSON serialization
class PlanModel extends PlanEntity {
  const PlanModel({
    required super.id,
    required super.name,
    required super.description,
    required super.totalCredits,
    required super.price,
    required super.validityDays,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create PlanModel from JSON
  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      totalCredits: json['total_credits'] as int? ?? json['totalCredits'] as int,
      price: (json['price'] as num).toDouble(),
      validityDays: json['validity_days'] as int? ?? json['validityDays'] as int,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['updatedAt'] as String),
    );
  }

  /// Convert PlanModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'total_credits': totalCredits,
      'price': price,
      'validity_days': validityDays,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to entity
  PlanEntity toEntity() {
    return PlanEntity(
      id: id,
      name: name,
      description: description,
      totalCredits: totalCredits,
      price: price,
      validityDays: validityDays,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create PlanModel from entity
  factory PlanModel.fromEntity(PlanEntity entity) {
    return PlanModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      totalCredits: entity.totalCredits,
      price: entity.price,
      validityDays: entity.validityDays,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Copy with new values
  PlanModel copyWith({
    int? id,
    String? name,
    String? description,
    int? totalCredits,
    double? price,
    int? validityDays,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalCredits: totalCredits ?? this.totalCredits,
      price: price ?? this.price,
      validityDays: validityDays ?? this.validityDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}