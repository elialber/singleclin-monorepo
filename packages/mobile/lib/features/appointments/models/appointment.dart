import 'package:equatable/equatable.dart';
import 'package:singleclin_mobile/features/appointments/models/appointment_status.dart';

/// Appointment Model
/// Represents a medical appointment in the SingleClin system
class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.userId,
    required this.clinicId,
    required this.clinicName,
    required this.serviceId,
    required this.serviceName,
    required this.categoryId,
    required this.categoryName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.status,
    this.professionalId,
    this.professionalName,
    required this.price,
    required this.sgCreditsUsed,
    required this.sgCreditsEarned,
    this.notes,
    this.patientNotes,
    this.preInstructions,
    this.postInstructions,
    this.attachments = const [],
    this.beforePhotos = const [],
    this.afterPhotos = const [],
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.cancellationReason,
    this.cancelledAt,
    this.refundAmount,
    this.reviewId,
    this.rating,
    this.reviewText,
    this.canCancel = true,
    this.canReschedule = true,
    this.canRate = false,
    this.requiresConsent = false,
    this.requiredDocuments = const [],
    this.providedDocuments = const [],
    this.qrCode,
    this.isConfirmed = false,
    this.reminderSent = false,
    this.reminderDate,
  });

  /// Factory method to create from JSON
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      clinicId: json['clinicId'] as String,
      clinicName: json['clinicName'] as String,
      serviceId: json['serviceId'] as String,
      serviceName: json['serviceName'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      scheduledTime: json['scheduledTime'] as String,
      status: AppointmentStatus.fromString(json['status'] as String),
      professionalId: json['professionalId'] as String?,
      professionalName: json['professionalName'] as String?,
      price: (json['price'] as num).toDouble(),
      sgCreditsUsed: (json['sgCreditsUsed'] as num?)?.toDouble() ?? 0.0,
      sgCreditsEarned: (json['sgCreditsEarned'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      patientNotes: json['patientNotes'] as String?,
      preInstructions: json['preInstructions'] as String?,
      postInstructions: json['postInstructions'] as String?,
      attachments: List<String>.from(json['attachments'] as List? ?? []),
      beforePhotos: List<String>.from(json['beforePhotos'] as List? ?? []),
      afterPhotos: List<String>.from(json['afterPhotos'] as List? ?? []),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      cancellationReason: json['cancellationReason'] as String?,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      reviewId: json['reviewId'] as String?,
      rating: json['rating'] as int?,
      reviewText: json['reviewText'] as String?,
      canCancel: json['canCancel'] as bool? ?? true,
      canReschedule: json['canReschedule'] as bool? ?? true,
      canRate: json['canRate'] as bool? ?? false,
      requiresConsent: json['requiresConsent'] as bool? ?? false,
      requiredDocuments: List<String>.from(
        json['requiredDocuments'] as List? ?? [],
      ),
      providedDocuments: List<String>.from(
        json['providedDocuments'] as List? ?? [],
      ),
      qrCode: json['qrCode'] as String?,
      isConfirmed: json['isConfirmed'] as bool? ?? false,
      reminderSent: json['reminderSent'] as bool? ?? false,
      reminderDate: json['reminderDate'] != null
          ? DateTime.parse(json['reminderDate'] as String)
          : null,
    );
  }
  final String id;
  final String userId;
  final String clinicId;
  final String clinicName;
  final String serviceId;
  final String serviceName;
  final String categoryId;
  final String categoryName;
  final DateTime scheduledDate;
  final String scheduledTime;
  final AppointmentStatus status;
  final String? professionalId;
  final String? professionalName;
  final double price;
  final double sgCreditsUsed;
  final double sgCreditsEarned;
  final String? notes;
  final String? patientNotes;
  final String? preInstructions;
  final String? postInstructions;
  final List<String> attachments;
  final List<String> beforePhotos;
  final List<String> afterPhotos;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final double? refundAmount;
  final String? reviewId;
  final int? rating;
  final String? reviewText;
  final bool canCancel;
  final bool canReschedule;
  final bool canRate;
  final bool requiresConsent;
  final List<String> requiredDocuments;
  final List<String> providedDocuments;
  final String? qrCode;
  final bool isConfirmed;
  final bool reminderSent;
  final DateTime? reminderDate;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'clinicId': clinicId,
      'clinicName': clinicName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'scheduledDate': scheduledDate.toIso8601String(),
      'scheduledTime': scheduledTime,
      'status': status.name,
      'professionalId': professionalId,
      'professionalName': professionalName,
      'price': price,
      'sgCreditsUsed': sgCreditsUsed,
      'sgCreditsEarned': sgCreditsEarned,
      'notes': notes,
      'patientNotes': patientNotes,
      'preInstructions': preInstructions,
      'postInstructions': postInstructions,
      'attachments': attachments,
      'beforePhotos': beforePhotos,
      'afterPhotos': afterPhotos,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'refundAmount': refundAmount,
      'reviewId': reviewId,
      'rating': rating,
      'reviewText': reviewText,
      'canCancel': canCancel,
      'canReschedule': canReschedule,
      'canRate': canRate,
      'requiresConsent': requiresConsent,
      'requiredDocuments': requiredDocuments,
      'providedDocuments': providedDocuments,
      'qrCode': qrCode,
      'isConfirmed': isConfirmed,
      'reminderSent': reminderSent,
      'reminderDate': reminderDate?.toIso8601String(),
    };
  }

  /// Create a copy with updated values
  Appointment copyWith({
    String? id,
    String? userId,
    String? clinicId,
    String? clinicName,
    String? serviceId,
    String? serviceName,
    String? categoryId,
    String? categoryName,
    DateTime? scheduledDate,
    String? scheduledTime,
    AppointmentStatus? status,
    String? professionalId,
    String? professionalName,
    double? price,
    double? sgCreditsUsed,
    double? sgCreditsEarned,
    String? notes,
    String? patientNotes,
    String? preInstructions,
    String? postInstructions,
    List<String>? attachments,
    List<String>? beforePhotos,
    List<String>? afterPhotos,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cancellationReason,
    DateTime? cancelledAt,
    double? refundAmount,
    String? reviewId,
    int? rating,
    String? reviewText,
    bool? canCancel,
    bool? canReschedule,
    bool? canRate,
    bool? requiresConsent,
    List<String>? requiredDocuments,
    List<String>? providedDocuments,
    String? qrCode,
    bool? isConfirmed,
    bool? reminderSent,
    DateTime? reminderDate,
  }) {
    return Appointment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clinicId: clinicId ?? this.clinicId,
      clinicName: clinicName ?? this.clinicName,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      professionalId: professionalId ?? this.professionalId,
      professionalName: professionalName ?? this.professionalName,
      price: price ?? this.price,
      sgCreditsUsed: sgCreditsUsed ?? this.sgCreditsUsed,
      sgCreditsEarned: sgCreditsEarned ?? this.sgCreditsEarned,
      notes: notes ?? this.notes,
      patientNotes: patientNotes ?? this.patientNotes,
      preInstructions: preInstructions ?? this.preInstructions,
      postInstructions: postInstructions ?? this.postInstructions,
      attachments: attachments ?? this.attachments,
      beforePhotos: beforePhotos ?? this.beforePhotos,
      afterPhotos: afterPhotos ?? this.afterPhotos,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      refundAmount: refundAmount ?? this.refundAmount,
      reviewId: reviewId ?? this.reviewId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      canCancel: canCancel ?? this.canCancel,
      canReschedule: canReschedule ?? this.canReschedule,
      canRate: canRate ?? this.canRate,
      requiresConsent: requiresConsent ?? this.requiresConsent,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      providedDocuments: providedDocuments ?? this.providedDocuments,
      qrCode: qrCode ?? this.qrCode,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      reminderSent: reminderSent ?? this.reminderSent,
      reminderDate: reminderDate ?? this.reminderDate,
    );
  }

  /// Get time remaining until appointment
  Duration get timeUntilAppointment {
    final now = DateTime.now();
    final appointmentDateTime = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      int.parse(scheduledTime.split(':')[0]),
      int.parse(scheduledTime.split(':')[1]),
    );
    return appointmentDateTime.difference(now);
  }

  /// Check if appointment is in the past
  bool get isPast {
    return timeUntilAppointment.isNegative;
  }

  /// Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  /// Check if appointment can be cancelled based on time
  bool get canCancelByTime {
    return !isPast && timeUntilAppointment.inHours >= 24;
  }

  /// Get formatted date string
  String get formattedDate {
    final months = [
      '',
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${scheduledDate.day} ${months[scheduledDate.month]}';
  }

  /// Get formatted time string
  String get formattedTime {
    return scheduledTime;
  }

  /// Get status color based on appointment status
  String get statusColor {
    return status.color;
  }

  /// Get status icon
  String get statusIcon {
    return status.icon;
  }

  /// Check if all required documents are provided
  bool get hasAllRequiredDocuments {
    return requiredDocuments.every(providedDocuments.contains);
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    clinicId,
    serviceId,
    scheduledDate,
    scheduledTime,
    status,
    price,
    sgCreditsUsed,
    updatedAt,
  ];

  @override
  String toString() {
    return 'Appointment(id: $id, service: $serviceName, date: $formattedDate, time: $formattedTime, status: ${status.name})';
  }
}
