import 'package:singleclin_mobile/features/appointments/models/appointment_status.dart';

/// Appointment model for transaction/credit history
class AppointmentModel {
  final String id;
  final String userId;
  final String serviceName;
  final String? clinicName;
  final DateTime scheduledDate;
  final AppointmentStatus status;
  final int totalCredits;
  final String? confirmationToken;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.serviceName,
    this.clinicName,
    required this.scheduledDate,
    required this.status,
    required this.totalCredits,
    this.confirmationToken,
    required this.createdAt,
    this.completedAt,
    this.cancelledAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      serviceName: _extractServiceName(json),
      clinicName: _extractClinicName(json),
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      status: _parseStatus(json['status']),
      totalCredits: json['totalCredits'] as int? ?? 0,
      confirmationToken: json['confirmationToken'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
    );
  }

  static String _extractServiceName(Map<String, dynamic> json) {
    if (json['service'] != null && json['service'] is Map) {
      return json['service']['name'] as String? ?? 'Serviço Desconhecido';
    }
    return json['serviceName'] as String? ?? 'Serviço Desconhecido';
  }

  static String? _extractClinicName(Map<String, dynamic> json) {
    if (json['clinic'] != null && json['clinic'] is Map) {
      return json['clinic']['name'] as String?;
    }
    if (json['service'] != null &&
        json['service'] is Map &&
        json['service']['clinic'] != null) {
      return json['service']['clinic']['name'] as String?;
    }
    return json['clinicName'] as String?;
  }

  static AppointmentStatus _parseStatus(dynamic status) {
    if (status is int) {
      // Map int values to AppointmentStatus
      return AppointmentStatus.values.firstWhere(
        (s) => s.value == status.toString(),
        orElse: () => AppointmentStatus.pending,
      );
    }
    if (status is String) {
      // Try to find by value string
      return AppointmentStatus.values.firstWhere(
        (s) => s.value.toLowerCase() == status.toLowerCase(),
        orElse: () => AppointmentStatus.pending,
      );
    }
    return AppointmentStatus.pending;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'serviceName': serviceName,
      'clinicName': clinicName,
      'scheduledDate': scheduledDate.toIso8601String(),
      'status': status.value,
      'totalCredits': totalCredits,
      'confirmationToken': confirmationToken,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
    };
  }

  bool get isCompleted => status == AppointmentStatus.completed;
  bool get isCancelled => status == AppointmentStatus.cancelled;
  bool get isConfirmed => status == AppointmentStatus.confirmed;
  bool get isPending => status == AppointmentStatus.pending;

  String get statusDisplayName => status.label;

  String get formattedDate {
    final day = scheduledDate.day.toString().padLeft(2, '0');
    final month = scheduledDate.month.toString().padLeft(2, '0');
    final year = scheduledDate.year;
    final hour = scheduledDate.hour.toString().padLeft(2, '0');
    final minute = scheduledDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year às $hour:$minute';
  }

  String get formattedDateShort {
    final day = scheduledDate.day.toString().padLeft(2, '0');
    final month = scheduledDate.month.toString().padLeft(2, '0');
    final year = scheduledDate.year;

    return '$day/$month/$year';
  }
}

