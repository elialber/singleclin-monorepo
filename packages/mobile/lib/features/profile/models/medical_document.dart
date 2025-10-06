import 'package:equatable/equatable.dart';

/// Medical Document Model
/// Represents medical documents, files, and images
class MedicalDocument extends Equatable {
  const MedicalDocument({
    required this.id,
    required this.userId,
    required this.name,
    required this.originalName,
    required this.type,
    required this.mimeType,
    required this.fileSize,
    required this.uploadedAt, required this.createdAt, required this.updatedAt, this.fileUrl,
    this.thumbnailUrl,
    this.localPath,
    this.description,
    this.associatedAppointmentId,
    this.associatedRecordId,
    this.tags = const [],
    this.isEncrypted = true,
    this.metadata,
    this.status = DocumentStatus.active,
    this.expiresAt,
    this.isShared = false,
    this.sharedWith = const [],
    this.encryptionKey,
  });

  /// Factory method to create from JSON
  factory MedicalDocument.fromJson(Map<String, dynamic> json) {
    return MedicalDocument(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      originalName: json['originalName'] as String,
      type: DocumentType.fromString(json['type'] as String),
      mimeType: json['mimeType'] as String,
      fileSize: json['fileSize'] as int,
      fileUrl: json['fileUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      localPath: json['localPath'] as String?,
      description: json['description'] as String?,
      associatedAppointmentId: json['associatedAppointmentId'] as String?,
      associatedRecordId: json['associatedRecordId'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      isEncrypted: json['isEncrypted'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
      status: DocumentStatus.fromString(json['status'] as String? ?? 'active'),
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      isShared: json['isShared'] as bool? ?? false,
      sharedWith: List<String>.from(json['sharedWith'] as List? ?? []),
      encryptionKey: json['encryptionKey'] as String?,
    );
  }
  final String id;
  final String userId;
  final String name;
  final String originalName;
  final DocumentType type;
  final String mimeType;
  final int fileSize;
  final String? fileUrl;
  final String? thumbnailUrl;
  final String? localPath;
  final String? description;
  final String? associatedAppointmentId;
  final String? associatedRecordId;
  final List<String> tags;
  final bool isEncrypted;
  final Map<String, dynamic>? metadata;
  final DocumentStatus status;
  final DateTime uploadedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final bool isShared;
  final List<String> sharedWith;
  final String? encryptionKey;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'originalName': originalName,
      'type': type.value,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'localPath': localPath,
      'description': description,
      'associatedAppointmentId': associatedAppointmentId,
      'associatedRecordId': associatedRecordId,
      'tags': tags,
      'isEncrypted': isEncrypted,
      'metadata': metadata,
      'status': status.value,
      'uploadedAt': uploadedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isShared': isShared,
      'sharedWith': sharedWith,
      'encryptionKey': encryptionKey,
    };
  }

  /// Create a copy with updated values
  MedicalDocument copyWith({
    String? id,
    String? userId,
    String? name,
    String? originalName,
    DocumentType? type,
    String? mimeType,
    int? fileSize,
    String? fileUrl,
    String? thumbnailUrl,
    String? localPath,
    String? description,
    String? associatedAppointmentId,
    String? associatedRecordId,
    List<String>? tags,
    bool? isEncrypted,
    Map<String, dynamic>? metadata,
    DocumentStatus? status,
    DateTime? uploadedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    bool? isShared,
    List<String>? sharedWith,
    String? encryptionKey,
  }) {
    return MedicalDocument(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      originalName: originalName ?? this.originalName,
      type: type ?? this.type,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      fileUrl: fileUrl ?? this.fileUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      localPath: localPath ?? this.localPath,
      description: description ?? this.description,
      associatedAppointmentId:
          associatedAppointmentId ?? this.associatedAppointmentId,
      associatedRecordId: associatedRecordId ?? this.associatedRecordId,
      tags: tags ?? this.tags,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isShared: isShared ?? this.isShared,
      sharedWith: sharedWith ?? this.sharedWith,
      encryptionKey: encryptionKey ?? this.encryptionKey,
    );
  }

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get file extension
  String get fileExtension {
    return originalName.split('.').last.toLowerCase();
  }

  /// Check if document is an image
  bool get isImage {
    return mimeType.startsWith('image/');
  }

  /// Check if document is a PDF
  bool get isPdf {
    return mimeType == 'application/pdf';
  }

  /// Check if document is a video
  bool get isVideo {
    return mimeType.startsWith('video/');
  }

  /// Check if document is expired
  bool get isExpired {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  /// Get formatted upload date
  String get formattedUploadDate {
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
    return '${uploadedAt.day} ${months[uploadedAt.month]} ${uploadedAt.year}';
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(uploadedAt);

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
      return 'Agora';
    }
  }

  /// Get document icon based on type
  String get icon {
    return type.icon;
  }

  /// Get document color based on type
  String get color {
    return type.color;
  }

  /// Check if document can be previewed
  bool get canPreview {
    return isImage || isPdf;
  }

  /// Check if document is available (not deleted or expired)
  bool get isAvailable {
    return status == DocumentStatus.active && !isExpired;
  }

  @override
  List<Object?> get props => [id, userId, name, type, fileSize, updatedAt];

  @override
  String toString() {
    return 'MedicalDocument(id: $id, name: $name, type: ${type.label}, size: $formattedFileSize)';
  }
}

/// Document Type Enum
enum DocumentType {
  examResult('exam_result', 'Resultado de Exame', '#4CAF50', 'biotech'),
  prescription('prescription', 'Receita Médica', '#E91E63', 'medication'),
  medicalReport('medical_report', 'Relatório Médico', '#2196F3', 'description'),
  xray('xray', 'Raio-X', '#9C27B0', 'medical_services'),
  ultrasound('ultrasound', 'Ultrassom', '#FF9800', 'pregnant_woman'),
  mri('mri', 'Ressonância', '#607D8B', 'sensors'),
  ctScan('ct_scan', 'Tomografia', '#795548', 'scanner'),
  bloodTest('blood_test', 'Exame de Sangue', '#F44336', 'bloodtype'),
  urineTest('urine_test', 'Exame de Urina', '#FFC107', 'water_drop'),
  biopsy('biopsy', 'Biópsia', '#673AB7', 'science'),
  ecg('ecg', 'Eletrocardiograma', '#E91E63', 'monitor_heart'),
  eeg('eeg', 'Eletroencefalograma', '#9C27B0', 'psychology'),
  vaccinationCard(
    'vaccination_card',
    'Cartão de Vacinação',
    '#8BC34A',
    'vaccines',
  ),
  insuranceCard(
    'insurance_card',
    'Cartão do Convênio',
    '#00BCD4',
    'credit_card',
  ),
  identityDocument(
    'identity_document',
    'Documento de Identidade',
    '#FF5722',
    'badge',
  ),
  consentForm(
    'consent_form',
    'Termo de Consentimento',
    '#795548',
    'assignment',
  ),
  beforePhoto('before_photo', 'Foto Antes', '#3F51B5', 'camera_alt'),
  afterPhoto('after_photo', 'Foto Depois', '#009688', 'camera_alt'),
  progressPhoto(
    'progress_photo',
    'Foto de Progresso',
    '#CDDC39',
    'photo_camera',
  ),
  invoice('invoice', 'Nota Fiscal', '#FF9800', 'receipt'),
  other('other', 'Outro', '#9E9E9E', 'description');

