import '../../domain/entities/user_plan_entity.dart';
import '../../domain/entities/plan_entity.dart';
import 'plan_model.dart';

/// User plan model for data layer with JSON serialization
class UserPlanModel extends UserPlanEntity {
  const UserPlanModel({
    required super.id,
    required super.userId,
    required super.planId,
    required super.plan,
    required super.usedCredits,
    required super.remainingCredits,
    required super.startDate,
    required super.expirationDate,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create UserPlanModel from JSON
  factory UserPlanModel.fromJson(Map<String, dynamic> json) {
    return UserPlanModel(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int,
      planId: json['plan_id'] as int? ?? json['planId'] as int,
      plan: PlanModel.fromJson(json['plan'] as Map<String, dynamic>),
      usedCredits: json['used_credits'] as int? ?? json['usedCredits'] as int,
      remainingCredits: json['remaining_credits'] as int? ?? json['remainingCredits'] as int,
      startDate: DateTime.parse(json['start_date'] as String? ?? json['startDate'] as String),
      expirationDate: DateTime.parse(json['expiration_date'] as String? ?? json['expirationDate'] as String),
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['updatedAt'] as String),
    );
  }

  /// Convert UserPlanModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'plan': (plan as PlanModel).toJson(),
      'used_credits': usedCredits,
      'remaining_credits': remainingCredits,
      'start_date': startDate.toIso8601String(),
      'expiration_date': expirationDate.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to entity
  UserPlanEntity toEntity() {
    return UserPlanEntity(
      id: id,
      userId: userId,
      planId: planId,
      plan: plan,
      usedCredits: usedCredits,
      remainingCredits: remainingCredits,
      startDate: startDate,
      expirationDate: expirationDate,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create UserPlanModel from entity
  factory UserPlanModel.fromEntity(UserPlanEntity entity) {
    return UserPlanModel(
      id: entity.id,
      userId: entity.userId,
      planId: entity.planId,
      plan: entity.plan,
      usedCredits: entity.usedCredits,
      remainingCredits: entity.remainingCredits,
      startDate: entity.startDate,
      expirationDate: entity.expirationDate,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Copy with new values
  UserPlanModel copyWith({
    int? id,
    int? userId,
    int? planId,
    PlanEntity? plan,
    int? usedCredits,
    int? remainingCredits,
    DateTime? startDate,
    DateTime? expirationDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      plan: plan ?? this.plan,
      usedCredits: usedCredits ?? this.usedCredits,
      remainingCredits: remainingCredits ?? this.remainingCredits,
      startDate: startDate ?? this.startDate,
      expirationDate: expirationDate ?? this.expirationDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}