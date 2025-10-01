import 'package:equatable/equatable.dart';

/// Trust certification model for credibility and transparency
class TrustCertification extends Equatable {
  const TrustCertification({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.issuingAuthority,
    required this.certificateNumber,
    required this.issuedDate,
    this.expiryDate,
    required this.status,
    required this.logoUrl,
    required this.certificateUrl,
    required this.verificationUrl,
    required this.benefits,
    required this.trustScore,
    required this.metadata,
  });

  factory TrustCertification.fromJson(Map<String, dynamic> json) {
    return TrustCertification(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: CertificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => CertificationType.security,
      ),
      issuingAuthority: json['issuingAuthority'] as String,
      certificateNumber: json['certificateNumber'] as String,
      issuedDate: DateTime.parse(json['issuedDate'] as String),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      status: CertificationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CertificationStatus.active,
      ),
      logoUrl: json['logoUrl'] as String,
      certificateUrl: json['certificateUrl'] as String,
      verificationUrl: json['verificationUrl'] as String,
      benefits: List<String>.from(json['benefits'] as List),
      trustScore: json['trustScore'] as int,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }
  final String id;
  final String name;
  final String description;
  final CertificationType type;
  final String issuingAuthority;
  final String certificateNumber;
  final DateTime issuedDate;
  final DateTime? expiryDate;
  final CertificationStatus status;
  final String logoUrl;
  final String certificateUrl;
  final String verificationUrl;
  final List<String> benefits;
  final int trustScore;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'issuingAuthority': issuingAuthority,
      'certificateNumber': certificateNumber,
      'issuedDate': issuedDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'status': status.name,
      'logoUrl': logoUrl,
      'certificateUrl': certificateUrl,
      'verificationUrl': verificationUrl,
      'benefits': benefits,
      'trustScore': trustScore,
      'metadata': metadata,
    };
  }

  TrustCertification copyWith({
    String? id,
    String? name,
    String? description,
    CertificationType? type,
    String? issuingAuthority,
    String? certificateNumber,
    DateTime? issuedDate,
    DateTime? expiryDate,
    CertificationStatus? status,
    String? logoUrl,
    String? certificateUrl,
    String? verificationUrl,
    List<String>? benefits,
    int? trustScore,
    Map<String, dynamic>? metadata,
  }) {
    return TrustCertification(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      certificateNumber: certificateNumber ?? this.certificateNumber,
      issuedDate: issuedDate ?? this.issuedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      logoUrl: logoUrl ?? this.logoUrl,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      verificationUrl: verificationUrl ?? this.verificationUrl,
      benefits: benefits ?? this.benefits,
      trustScore: trustScore ?? this.trustScore,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    type,
    issuingAuthority,
    certificateNumber,
    issuedDate,
    expiryDate,
    status,
    logoUrl,
    certificateUrl,
    verificationUrl,
    benefits,
    trustScore,
    metadata,
  ];
}

/// Privacy policy model
class PrivacyPolicy extends Equatable {
  const PrivacyPolicy({
    required this.id,
    required this.version,
    required this.effectiveDate,
    required this.title,
    required this.content,
    required this.sections,
    required this.isCurrentVersion,
    this.previousVersionId,
    required this.changes,
    required this.language,
  });

  factory PrivacyPolicy.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicy(
      id: json['id'] as String,
      version: json['version'] as String,
      effectiveDate: DateTime.parse(json['effectiveDate'] as String),
      title: json['title'] as String,
      content: json['content'] as String,
      sections: (json['sections'] as List<dynamic>)
          .map((s) => PolicySection.fromJson(s as Map<String, dynamic>))
          .toList(),
      isCurrentVersion: json['isCurrentVersion'] as bool,
      previousVersionId: json['previousVersionId'] as String?,
      changes: List<String>.from(json['changes'] as List),
      language: json['language'] as String,
    );
  }
  final String id;
  final String version;
  final DateTime effectiveDate;
  final String title;
  final String content;
  final List<PolicySection> sections;
  final bool isCurrentVersion;
  final String? previousVersionId;
  final List<String> changes;
  final String language;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'effectiveDate': effectiveDate.toIso8601String(),
      'title': title,
      'content': content,
      'sections': sections.map((s) => s.toJson()).toList(),
      'isCurrentVersion': isCurrentVersion,
      'previousVersionId': previousVersionId,
      'changes': changes,
      'language': language,
    };
  }

  @override
  List<Object?> get props => [
    id,
    version,
    effectiveDate,
    title,
    content,
    sections,
    isCurrentVersion,
    previousVersionId,
    changes,
    language,
  ];
}

