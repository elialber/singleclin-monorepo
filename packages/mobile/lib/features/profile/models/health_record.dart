import 'package:equatable/equatable.dart';

/// Health Record Model
/// Represents medical history and health records for the user
class HealthRecord extends Equatable {
  const HealthRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.date,
    required this.createdAt, required this.updatedAt, this.clinicId,
    this.clinicName,
    this.professionalId,
    this.professionalName,
    this.appointmentId,
    this.attachments = const [],
    this.photos = const [],
    this.results,
    this.recommendations = const [],
    this.followUpDate,
    this.isImportant = false,
    this.tags = const [],
    this.status = HealthRecordStatus.active,
    this.metadata,
  });

  /// Factory method to create from JSON
  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      clinicId: json['clinicId'] as String?,
      clinicName: json['clinicName'] as String?,
      professionalId: json['professionalId'] as String?,
      professionalName: json['professionalName'] as String?,
      appointmentId: json['appointmentId'] as String?,
      attachments: List<String>.from(json['attachments'] as List? ?? []),
      photos: List<String>.from(json['photos'] as List? ?? []),
      results: json['results'] as Map<String, dynamic>?,
      recommendations: List<String>.from(
        json['recommendations'] as List? ?? [],
      ),
      followUpDate: json['followUpDate'] as String?,
      isImportant: json['isImportant'] as bool? ?? false,
      tags: List<String>.from(json['tags'] as List? ?? []),
      status: HealthRecordStatus.fromString(
        json['status'] as String? ?? 'active',
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  final String id;
  final String userId;
  final String type;
  final String title;
  final String description;
  final DateTime date;
  final String? clinicId;
  final String? clinicName;
  final String? professionalId;
  final String? professionalName;
  final String? appointmentId;
  final List<String> attachments;
  final List<String> photos;
  final Map<String, dynamic>? results;
  final List<String> recommendations;
  final String? followUpDate;
  final bool isImportant;
  final List<String> tags;
  final HealthRecordStatus status;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'clinicId': clinicId,
      'clinicName': clinicName,
      'professionalId': professionalId,
      'professionalName': professionalName,
      'appointmentId': appointmentId,
      'attachments': attachments,
      'photos': photos,
      'results': results,
      'recommendations': recommendations,
      'followUpDate': followUpDate,
      'isImportant': isImportant,
      'tags': tags,
      'status': status.value,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated values
  HealthRecord copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? description,
    DateTime? date,
    String? clinicId,
    String? clinicName,
    String? professionalId,
    String? professionalName,
    String? appointmentId,
    List<String>? attachments,
    List<String>? photos,
    Map<String, dynamic>? results,
    List<String>? recommendations,
    String? followUpDate,
    bool? isImportant,
    List<String>? tags,
    HealthRecordStatus? status,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      clinicId: clinicId ?? this.clinicId,
      clinicName: clinicName ?? this.clinicName,
      professionalId: professionalId ?? this.professionalId,
      professionalName: professionalName ?? this.professionalName,
      appointmentId: appointmentId ?? this.appointmentId,
      attachments: attachments ?? this.attachments,
      photos: photos ?? this.photos,
      results: results ?? this.results,
      recommendations: recommendations ?? this.recommendations,
      followUpDate: followUpDate ?? this.followUpDate,
      isImportant: isImportant ?? this.isImportant,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ano${years > 1 ? 's' : ''} atrás';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months mês${months > 1 ? 'es' : ''} atrás';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} dia${difference.inDays > 1 ? 's' : ''} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''} atrás';
    } else {
      return 'Hoje';
    }
  }

  /// Get record type color
  String get typeColor {
    return HealthRecordType.fromString(type).color;
  }

  /// Get record type icon
  String get typeIcon {
    return HealthRecordType.fromString(type).icon;
  }

  /// Check if record has attachments
  bool get hasAttachments {
    return attachments.isNotEmpty || photos.isNotEmpty;
  }

  /// Get total attachments count
  int get totalAttachments {
    return attachments.length + photos.length;
  }

  /// Check if has follow up
  bool get hasFollowUp {
    return followUpDate != null && followUpDate!.isNotEmpty;
  }

  /// Check if follow up is due
  bool get isFollowUpDue {
    if (!hasFollowUp) return false;
    final followUp = DateTime.tryParse(followUpDate!);
    if (followUp == null) return false;
    return DateTime.now().isAfter(followUp);
  }

  @override
  List<Object?> get props => [id, userId, type, title, date, updatedAt];

  @override
  String toString() {
    return 'HealthRecord(id: $id, type: $type, title: $title, date: $formattedDate)';
  }
}

/// Health Record Status
enum HealthRecordStatus {
  active('active', 'Ativo'),
  archived('archived', 'Arquivado'),
  deleted('deleted', 'Excluído');

  const HealthRecordStatus(this.value, this.label);

  final String value;
  final String label;

