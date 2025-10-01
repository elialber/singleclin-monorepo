enum AppointmentStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  canceled,
  noShow,
  rescheduled,
}

enum AppointmentType { consultation, procedure, followUp, emergency }

class AppointmentModel {
  AppointmentModel({
    required this.id,
    required this.userId,
    required this.clinicId,
    required this.serviceId,
    required this.appointmentDate,
    required this.durationMinutes,
    required this.sgCost,
    required this.status,
    required this.type,
    this.notes,
    this.cancelReason,
    this.canceledAt,
    this.rescheduledFromId,
    required this.createdAt,
    required this.updatedAt,
    this.clinic,
    this.service,
    this.documents,
    this.review,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      clinicId: json['clinicId'] ?? '',
      serviceId: json['serviceId'] ?? '',
      appointmentDate: DateTime.parse(json['appointmentDate']),
      durationMinutes: json['durationMinutes'] ?? 60,
      sgCost: json['sgCost'] ?? 0,
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      type: AppointmentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AppointmentType.consultation,
      ),
      notes: json['notes'],
      cancelReason: json['cancelReason'],
      canceledAt: json['canceledAt'] != null
          ? DateTime.parse(json['canceledAt'])
          : null,
      rescheduledFromId: json['rescheduledFromId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      clinic: json['clinic'] != null
          ? ClinicModel.fromJson(json['clinic'])
          : null,
      service: json['service'] != null
          ? ServiceModel.fromJson(json['service'])
          : null,
      documents: json['documents'] != null
          ? List<AppointmentDocument>.from(
              json['documents'].map((x) => AppointmentDocument.fromJson(x)),
            )
          : null,
      review: json['review'] != null
          ? AppointmentReview.fromJson(json['review'])
          : null,
    );
  }
  final String id;
  final String userId;
  final String clinicId;
  final String serviceId;
  final DateTime appointmentDate;
  final int durationMinutes;
  final int sgCost;
  final AppointmentStatus status;
  final AppointmentType type;
  final String? notes;
  final String? cancelReason;
  final DateTime? canceledAt;
  final String? rescheduledFromId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relacionamentos
  final ClinicModel? clinic;
  final ServiceModel? service;
  final List<AppointmentDocument>? documents;
  final AppointmentReview? review;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'clinicId': clinicId,
      'serviceId': serviceId,
      'appointmentDate': appointmentDate.toIso8601String(),
      'durationMinutes': durationMinutes,
      'sgCost': sgCost,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'notes': notes,
      'cancelReason': cancelReason,
      'canceledAt': canceledAt?.toIso8601String(),
      'rescheduledFromId': rescheduledFromId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'clinic': clinic?.toJson(),
      'service': service?.toJson(),
      'documents': documents?.map((x) => x.toJson()).toList(),
      'review': review?.toJson(),
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? userId,
    String? clinicId,
    String? serviceId,
    DateTime? appointmentDate,
    int? durationMinutes,
    int? sgCost,
    AppointmentStatus? status,
    AppointmentType? type,
    String? notes,
    String? cancelReason,
    DateTime? canceledAt,
    String? rescheduledFromId,
    DateTime? createdAt,
    DateTime? updatedAt,
    ClinicModel? clinic,
    ServiceModel? service,
    List<AppointmentDocument>? documents,
    AppointmentReview? review,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clinicId: clinicId ?? this.clinicId,
      serviceId: serviceId ?? this.serviceId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sgCost: sgCost ?? this.sgCost,
      status: status ?? this.status,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      cancelReason: cancelReason ?? this.cancelReason,
      canceledAt: canceledAt ?? this.canceledAt,
      rescheduledFromId: rescheduledFromId ?? this.rescheduledFromId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clinic: clinic ?? this.clinic,
      service: service ?? this.service,
      documents: documents ?? this.documents,
      review: review ?? this.review,
    );
  }

  bool get canCancel {
    if (status == AppointmentStatus.canceled ||
        status == AppointmentStatus.completed ||
        status == AppointmentStatus.noShow) {
      return false;
    }

    final now = DateTime.now();
    final hoursUntilAppointment = appointmentDate.difference(now).inHours;

    return hoursUntilAppointment >= 24; // Pode cancelar com 24h de antecedência
  }

  bool get canReschedule {
    if (status == AppointmentStatus.canceled ||
        status == AppointmentStatus.completed ||
        status == AppointmentStatus.noShow) {
      return false;
    }

    final now = DateTime.now();
    final hoursUntilAppointment = appointmentDate.difference(now).inHours;

    return hoursUntilAppointment >= 2; // Pode reagendar com 2h de antecedência
  }

  bool get canReview {
    return status == AppointmentStatus.completed && review == null;
  }

  DateTime get endTime {
    return appointmentDate.add(Duration(minutes: durationMinutes));
  }

  String get statusDisplayName {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pendente';
      case AppointmentStatus.confirmed:
        return 'Confirmado';
      case AppointmentStatus.inProgress:
        return 'Em andamento';
      case AppointmentStatus.completed:
        return 'Concluído';
      case AppointmentStatus.canceled:
        return 'Cancelado';
      case AppointmentStatus.noShow:
        return 'Não compareceu';
      case AppointmentStatus.rescheduled:
        return 'Reagendado';
    }
  }
}

class AppointmentDocument {
  AppointmentDocument({
    required this.id,
    required this.appointmentId,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    required this.uploadedAt,
  });

  factory AppointmentDocument.fromJson(Map<String, dynamic> json) {
    return AppointmentDocument(
      id: json['id'] ?? '',
      appointmentId: json['appointmentId'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      type: json['type'] ?? '',
      size: json['size'] ?? 0,
      uploadedAt: DateTime.parse(json['uploadedAt']),
    );
  }
  final String id;
  final String appointmentId;
  final String name;
  final String url;
  final String type;
  final int size;
  final DateTime uploadedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'name': name,
      'url': url,
      'type': type,
      'size': size,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

class AppointmentReview {
  AppointmentReview({
    required this.id,
    required this.appointmentId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory AppointmentReview.fromJson(Map<String, dynamic> json) {
    return AppointmentReview(
      id: json['id'] ?? '',
      appointmentId: json['appointmentId'] ?? '',
      userId: json['userId'] ?? '',
      rating: json['rating'] ?? 5,
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
  final String id;
  final String appointmentId;
  final String userId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
