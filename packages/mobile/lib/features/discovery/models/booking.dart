import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'service.dart';
import 'clinic.dart';

/// Represents a booking/appointment in the SingleClin system
class Booking extends Equatable {
  final String id;
  final String userId;
  final String clinicId;
  final String serviceId;
  final Clinic? clinic; // Populated when fetched with details
  final Service? service; // Populated when fetched with details
  final DateTime scheduledDate;
  final TimeOfDay scheduledTime;
  final BookingStatus status;
  final int totalCostSG;
  final PaymentStatus paymentStatus;
  final String? notes;
  final String? cancellationReason;
  final DateTime? cancellationDate;
  final String? professionalId;
  final String? professionalName;
  final BookingReminders reminders;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool requiresPreparation;
  final String? preparationNotes;
  final bool hasFollowUp;
  final DateTime? followUpDate;

  const Booking({
    required this.id,
    required this.userId,
    required this.clinicId,
    required this.serviceId,
    this.clinic,
    this.service,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.status,
    required this.totalCostSG,
    required this.paymentStatus,
    this.notes,
    this.cancellationReason,
    this.cancellationDate,
    this.professionalId,
    this.professionalName,
    required this.reminders,
    required this.createdAt,
    required this.updatedAt,
    this.requiresPreparation = false,
    this.preparationNotes,
    this.hasFollowUp = false,
    this.followUpDate,
  });