/// Policy section for structured content
class PolicySection extends Equatable {
  const PolicySection({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
    required this.subsections,
  });

  factory PolicySection.fromJson(Map<String, dynamic> json) {
    return PolicySection(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      order: json['order'] as int,
      subsections:
          (json['subsections'] as List<dynamic>?)
              ?.map((s) => PolicySubsection.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
  final String id;
  final String title;
  final String content;
  final int order;
  final List<PolicySubsection> subsections;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'order': order,
      'subsections': subsections.map((s) => s.toJson()).toList(),
    };
  }

  @override
  List<Object> get props => [id, title, content, order, subsections];
}

/// Policy subsection
class PolicySubsection extends Equatable {
  const PolicySubsection({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
  });

  factory PolicySubsection.fromJson(Map<String, dynamic> json) {
    return PolicySubsection(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      order: json['order'] as int,
    );
  }
  final String id;
  final String title;
  final String content;
  final int order;

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'content': content, 'order': order};
  }

  @override
  List<Object> get props => [id, title, content, order];
}

/// LGPD compliance status
class LgpdCompliance extends Equatable {
  const LgpdCompliance({
    required this.isCompliant,
    required this.lastAuditDate,
    this.nextAuditDate,
    required this.complianceScore,
    required this.requirements,
    required this.dataActivities,
    required this.dpoContact,
    required this.userRights,
  });

  factory LgpdCompliance.fromJson(Map<String, dynamic> json) {
    return LgpdCompliance(
      isCompliant: json['isCompliant'] as bool,
      lastAuditDate: DateTime.parse(json['lastAuditDate'] as String),
      nextAuditDate: json['nextAuditDate'] != null
          ? DateTime.parse(json['nextAuditDate'] as String)
          : null,
      complianceScore: json['complianceScore'] as String,
      requirements: (json['requirements'] as List<dynamic>)
          .map((r) => ComplianceItem.fromJson(r as Map<String, dynamic>))
          .toList(),
      dataActivities: (json['dataActivities'] as List<dynamic>)
          .map(
            (a) => DataProcessingActivity.fromJson(a as Map<String, dynamic>),
          )
          .toList(),
      dpoContact: ContactInfo.fromJson(
        json['dpoContact'] as Map<String, dynamic>,
      ),
      userRights: (json['userRights'] as List<dynamic>)
          .map((r) => UserRight.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
  final bool isCompliant;
  final DateTime lastAuditDate;
  final DateTime? nextAuditDate;
  final String complianceScore;
  final List<ComplianceItem> requirements;
  final List<DataProcessingActivity> dataActivities;
  final ContactInfo dpoContact;
  final List<UserRight> userRights;

  Map<String, dynamic> toJson() {
    return {
      'isCompliant': isCompliant,
      'lastAuditDate': lastAuditDate.toIso8601String(),
      'nextAuditDate': nextAuditDate?.toIso8601String(),
      'complianceScore': complianceScore,
      'requirements': requirements.map((r) => r.toJson()).toList(),
      'dataActivities': dataActivities.map((a) => a.toJson()).toList(),
      'dpoContact': dpoContact.toJson(),
      'userRights': userRights.map((r) => r.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    isCompliant,
    lastAuditDate,
    nextAuditDate,
    complianceScore,
    requirements,
    dataActivities,
    dpoContact,
    userRights,
  ];
}

/// Compliance item
class ComplianceItem extends Equatable {
  const ComplianceItem({
    required this.id,
    required this.requirement,
    required this.isCompliant,
    required this.status,
    this.lastChecked,
    this.evidence,
  });

  factory ComplianceItem.fromJson(Map<String, dynamic> json) {
    return ComplianceItem(
      id: json['id'] as String,
      requirement: json['requirement'] as String,
      isCompliant: json['isCompliant'] as bool,
      status: json['status'] as String,
      lastChecked: json['lastChecked'] != null
          ? DateTime.parse(json['lastChecked'] as String)
          : null,
      evidence: json['evidence'] as String?,
    );
  }
  final String id;
  final String requirement;
  final bool isCompliant;
  final String status;
  final DateTime? lastChecked;
  final String? evidence;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requirement': requirement,
      'isCompliant': isCompliant,
      'status': status,
      'lastChecked': lastChecked?.toIso8601String(),
      'evidence': evidence,
    };
  }

  @override
  List<Object?> get props => [
    id,
    requirement,
    isCompliant,
    status,
    lastChecked,
    evidence,
  ];
}

/// Data processing activity
class DataProcessingActivity extends Equatable {
  const DataProcessingActivity({
    required this.id,
    required this.purpose,
    required this.dataTypes,
    required this.legalBasis,
    required this.retention,
    required this.recipients,
    required this.isTransferredAbroad,
  });

  factory DataProcessingActivity.fromJson(Map<String, dynamic> json) {
    return DataProcessingActivity(
      id: json['id'] as String,
      purpose: json['purpose'] as String,
      dataTypes: List<String>.from(json['dataTypes'] as List),
      legalBasis: json['legalBasis'] as String,
      retention: json['retention'] as String,
      recipients: List<String>.from(json['recipients'] as List),
      isTransferredAbroad: json['isTransferredAbroad'] as bool,
    );
  }
  final String id;
  final String purpose;
  final List<String> dataTypes;
  final String legalBasis;
  final String retention;
  final List<String> recipients;
  final bool isTransferredAbroad;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purpose': purpose,
      'dataTypes': dataTypes,
      'legalBasis': legalBasis,
      'retention': retention,
      'recipients': recipients,
      'isTransferredAbroad': isTransferredAbroad,
    };
  }

  @override
  List<Object> get props => [
    id,
    purpose,
    dataTypes,
    legalBasis,
    retention,
    recipients,
    isTransferredAbroad,
  ];
}

/// Contact information
class ContactInfo extends Equatable {
  const ContactInfo({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      role: json['role'] as String,
    );
  }
  final String name;
  final String email;
  final String phone;
  final String address;
  final String role;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role,
    };
  }

  @override
  List<Object> get props => [name, email, phone, address, role];
}