  const DocumentType(this.value, this.label, this.color, this.icon);

  final String value;
  final String label;
  final String color;
  final String icon;

  static DocumentType fromString(String value) {
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => other,
    );
  }

  /// Get exam document types
  static List<DocumentType> get examTypes => [
    examResult,
    xray,
    ultrasound,
    mri,
    ctScan,
    bloodTest,
    urineTest,
    biopsy,
    ecg,
    eeg,
  ];

  /// Get administrative document types
  static List<DocumentType> get administrativeTypes => [
    prescription,
    medicalReport,
    vaccinationCard,
    insuranceCard,
    identityDocument,
    consentForm,
    invoice,
  ];

  /// Get photo document types
  static List<DocumentType> get photoTypes => [
    beforePhoto,
    afterPhoto,
    progressPhoto,
  ];

  /// Check if type is a photo
  bool get isPhoto {
    return photoTypes.contains(this);
  }

  /// Check if type is an exam
  bool get isExam {
    return examTypes.contains(this);
  }

  /// Check if type is administrative
  bool get isAdministrative {
    return administrativeTypes.contains(this);
  }
}

/// Document Status Enum
enum DocumentStatus {
  active('active', 'Ativo'),
  processing('processing', 'Processando'),
  archived('archived', 'Arquivado'),
  deleted('deleted', 'Excluído'),
  expired('expired', 'Expirado');