  /// Combined date and time for scheduling
  DateTime get scheduledDateTime {
    return DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );
  }

  /// Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
           scheduledDate.month == now.month &&
           scheduledDate.day == now.day;
  }

  /// Check if appointment is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return scheduledDate.year == tomorrow.year &&
           scheduledDate.month == tomorrow.month &&
           scheduledDate.day == tomorrow.day;
  }

  /// Check if appointment is in the past
  bool get isPast => scheduledDateTime.isBefore(DateTime.now());

  /// Check if appointment is upcoming (future)
  bool get isUpcoming => scheduledDateTime.isAfter(DateTime.now());

  /// Check if appointment can be cancelled
  bool get canBeCancelled {
    return status == BookingStatus.confirmed &&
           scheduledDateTime.isAfter(DateTime.now().add(const Duration(hours: 24)));
  }

  /// Check if appointment can be rescheduled
  bool get canBeRescheduled {
    return (status == BookingStatus.confirmed || status == BookingStatus.pending) &&
           scheduledDateTime.isAfter(DateTime.now().add(const Duration(hours: 24)));
  }

  /// Time until appointment in hours
  int get hoursUntilAppointment {
    final now = DateTime.now();
    if (isPast) return 0;
    return scheduledDateTime.difference(now).inHours;
  }

  /// Formatted date display
  String get formattedDate {
    if (isToday) return 'Hoje';
    if (isTomorrow) return 'Amanhã';
    
    final weekdays = [
      '', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
    ];
    final months = [
      '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    
    return '${weekdays[scheduledDate.weekday]}, ${scheduledDate.day} ${months[scheduledDate.month]}';
  }

  /// Formatted time display
  String get formattedTime {
    return '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
  }

  /// Formatted date and time display
  String get formattedDateTime => '$formattedDate às $formattedTime';

  /// Status display text
  String get statusDisplayText {
    switch (status) {
      case BookingStatus.pending:
        return 'Pendente';
      case BookingStatus.confirmed:
        return 'Confirmado';
      case BookingStatus.completed:
        return 'Concluído';
      case BookingStatus.cancelled:
        return 'Cancelado';
      case BookingStatus.noShow:
        return 'Não compareceu';
      case BookingStatus.rescheduled:
        return 'Reagendado';
    }
  }

  /// Payment status display text
  String get paymentStatusDisplayText {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Pagamento pendente';
      case PaymentStatus.paid:
        return 'Pago';
      case PaymentStatus.refunded:
        return 'Reembolsado';
      case PaymentStatus.failed:
        return 'Falha no pagamento';
    }
  }

  /// Get reminder notification times
  List<DateTime> get reminderTimes {
    final reminderTimes = <DateTime>[];
    final appointmentTime = scheduledDateTime;
    
    if (reminders.oneDayBefore) {
      reminderTimes.add(appointmentTime.subtract(const Duration(days: 1)));
    }
    if (reminders.oneHourBefore) {
      reminderTimes.add(appointmentTime.subtract(const Duration(hours: 1)));
    }
    if (reminders.thirtyMinutesBefore) {
      reminderTimes.add(appointmentTime.subtract(const Duration(minutes: 30)));
    }
    
    return reminderTimes;
  }

  /// Create copy with updated fields
  Booking copyWith({
    String? id,
    String? userId,
    String? clinicId,
    String? serviceId,
    Clinic? clinic,
    Service? service,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
    BookingStatus? status,
    int? totalCostSG,
    PaymentStatus? paymentStatus,
    String? notes,
    String? cancellationReason,
    DateTime? cancellationDate,
    String? professionalId,
    String? professionalName,
    BookingReminders? reminders,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? requiresPreparation,
    String? preparationNotes,
    bool? hasFollowUp,
    DateTime? followUpDate,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clinicId: clinicId ?? this.clinicId,
      serviceId: serviceId ?? this.serviceId,
      clinic: clinic ?? this.clinic,
      service: service ?? this.service,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      totalCostSG: totalCostSG ?? this.totalCostSG,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancellationDate: cancellationDate ?? this.cancellationDate,
      professionalId: professionalId ?? this.professionalId,
      professionalName: professionalName ?? this.professionalName,
      reminders: reminders ?? this.reminders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      requiresPreparation: requiresPreparation ?? this.requiresPreparation,
      preparationNotes: preparationNotes ?? this.preparationNotes,
      hasFollowUp: hasFollowUp ?? this.hasFollowUp,
      followUpDate: followUpDate ?? this.followUpDate,
    );
  }

  /// Create from JSON
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      userId: json['userId'] as String,
      clinicId: json['clinicId'] as String,
      serviceId: json['serviceId'] as String,
      clinic: json['clinic'] != null 
          ? Clinic.fromJson(json['clinic'] as Map<String, dynamic>)
          : null,
      service: json['service'] != null 
          ? Service.fromJson(json['service'] as Map<String, dynamic>)
          : null,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      scheduledTime: TimeOfDay(
        hour: json['scheduledHour'] as int,
        minute: json['scheduledMinute'] as int,
      ),
      status: BookingStatus.fromString(json['status'] as String),
      totalCostSG: json['totalCostSG'] as int,
      paymentStatus: PaymentStatus.fromString(json['paymentStatus'] as String),
      notes: json['notes'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      cancellationDate: json['cancellationDate'] != null
          ? DateTime.parse(json['cancellationDate'] as String)
          : null,
      professionalId: json['professionalId'] as String?,
      professionalName: json['professionalName'] as String?,
      reminders: BookingReminders.fromJson(
          json['reminders'] as Map<String, dynamic>? ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      requiresPreparation: json['requiresPreparation'] as bool? ?? false,
      preparationNotes: json['preparationNotes'] as String?,
      hasFollowUp: json['hasFollowUp'] as bool? ?? false,
      followUpDate: json['followUpDate'] != null
          ? DateTime.parse(json['followUpDate'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'clinicId': clinicId,
      'serviceId': serviceId,
      'clinic': clinic?.toJson(),
      'service': service?.toJson(),
      'scheduledDate': scheduledDate.toIso8601String(),
      'scheduledHour': scheduledTime.hour,
      'scheduledMinute': scheduledTime.minute,
      'status': status.name,
      'totalCostSG': totalCostSG,
      'paymentStatus': paymentStatus.name,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'cancellationDate': cancellationDate?.toIso8601String(),
      'professionalId': professionalId,
      'professionalName': professionalName,
      'reminders': reminders.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'requiresPreparation': requiresPreparation,
      'preparationNotes': preparationNotes,
      'hasFollowUp': hasFollowUp,
      'followUpDate': followUpDate?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        clinicId,
        serviceId,
        clinic,
        service,
        scheduledDate,
        scheduledTime,
        status,
        totalCostSG,
        paymentStatus,
        notes,
        cancellationReason,
        cancellationDate,
        professionalId,
        professionalName,
        reminders,
        createdAt,
        updatedAt,
        requiresPreparation,
        preparationNotes,
        hasFollowUp,
        followUpDate,
      ];
}

/// Booking status enumeration
enum BookingStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  noShow,
  rescheduled;

  static BookingStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'no_show':
      case 'noshow':
        return BookingStatus.noShow;
      case 'rescheduled':
        return BookingStatus.rescheduled;
      default:
        return BookingStatus.pending;
    }
  }
}