/// User right under LGPD
class UserRight extends Equatable {
  const UserRight({
    required this.id,
    required this.right,
    required this.description,
    required this.howToExercise,
    required this.isAvailable,
  });

  factory UserRight.fromJson(Map<String, dynamic> json) {
    return UserRight(
      id: json['id'] as String,
      right: json['right'] as String,
      description: json['description'] as String,
      howToExercise: json['howToExercise'] as String,
      isAvailable: json['isAvailable'] as bool,
    );
  }
  final String id;
  final String right;
  final String description;
  final String howToExercise;
  final bool isAvailable;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'right': right,
      'description': description,
      'howToExercise': howToExercise,
      'isAvailable': isAvailable,
    };
  }

  @override
  List<Object> get props => [
    id,
    right,
    description,
    howToExercise,
    isAvailable,
  ];
}

/// Security audit report
class SecurityAudit extends Equatable {
  const SecurityAudit({
    required this.id,
    required this.auditDate,
    required this.auditor,
    required this.overallScore,
    required this.findings,
    required this.recommendations,
    this.nextAuditDate,
    required this.isPublic,
  });

  factory SecurityAudit.fromJson(Map<String, dynamic> json) {
    return SecurityAudit(
      id: json['id'] as String,
      auditDate: DateTime.parse(json['auditDate'] as String),
      auditor: json['auditor'] as String,
      overallScore: json['overallScore'] as String,
      findings: (json['findings'] as List<dynamic>)
          .map((f) => SecurityFinding.fromJson(f as Map<String, dynamic>))
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>)
          .map(
            (r) => SecurityRecommendation.fromJson(r as Map<String, dynamic>),
          )
          .toList(),
      nextAuditDate: json['nextAuditDate'] != null
          ? DateTime.parse(json['nextAuditDate'] as String)
          : null,
      isPublic: json['isPublic'] as bool,
    );
  }
  final String id;
  final DateTime auditDate;
  final String auditor;
  final String overallScore;
  final List<SecurityFinding> findings;
  final List<SecurityRecommendation> recommendations;
  final DateTime? nextAuditDate;
  final bool isPublic;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auditDate': auditDate.toIso8601String(),
      'auditor': auditor,
      'overallScore': overallScore,
      'findings': findings.map((f) => f.toJson()).toList(),
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'nextAuditDate': nextAuditDate?.toIso8601String(),
      'isPublic': isPublic,
    };
  }

  @override
  List<Object?> get props => [
    id,
    auditDate,
    auditor,
    overallScore,
    findings,
    recommendations,
    nextAuditDate,
    isPublic,
  ];
}

