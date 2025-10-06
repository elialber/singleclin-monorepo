import 'package:equatable/equatable.dart';

/// User Profile Model
/// Comprehensive user profile with health information and LGPD compliance
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    required this.personalInfo,
    required this.healthInfo,
    required this.contactInfo,
    required this.privacySettings,
    required this.notificationSettings,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.emergencyContacts = const [],
    this.allergies = const [],
    this.medications = const [],
    this.healthConditions = const [],
    this.additionalData,
    this.lastLoginAt,
    this.isActive = true,
    this.isVerified = false,
    this.hasCompletedOnboarding = false,
    this.preferredLanguage = 'pt_BR',
    this.timezone = 'America/Sao_Paulo',
  });

  /// Factory method to create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      personalInfo: PersonalInfo.fromJson(
        json['personalInfo'] as Map<String, dynamic>,
      ),
      healthInfo: HealthInfo.fromJson(
        json['healthInfo'] as Map<String, dynamic>,
      ),
      contactInfo: ContactInfo.fromJson(
        json['contactInfo'] as Map<String, dynamic>,
      ),
      privacySettings: PrivacySettings.fromJson(
        json['privacySettings'] as Map<String, dynamic>,
      ),
      notificationSettings: NotificationSettings.fromJson(
        json['notificationSettings'] as Map<String, dynamic>,
      ),
      emergencyContacts: List<String>.from(
        json['emergencyContacts'] as List? ?? [],
      ),
      allergies: List<String>.from(json['allergies'] as List? ?? []),
      medications: List<String>.from(json['medications'] as List? ?? []),
      healthConditions: List<String>.from(
        json['healthConditions'] as List? ?? [],
      ),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'pt_BR',
      timezone: json['timezone'] as String? ?? 'America/Sao_Paulo',
    );
  }
  final String id;
  final String email;
  final String? photoUrl;
  final PersonalInfo personalInfo;
  final HealthInfo healthInfo;
  final ContactInfo contactInfo;
  final PrivacySettings privacySettings;
  final NotificationSettings notificationSettings;
  final List<String> emergencyContacts;
  final List<String> allergies;
  final List<String> medications;
  final List<String> healthConditions;
  final Map<String, dynamic>? additionalData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final bool isVerified;
  final bool hasCompletedOnboarding;
  final String? preferredLanguage;
  final String? timezone;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'photoUrl': photoUrl,
      'personalInfo': personalInfo.toJson(),
      'healthInfo': healthInfo.toJson(),
      'contactInfo': contactInfo.toJson(),
      'privacySettings': privacySettings.toJson(),
      'notificationSettings': notificationSettings.toJson(),
      'emergencyContacts': emergencyContacts,
      'allergies': allergies,
      'medications': medications,
      'healthConditions': healthConditions,
      'additionalData': additionalData,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
      'isVerified': isVerified,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'preferredLanguage': preferredLanguage,
      'timezone': timezone,
    };
  }

  /// Create a copy with updated values
  UserProfile copyWith({
    String? id,
    String? email,
    String? photoUrl,
    PersonalInfo? personalInfo,
    HealthInfo? healthInfo,
    ContactInfo? contactInfo,
    PrivacySettings? privacySettings,
    NotificationSettings? notificationSettings,
    List<String>? emergencyContacts,
    List<String>? allergies,
    List<String>? medications,
    List<String>? healthConditions,
    Map<String, dynamic>? additionalData,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isActive,
    bool? isVerified,
    bool? hasCompletedOnboarding,
    String? preferredLanguage,
    String? timezone,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      personalInfo: personalInfo ?? this.personalInfo,
      healthInfo: healthInfo ?? this.healthInfo,
      contactInfo: contactInfo ?? this.contactInfo,
      privacySettings: privacySettings ?? this.privacySettings,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      healthConditions: healthConditions ?? this.healthConditions,
      additionalData: additionalData ?? this.additionalData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      timezone: timezone ?? this.timezone,
    );
  }

  /// Get display name
  String get displayName {
    if (personalInfo.fullName.isNotEmpty) {
      return personalInfo.fullName;
    }
    return email.split('@').first;
  }

  /// Get initials for avatar
  String get initials {
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  }

  /// Check if profile is complete
  bool get isProfileComplete {
    return personalInfo.isComplete &&
        healthInfo.isComplete &&
        contactInfo.isComplete &&
        hasCompletedOnboarding;
  }

  /// Get completion percentage
  double get completionPercentage {
    int completedFields = 0;
    int totalFields = 0;

    // Personal Info (5 fields)
    totalFields += 5;
    if (personalInfo.fullName.isNotEmpty) completedFields++;
    if (personalInfo.birthDate != null) completedFields++;
    if (personalInfo.gender.isNotEmpty) completedFields++;
    if (personalInfo.cpf.isNotEmpty) completedFields++;
    if (personalInfo.rg.isNotEmpty) completedFields++;

    // Health Info (4 fields)
    totalFields += 4;
    if (healthInfo.bloodType.isNotEmpty) completedFields++;
    if (healthInfo.weight != null) completedFields++;
    if (healthInfo.height != null) completedFields++;
    if (allergies.isNotEmpty) completedFields++;

    // Contact Info (3 fields)
    totalFields += 3;
    if (contactInfo.phone.isNotEmpty) completedFields++;
    if (contactInfo.address != null) completedFields++;
    if (emergencyContacts.isNotEmpty) completedFields++;

    // Photo
    totalFields += 1;
    if (photoUrl?.isNotEmpty ?? false) completedFields++;

    return completedFields / totalFields;
  }

  @override
  List<Object?> get props => [
    id,
    email,
    personalInfo,
    healthInfo,
    contactInfo,
    updatedAt,
  ];

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, name: ${personalInfo.fullName})';
  }
}