/// Payment status enumeration
enum PaymentStatus {
  pending,
  paid,
  refunded,
  failed;

  static PaymentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'paid':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }
}

/// Booking reminder settings
class BookingReminders extends Equatable {
  final bool oneDayBefore;
  final bool oneHourBefore;
  final bool thirtyMinutesBefore;

  const BookingReminders({
    this.oneDayBefore = true,
    this.oneHourBefore = true,
    this.thirtyMinutesBefore = false,
  });

  factory BookingReminders.fromJson(Map<String, dynamic> json) {
    return BookingReminders(
      oneDayBefore: json['oneDayBefore'] as bool? ?? true,
      oneHourBefore: json['oneHourBefore'] as bool? ?? true,
      thirtyMinutesBefore: json['thirtyMinutesBefore'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'oneDayBefore': oneDayBefore,
      'oneHourBefore': oneHourBefore,
      'thirtyMinutesBefore': thirtyMinutesBefore,
    };
  }

  @override
  List<Object?> get props => [oneDayBefore, oneHourBefore, thirtyMinutesBefore];
}

/// Booking creation request model
class BookingRequest extends Equatable {
  final String clinicId;
  final String serviceId;
  final DateTime scheduledDate;
  final TimeOfDay scheduledTime;
  final String? notes;
  final String? professionalId;
  final BookingReminders reminders;
  final bool agreedToTerms;

  const BookingRequest({
    required this.clinicId,
    required this.serviceId,
    required this.scheduledDate,
    required this.scheduledTime,
    this.notes,
    this.professionalId,
    this.reminders = const BookingReminders(),
    this.agreedToTerms = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'clinicId': clinicId,
      'serviceId': serviceId,
      'scheduledDate': scheduledDate.toIso8601String(),
      'scheduledHour': scheduledTime.hour,
      'scheduledMinute': scheduledTime.minute,
      'notes': notes,
      'professionalId': professionalId,
      'reminders': reminders.toJson(),
      'agreedToTerms': agreedToTerms,
    };
  }

  @override
  List<Object?> get props => [
        clinicId,
        serviceId,
        scheduledDate,
        scheduledTime,
        notes,
        professionalId,
        reminders,
        agreedToTerms,
      ];
}

/// Booking cancellation request model
class BookingCancellationRequest extends Equatable {
  final String bookingId;
  final String reason;
  final bool requestRefund;

  const BookingCancellationRequest({
    required this.bookingId,
    required this.reason,
    this.requestRefund = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'reason': reason,
      'requestRefund': requestRefund,
    };
  }

  @override
  List<Object?> get props => [bookingId, reason, requestRefund];
}

/// Booking reschedule request model
class BookingRescheduleRequest extends Equatable {
  final String bookingId;
  final DateTime newDate;
  final TimeOfDay newTime;
  final String? reason;

  const BookingRescheduleRequest({
    required this.bookingId,
    required this.newDate,
    required this.newTime,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'newDate': newDate.toIso8601String(),
      'newHour': newTime.hour,
      'newMinute': newTime.minute,
      'reason': reason,
    };
  }

  @override
  List<Object?> get props => [bookingId, newDate, newTime, reason];
}

/// Available time slot for booking
class TimeSlot extends Equatable {
  final TimeOfDay time;
  final bool isAvailable;
  final String? unavailabilityReason;
  final String? professionalId;
  final String? professionalName;

  const TimeSlot({
    required this.time,
    required this.isAvailable,
    this.unavailabilityReason,
    this.professionalId,
    this.professionalName,
  });

  String get formattedTime {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      time: TimeOfDay(
        hour: json['hour'] as int,
        minute: json['minute'] as int,
      ),
      isAvailable: json['isAvailable'] as bool,
      unavailabilityReason: json['unavailabilityReason'] as String?,
      professionalId: json['professionalId'] as String?,
      professionalName: json['professionalName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': time.hour,
      'minute': time.minute,
      'isAvailable': isAvailable,
      'unavailabilityReason': unavailabilityReason,
      'professionalId': professionalId,
      'professionalName': professionalName,
    };
  }

  @override
  List<Object?> get props => [
        time,
        isAvailable,
        unavailabilityReason,
        professionalId,
        professionalName,
      ];
}