/// Security finding
class SecurityFinding extends Equatable {
  const SecurityFinding({
    required this.category,
    required this.finding,
    required this.severity,
    required this.isResolved,
  });

  factory SecurityFinding.fromJson(Map<String, dynamic> json) {
    return SecurityFinding(
      category: json['category'] as String,
      finding: json['finding'] as String,
      severity: json['severity'] as String,
      isResolved: json['isResolved'] as bool,
    );
  }
  final String category;
  final String finding;
  final String severity;
  final bool isResolved;

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'finding': finding,
      'severity': severity,
      'isResolved': isResolved,
    };
  }

  @override
  List<Object> get props => [category, finding, severity, isResolved];
}

/// Security recommendation
class SecurityRecommendation extends Equatable {
  const SecurityRecommendation({
    required this.recommendation,
    required this.priority,
    required this.isImplemented,
  });

  factory SecurityRecommendation.fromJson(Map<String, dynamic> json) {
    return SecurityRecommendation(
      recommendation: json['recommendation'] as String,
      priority: json['priority'] as String,
      isImplemented: json['isImplemented'] as bool,
    );
  }
  final String recommendation;
  final String priority;
  final bool isImplemented;

  Map<String, dynamic> toJson() {
    return {
      'recommendation': recommendation,
      'priority': priority,
      'isImplemented': isImplemented,
    };
  }

  @override
  List<Object> get props => [recommendation, priority, isImplemented];
}

/// Trust metrics
class TrustMetrics extends Equatable {
  const TrustMetrics({
    required this.overallTrustScore,
    required this.categoryScores,
    required this.certifications,
    required this.lastUpdated,
    required this.userReviews,
    required this.avgRating,
    required this.resolvedComplaints,
    required this.totalComplaints,
  });

  factory TrustMetrics.fromJson(Map<String, dynamic> json) {
    return TrustMetrics(
      overallTrustScore: json['overallTrustScore'] as int,
      categoryScores: Map<String, int>.from(json['categoryScores'] as Map),
      certifications: (json['certifications'] as List<dynamic>)
          .map((c) => TrustCertification.fromJson(c as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      userReviews: json['userReviews'] as int,
      avgRating: (json['avgRating'] as num).toDouble(),
      resolvedComplaints: json['resolvedComplaints'] as int,
      totalComplaints: json['totalComplaints'] as int,
    );
  }
  final int overallTrustScore;
  final Map<String, int> categoryScores;
  final List<TrustCertification> certifications;
  final DateTime lastUpdated;
  final int userReviews;
  final double avgRating;
  final int resolvedComplaints;
  final int totalComplaints;

  Map<String, dynamic> toJson() {
    return {
      'overallTrustScore': overallTrustScore,
      'categoryScores': categoryScores,
      'certifications': certifications.map((c) => c.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'userReviews': userReviews,
      'avgRating': avgRating,
      'resolvedComplaints': resolvedComplaints,
      'totalComplaints': totalComplaints,
    };
  }

  @override
  List<Object> get props => [
    overallTrustScore,
    categoryScores,
    certifications,
    lastUpdated,
    userReviews,
    avgRating,
    resolvedComplaints,
    totalComplaints,
  ];
}

/// Enums for trust system
enum CertificationType {
  security,
  privacy,
  quality,
  medical,
  regulatory,
  industry,
  compliance,
  audit,
}

enum CertificationStatus { active, expired, suspended, revoked, pending }
