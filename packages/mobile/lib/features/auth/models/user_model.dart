class UserModel {
  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.sgCredits, required this.isActive, required this.createdAt, required this.updatedAt, this.phone,
    this.profileImageUrl,
    this.birthDate,
    this.address,
    this.emergencyContact,
    this.creditsRenewDate,
    this.subscription,
    this.preferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'],
      profileImageUrl: json['profileImageUrl'],
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'])
          : null,
      address: json['address'],
      emergencyContact: json['emergencyContact'],
      sgCredits: json['sgCredits'] ?? 0,
      creditsRenewDate: json['creditsRenewDate'] != null
          ? DateTime.parse(json['creditsRenewDate'])
          : null,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      subscription: json['subscription'] != null
          ? UserSubscription.fromJson(json['subscription'])
          : null,
      preferences: json['preferences'] != null
          ? List<String>.from(json['preferences'])
          : null,
    );
  }
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? profileImageUrl;
  final DateTime? birthDate;
  final String? address;
  final String? emergencyContact;
  final int sgCredits;
  final DateTime? creditsRenewDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserSubscription? subscription;
  final List<String>? preferences;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'birthDate': birthDate?.toIso8601String(),
      'address': address,
      'emergencyContact': emergencyContact,
      'sgCredits': sgCredits,
      'creditsRenewDate': creditsRenewDate?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'subscription': subscription?.toJson(),
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? profileImageUrl,
    DateTime? birthDate,
    String? address,
    String? emergencyContact,
    int? sgCredits,
    DateTime? creditsRenewDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserSubscription? subscription,
    List<String>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      sgCredits: sgCredits ?? this.sgCredits,
      creditsRenewDate: creditsRenewDate ?? this.creditsRenewDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subscription: subscription ?? this.subscription,
      preferences: preferences ?? this.preferences,
    );
  }
}

class UserSubscription {
  UserSubscription({
    required this.id,
    required this.planId,
    required this.planName,
    required this.monthlyCredits,
    required this.monthlyPrice,
    required this.startDate,
    required this.isActive, required this.status, this.endDate,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] ?? '',
      planId: json['planId'] ?? '',
      planName: json['planName'] ?? '',
      monthlyCredits: json['monthlyCredits'] ?? 0,
      monthlyPrice: (json['monthlyPrice'] ?? 0.0).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'] ?? false,
      status: json['status'] ?? '',
    );
  }
  final String id;
  final String planId;
  final String planName;
  final int monthlyCredits;
  final double monthlyPrice;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String status;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planId': planId,
      'planName': planName,
      'monthlyCredits': monthlyCredits,
      'monthlyPrice': monthlyPrice,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'status': status,
    };
  }
}