/// Personal Information
class PersonalInfo extends Equatable {
  const PersonalInfo({
    this.fullName = '',
    this.birthDate,
    this.gender = '',
    this.cpf = '',
    this.rg = '',
    this.occupation,
    this.maritalStatus,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      fullName: json['fullName'] as String? ?? '',
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      gender: json['gender'] as String? ?? '',
      cpf: json['cpf'] as String? ?? '',
      rg: json['rg'] as String? ?? '',
      occupation: json['occupation'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
    );
  }
  final String fullName;
  final DateTime? birthDate;
  final String gender;
  final String cpf;
  final String rg;
  final String? occupation;
  final String? maritalStatus;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'cpf': cpf,
      'rg': rg,
      'occupation': occupation,
      'maritalStatus': maritalStatus,
    };
  }

  PersonalInfo copyWith({
    String? fullName,
    DateTime? birthDate,
    String? gender,
    String? cpf,
    String? rg,
    String? occupation,
    String? maritalStatus,
  }) {
    return PersonalInfo(
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      cpf: cpf ?? this.cpf,
      rg: rg ?? this.rg,
      occupation: occupation ?? this.occupation,
      maritalStatus: maritalStatus ?? this.maritalStatus,
    );
  }

  /// Calculate age from birth date
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// Check if personal info is complete
  bool get isComplete {
    return fullName.isNotEmpty &&
        birthDate != null &&
        gender.isNotEmpty &&
        cpf.isNotEmpty;
  }

  @override
  List<Object?> get props => [fullName, birthDate, gender, cpf, rg];
}

/// Health Information
class HealthInfo extends Equatable {
  const HealthInfo({
    this.bloodType = '',
    this.weight,
    this.height,
    this.insuranceProvider,
    this.insuranceNumber,
    this.primaryDoctor,
    this.primaryDoctorPhone,
  });

  factory HealthInfo.fromJson(Map<String, dynamic> json) {
    return HealthInfo(
      bloodType: json['bloodType'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      insuranceProvider: json['insuranceProvider'] as String?,
      insuranceNumber: json['insuranceNumber'] as String?,
      primaryDoctor: json['primaryDoctor'] as String?,
      primaryDoctorPhone: json['primaryDoctorPhone'] as String?,
    );
  }
  final String bloodType;
  final double? weight;
  final double? height;
  final String? insuranceProvider;
  final String? insuranceNumber;
  final String? primaryDoctor;
  final String? primaryDoctorPhone;

  Map<String, dynamic> toJson() {
    return {
      'bloodType': bloodType,
      'weight': weight,
      'height': height,
      'insuranceProvider': insuranceProvider,
      'insuranceNumber': insuranceNumber,
      'primaryDoctor': primaryDoctor,
      'primaryDoctorPhone': primaryDoctorPhone,
    };
  }

  HealthInfo copyWith({
    String? bloodType,
    double? weight,
    double? height,
    String? insuranceProvider,
    String? insuranceNumber,
    String? primaryDoctor,
    String? primaryDoctorPhone,
  }) {
    return HealthInfo(
      bloodType: bloodType ?? this.bloodType,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      primaryDoctor: primaryDoctor ?? this.primaryDoctor,
      primaryDoctorPhone: primaryDoctorPhone ?? this.primaryDoctorPhone,
    );
  }

  /// Calculate BMI
  double? get bmi {
    if (weight == null || height == null || height! <= 0) return null;
    return weight! / ((height! / 100) * (height! / 100));
  }

  /// Get BMI category
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return '';

    if (bmiValue < 18.5) return 'Abaixo do peso';
    if (bmiValue < 25) return 'Peso normal';
    if (bmiValue < 30) return 'Sobrepeso';
    return 'Obesidade';
  }

  /// Check if health info is complete
  bool get isComplete {
    return bloodType.isNotEmpty;
  }

  @override
  List<Object?> get props => [bloodType, weight, height, insuranceProvider];
}

