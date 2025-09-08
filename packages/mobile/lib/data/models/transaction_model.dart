import 'package:singleclin_mobile/domain/entities/transaction_entity.dart';

/// Transaction model for data layer with JSON serialization
class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.userId,
    required super.clinicId,
    required super.clinicName,
    required super.serviceType,
    required super.creditsUsed,
    required super.value,
    required super.status,
    required super.transactionDate,
    required super.createdAt,
    required super.updatedAt,
    super.notes,
  });

  /// Create TransactionModel from entity
  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      userId: entity.userId,
      clinicId: entity.clinicId,
      clinicName: entity.clinicName,
      serviceType: entity.serviceType,
      creditsUsed: entity.creditsUsed,
      value: entity.value,
      status: entity.status,
      notes: entity.notes,
      transactionDate: entity.transactionDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create TransactionModel from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? json['userId'] as int,
      clinicId: json['clinic_id'] as int? ?? json['clinicId'] as int,
      clinicName:
          json['clinic_name'] as String? ?? json['clinicName'] as String,
      serviceType:
          json['service_type'] as String? ?? json['serviceType'] as String,
      creditsUsed: json['credits_used'] as int? ?? json['creditsUsed'] as int,
      value: (json['value'] as num).toDouble(),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      transactionDate: DateTime.parse(
        json['transaction_date'] as String? ??
            json['transactionDate'] as String,
      ),
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? json['createdAt'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? json['updatedAt'] as String,
      ),
    );
  }

  /// Convert TransactionModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'clinic_id': clinicId,
      'clinic_name': clinicName,
      'service_type': serviceType,
      'credits_used': creditsUsed,
      'value': value,
      'status': status,
      'notes': notes,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to entity
  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      userId: userId,
      clinicId: clinicId,
      clinicName: clinicName,
      serviceType: serviceType,
      creditsUsed: creditsUsed,
      value: value,
      status: status,
      notes: notes,
      transactionDate: transactionDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Copy with new values
  TransactionModel copyWith({
    int? id,
    int? userId,
    int? clinicId,
    String? clinicName,
    String? serviceType,
    int? creditsUsed,
    double? value,
    String? status,
    String? notes,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clinicId: clinicId ?? this.clinicId,
      clinicName: clinicName ?? this.clinicName,
      serviceType: serviceType ?? this.serviceType,
      creditsUsed: creditsUsed ?? this.creditsUsed,
      value: value ?? this.value,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