  const DocumentStatus(this.value, this.label);

  final String value;
  final String label;

  static DocumentStatus fromString(String value) {
    return values.firstWhere(
      (status) => status.value == value,
      orElse: () => active,
    );
  }

  /// Check if status allows viewing
  bool get allowsViewing {
    return [active, archived].contains(this);
  }

  /// Check if status allows editing
  bool get allowsEditing {
    return this == active;
  }

  /// Check if status allows deletion
  bool get allowsDeletion {
    return [active, archived].contains(this);
  }
}

/// Document Share Permission
class DocumentSharePermission extends Equatable {
  const DocumentSharePermission({
    required this.id,
    required this.documentId,
    required this.sharedWithId,
    required this.sharedWithType,
    required this.sharedWithName,
    required this.permissions,
    required this.createdAt, this.expiresAt,
    this.isActive = true,
  });

  factory DocumentSharePermission.fromJson(Map<String, dynamic> json) {
    return DocumentSharePermission(
      id: json['id'] as String,
      documentId: json['documentId'] as String,
      sharedWithId: json['sharedWithId'] as String,
      sharedWithType: json['sharedWithType'] as String,
      sharedWithName: json['sharedWithName'] as String,
      permissions: (json['permissions'] as List)
          .map((p) => DocumentPermission.fromString(p as String))
          .toList(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
  final String id;
  final String documentId;
  final String sharedWithId;
  final String sharedWithType; // 'user', 'clinic', 'professional'
  final String sharedWithName;
  final List<DocumentPermission> permissions;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'sharedWithId': sharedWithId,
      'sharedWithType': sharedWithType,
      'sharedWithName': sharedWithName,
      'permissions': permissions.map((p) => p.value).toList(),
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Check if permission is expired
  bool get isExpired {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  /// Check if has specific permission
  bool hasPermission(DocumentPermission permission) {
    return permissions.contains(permission);
  }

  @override
  List<Object?> get props => [id, documentId, sharedWithId, permissions];
}

/// Document Permission Types
enum DocumentPermission {
  view('view', 'Visualizar'),
  download('download', 'Download'),
  share('share', 'Compartilhar'),
  edit('edit', 'Editar'),
  delete('delete', 'Excluir');

  const DocumentPermission(this.value, this.label);

  final String value;
  final String label;

  static DocumentPermission fromString(String value) {
    return values.firstWhere(
      (permission) => permission.value == value,
      orElse: () => view,
    );
  }

  /// Get standard permissions for different share types
  static List<DocumentPermission> get viewOnlyPermissions => [view];
  static List<DocumentPermission> get standardPermissions => [view, download];
  static List<DocumentPermission> get fullPermissions => [
    view,
    download,
    share,
  ];
  static List<DocumentPermission> get adminPermissions => values;
}