/// Contact Information
class ContactInfo extends Equatable {
  const ContactInfo({this.phone = '', this.whatsapp, this.address});

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      phone: json['phone'] as String? ?? '',
      whatsapp: json['whatsapp'] as String?,
      address: json['address'] != null
          ? Address.fromJson(json['address'] as Map<String, dynamic>)
          : null,
    );
  }
  final String phone;
  final String? whatsapp;
  final Address? address;

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'whatsapp': whatsapp, 'address': address?.toJson()};
  }

  ContactInfo copyWith({String? phone, String? whatsapp, Address? address}) {
    return ContactInfo(
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      address: address ?? this.address,
    );
  }

  /// Check if contact info is complete
  bool get isComplete {
    return phone.isNotEmpty;
  }

  @override
  List<Object?> get props => [phone, whatsapp, address];
}

/// Address Information
class Address extends Equatable {
  const Address({
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
    this.complement,
    this.country = 'Brasil',
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String,
      number: json['number'] as String,
      complement: json['complement'] as String?,
      neighborhood: json['neighborhood'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      country: json['country'] as String? ?? 'Brasil',
    );
  }
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String zipCode;
  final String? country;

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'number': number,
      'complement': complement,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }

  /// Get formatted address string
  String get formattedAddress {
    final buffer = StringBuffer();
    buffer.write('$street, $number');
    if (complement?.isNotEmpty ?? false) {
      buffer.write(' - $complement');
    }
    buffer.write('\n$neighborhood, $city - $state\nCEP: $zipCode');
    return buffer.toString();
  }

  @override
  List<Object?> get props => [
    street,
    number,
    neighborhood,
    city,
    state,
    zipCode,
  ];
}

/// Privacy Settings for LGPD compliance
class PrivacySettings extends Equatable {
  const PrivacySettings({
    this.dataProcessingConsent = false,
    this.marketingConsent = false,
    this.analyticsConsent = false,
    this.sharingConsent = false,
    this.consentDate,
    this.allowDataExport = true,
    this.allowDataDeletion = true,
    this.dataProcessingPurposes = const [],
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      dataProcessingConsent: json['dataProcessingConsent'] as bool? ?? false,
      marketingConsent: json['marketingConsent'] as bool? ?? false,
      analyticsConsent: json['analyticsConsent'] as bool? ?? false,
      sharingConsent: json['sharingConsent'] as bool? ?? false,
      consentDate: json['consentDate'] != null
          ? DateTime.parse(json['consentDate'] as String)
          : null,
      allowDataExport: json['allowDataExport'] as bool? ?? true,
      allowDataDeletion: json['allowDataDeletion'] as bool? ?? true,
      dataProcessingPurposes: List<String>.from(
        json['dataProcessingPurposes'] as List? ?? [],
      ),
    );
  }
  final bool dataProcessingConsent;
  final bool marketingConsent;
  final bool analyticsConsent;
  final bool sharingConsent;
  final DateTime? consentDate;
  final bool allowDataExport;
  final bool allowDataDeletion;
  final List<String> dataProcessingPurposes;

  Map<String, dynamic> toJson() {
    return {
      'dataProcessingConsent': dataProcessingConsent,
      'marketingConsent': marketingConsent,
      'analyticsConsent': analyticsConsent,
      'sharingConsent': sharingConsent,
      'consentDate': consentDate?.toIso8601String(),
      'allowDataExport': allowDataExport,
      'allowDataDeletion': allowDataDeletion,
      'dataProcessingPurposes': dataProcessingPurposes,
    };
  }

  @override
  List<Object?> get props => [
    dataProcessingConsent,
    marketingConsent,
    analyticsConsent,
    sharingConsent,
    consentDate,
  ];
}

/// Notification Settings
class NotificationSettings extends Equatable {
  const NotificationSettings({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.appointmentReminders = true,
    this.promotionalNotifications = false,
    this.healthTips = true,
    this.reminderHoursBefore = 24,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      smsNotifications: json['smsNotifications'] as bool? ?? false,
      appointmentReminders: json['appointmentReminders'] as bool? ?? true,
      promotionalNotifications:
          json['promotionalNotifications'] as bool? ?? false,
      healthTips: json['healthTips'] as bool? ?? true,
      reminderHoursBefore: json['reminderHoursBefore'] as int? ?? 24,
    );
  }
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool appointmentReminders;
  final bool promotionalNotifications;
  final bool healthTips;
  final int reminderHoursBefore;

  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'appointmentReminders': appointmentReminders,
      'promotionalNotifications': promotionalNotifications,
      'healthTips': healthTips,
      'reminderHoursBefore': reminderHoursBefore,
    };
  }

  @override
  List<Object?> get props => [
    pushNotifications,
    emailNotifications,
    appointmentReminders,
    reminderHoursBefore,
  ];
}
