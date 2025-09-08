import 'package:equatable/equatable.dart';

/// Cancellation Policy Model
/// Defines cancellation rules and refund calculations for appointments
class CancellationPolicy extends Equatable {
  final String id;
  final String serviceId;
  final String serviceName;
  final String categoryId;
  final List<CancellationRule> rules;
  final String description;
  final bool allowsEmergencyException;
  final List<String> emergencyExceptions;
  final bool allowsRescheduling;
  final int maxReschedulingCount;
  final bool requiresJustification;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CancellationPolicy({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.categoryId,
    required this.rules,
    required this.description,
    this.allowsEmergencyException = true,
    this.emergencyExceptions = const [],
    this.allowsRescheduling = true,
    this.maxReschedulingCount = 3,
    this.requiresJustification = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory method to create from JSON
  factory CancellationPolicy.fromJson(Map<String, dynamic> json) {
    return CancellationPolicy(
      id: json['id'] as String,
      serviceId: json['serviceId'] as String,
      serviceName: json['serviceName'] as String,
      categoryId: json['categoryId'] as String,
      rules: (json['rules'] as List)
          .map((rule) => CancellationRule.fromJson(rule as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String,
      allowsEmergencyException: json['allowsEmergencyException'] as bool? ?? true,
      emergencyExceptions: List<String>.from(json['emergencyExceptions'] as List? ?? []),
      allowsRescheduling: json['allowsRescheduling'] as bool? ?? true,
      maxReschedulingCount: json['maxReschedulingCount'] as int? ?? 3,
      requiresJustification: json['requiresJustification'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'categoryId': categoryId,
      'rules': rules.map((rule) => rule.toJson()).toList(),
      'description': description,
      'allowsEmergencyException': allowsEmergencyException,
      'emergencyExceptions': emergencyExceptions,
      'allowsRescheduling': allowsRescheduling,
      'maxReschedulingCount': maxReschedulingCount,
      'requiresJustification': requiresJustification,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Calculate refund amount based on cancellation time
  CancellationCalculation calculateRefund({
    required DateTime appointmentDate,
    required DateTime cancellationDate,
    required double appointmentPrice,
    required double sgCreditsUsed,
    bool isEmergency = false,
  }) {
    final hoursUntilAppointment = appointmentDate.difference(cancellationDate).inHours;
    
    // Emergency exception - full refund
    if (isEmergency && allowsEmergencyException) {
      return CancellationCalculation(
        refundPercentage: 100,
        refundAmount: sgCreditsUsed,
        penalty: 0,
        reason: 'Cancelamento por emergência médica',
        hoursUntilAppointment: hoursUntilAppointment,
        canCancel: true,
      );
    }

    // Find applicable rule
    CancellationRule? applicableRule;
    for (final rule in rules) {
      if (hoursUntilAppointment >= rule.minHoursBeforeAppointment) {
        applicableRule = rule;
        break;
      }
    }

    if (applicableRule == null) {
      return CancellationCalculation(
        refundPercentage: 0,
        refundAmount: 0,
        penalty: sgCreditsUsed,
        reason: 'Cancelamento fora do prazo permitido',
        hoursUntilAppointment: hoursUntilAppointment,
        canCancel: false,
      );
    }

    final refundAmount = sgCreditsUsed * (applicableRule.refundPercentage / 100);
    final penalty = sgCreditsUsed - refundAmount;

    return CancellationCalculation(
      refundPercentage: applicableRule.refundPercentage,
      refundAmount: refundAmount,
      penalty: penalty,
      reason: applicableRule.description,
      hoursUntilAppointment: hoursUntilAppointment,
      canCancel: true,
    );
  }

  /// Get default cancellation policy
  static CancellationPolicy getDefault() {
    return CancellationPolicy(
      id: 'default',
      serviceId: 'all',
      serviceName: 'Todos os serviços',
      categoryId: 'all',
      rules: [
        CancellationRule(
          minHoursBeforeAppointment: 48,
          refundPercentage: 100,
          description: 'Cancelamento com 48h de antecedência - Reembolso total',
        ),
        CancellationRule(
          minHoursBeforeAppointment: 24,
          refundPercentage: 80,
          description: 'Cancelamento com 24h de antecedência - 80% de reembolso',
        ),
        CancellationRule(
          minHoursBeforeAppointment: 12,
          refundPercentage: 50,
          description: 'Cancelamento com 12h de antecedência - 50% de reembolso',
        ),
        CancellationRule(
          minHoursBeforeAppointment: 0,
          refundPercentage: 0,
          description: 'Cancelamento com menos de 12h - Sem reembolso',
        ),
      ],
      description: 'Política padrão de cancelamento para procedimentos estéticos',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        serviceId,
        categoryId,
        rules,
        allowsEmergencyException,
        allowsRescheduling,
      ];
}

/// Cancellation Rule
/// Individual rule within a cancellation policy
class CancellationRule extends Equatable {
  final int minHoursBeforeAppointment;
  final int refundPercentage;
  final String description;

  const CancellationRule({
    required this.minHoursBeforeAppointment,
    required this.refundPercentage,
    required this.description,
  });

  factory CancellationRule.fromJson(Map<String, dynamic> json) {
    return CancellationRule(
      minHoursBeforeAppointment: json['minHoursBeforeAppointment'] as int,
      refundPercentage: json['refundPercentage'] as int,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minHoursBeforeAppointment': minHoursBeforeAppointment,
      'refundPercentage': refundPercentage,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [minHoursBeforeAppointment, refundPercentage];
}

/// Cancellation Calculation Result
/// Result of refund calculation for appointment cancellation
class CancellationCalculation extends Equatable {
  final int refundPercentage;
  final double refundAmount;
  final double penalty;
  final String reason;
  final int hoursUntilAppointment;
  final bool canCancel;

  const CancellationCalculation({
    required this.refundPercentage,
    required this.refundAmount,
    required this.penalty,
    required this.reason,
    required this.hoursUntilAppointment,
    required this.canCancel,
  });

  /// Get user-friendly time description
  String get timeDescription {
    if (hoursUntilAppointment < 1) {
      return 'menos de 1 hora';
    } else if (hoursUntilAppointment < 24) {
      return '$hoursUntilAppointment horas';
    } else {
      final days = (hoursUntilAppointment / 24).floor();
      return '$days dias';
    }
  }

  /// Get color for refund percentage
  String get refundColor {
    if (refundPercentage >= 100) return '#4CAF50'; // Green
    if (refundPercentage >= 80) return '#8BC34A'; // Light Green
    if (refundPercentage >= 50) return '#FFC107'; // Yellow
    if (refundPercentage > 0) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }

  /// Check if refund is favorable
  bool get isFavorableRefund => refundPercentage >= 80;

  /// Get formatted refund message
  String get formattedMessage {
    if (!canCancel) {
      return 'Cancelamento não permitido. $reason.';
    }
    
    if (refundPercentage == 100) {
      return 'Reembolso total de ${refundAmount.toStringAsFixed(0)} SG créditos.';
    }
    
    if (refundPercentage > 0) {
      return 'Reembolso de $refundPercentage% (${refundAmount.toStringAsFixed(0)} SG créditos). Taxa de cancelamento: ${penalty.toStringAsFixed(0)} SG créditos.';
    }
    
    return 'Sem reembolso. Taxa de cancelamento: ${penalty.toStringAsFixed(0)} SG créditos.';
  }

  @override
  List<Object?> get props => [
        refundPercentage,
        refundAmount,
        penalty,
        hoursUntilAppointment,
        canCancel,
      ];
}

/// Emergency Exception Types
enum EmergencyExceptionType {
  medicalEmergency('medical_emergency', 'Emergência médica'),
  forceeMajeure('force_majeure', 'Força maior'),
  familyEmergency('family_emergency', 'Emergência familiar'),
  naturalDisaster('natural_disaster', 'Desastre natural'),
  governmentOrder('government_order', 'Ordem governamental');

  const EmergencyExceptionType(this.value, this.label);

  final String value;
  final String label;

  static EmergencyExceptionType fromString(String value) {
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => medicalEmergency,
    );
  }
}