  static HealthRecordStatus fromString(String value) {
    return values.firstWhere(
      (status) => status.value == value,
      orElse: () => active,
    );
  }
}

/// Health Record Types
enum HealthRecordType {
  consultation('consultation', 'Consulta', '#2196F3', 'medical_services'),
  exam('exam', 'Exame', '#4CAF50', 'biotech'),
  procedure('procedure', 'Procedimento', '#9C27B0', 'healing'),
  vaccination('vaccination', 'Vacinação', '#FF9800', 'vaccines'),
  prescription('prescription', 'Receita', '#E91E63', 'medication'),
  allergy('allergy', 'Alergia', '#F44336', 'warning'),
  surgery('surgery', 'Cirurgia', '#795548', 'local_hospital'),
  therapy('therapy', 'Terapia', '#607D8B', 'psychology'),
  nutrition('nutrition', 'Nutrição', '#8BC34A', 'restaurant'),
  fitness('fitness', 'Exercício', '#FF5722', 'fitness_center'),
  mental_health('mental_health', 'Saúde Mental', '#673AB7', 'mood'),
  chronic_condition(
    'chronic_condition',
    'Condição Crônica',
    '#FFC107',
    'monitor_heart',
  ),
  emergency('emergency', 'Emergência', '#D32F2F', 'emergency'),
  followup('followup', 'Retorno', '#00BCD4', 'event_repeat'),
  other('other', 'Outro', '#9E9E9E', 'description');

  const HealthRecordType(this.value, this.label, this.color, this.icon);

  final String value;
  final String label;
  final String color;
  final String icon;

  static HealthRecordType fromString(String value) {
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => other,
    );
  }

  /// Get all procedure types
  static List<HealthRecordType> get procedureTypes => [
    consultation,
    exam,
    procedure,
    surgery,
    therapy,
  ];

  /// Get all medical types
  static List<HealthRecordType> get medicalTypes => [
    consultation,
    exam,
    procedure,
    vaccination,
    prescription,
    surgery,
  ];

  /// Get all lifestyle types
  static List<HealthRecordType> get lifestyleTypes => [
    nutrition,
    fitness,
    mental_health,
  ];
}

/// Health Metric Model
/// For tracking specific health metrics over time
class HealthMetric extends Equatable {
  const HealthMetric({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedDate,
    this.source,
    this.notes,
    this.metadata,
  });

  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    return HealthMetric(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      recordedDate: DateTime.parse(json['recordedDate'] as String),
      source: json['source'] as String?,
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  final String id;
  final String userId;
  final String type;
  final double value;
  final String unit;
  final DateTime recordedDate;
  final String? source;
  final String? notes;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'value': value,
      'unit': unit,
      'recordedDate': recordedDate.toIso8601String(),
      'source': source,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Get formatted value with unit
  String get formattedValue {
    if (value == value.toInt()) {
      return '${value.toInt()} $unit';
    }
    return '${value.toStringAsFixed(1)} $unit';
  }

  /// Get metric type info
  HealthMetricType get metricType {
    return HealthMetricType.fromString(type);
  }

  @override
  List<Object?> get props => [id, userId, type, value, recordedDate];
}

/// Health Metric Types
enum HealthMetricType {
  weight('weight', 'Peso', 'kg', '#4CAF50'),
  height('height', 'Altura', 'cm', '#2196F3'),
  bloodPressure('blood_pressure', 'Pressão Arterial', 'mmHg', '#F44336'),
  heartRate('heart_rate', 'Frequência Cardíaca', 'bpm', '#E91E63'),
  bloodSugar('blood_sugar', 'Glicemia', 'mg/dL', '#FF9800'),
  cholesterol('cholesterol', 'Colesterol', 'mg/dL', '#9C27B0'),
  temperature('temperature', 'Temperatura', '°C', '#FF5722'),
  oxygenSaturation('oxygen_saturation', 'Saturação O2', '%', '#00BCD4'),
  steps('steps', 'Passos', 'passos', '#8BC34A'),
  sleep('sleep', 'Sono', 'horas', '#673AB7'),
  water('water', 'Água', 'L', '#03A9F4'),
  calories('calories', 'Calorias', 'kcal', '#FFC107');

  const HealthMetricType(this.value, this.label, this.unit, this.color);

  final String value;
  final String label;
  final String unit;
  final String color;

  static HealthMetricType fromString(String value) {
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => weight,
    );
  }

  /// Get vital signs metrics
  static List<HealthMetricType> get vitalSigns => [
    bloodPressure,
    heartRate,
    temperature,
    oxygenSaturation,
  ];

  /// Get body metrics
  static List<HealthMetricType> get bodyMetrics => [weight, height];

  /// Get lab metrics
  static List<HealthMetricType> get labMetrics => [bloodSugar, cholesterol];

  /// Get lifestyle metrics
  static List<HealthMetricType> get lifestyleMetrics => [
    steps,
    sleep,
    water,
    calories,
  ];
}
