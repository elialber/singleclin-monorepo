import 'package:singleclin_mobile/domain/entities/user_entity.dart';

/// User model in the data layer with offline-first capabilities
class UserModel extends UserEntity {
  // Offline-specific fields
  final DateTime? lastSyncAt;
  final bool isLocalOnly; // True if created offline and not synced yet
  final int syncVersion; // For conflict resolution
  final UserPreferences? preferences;

  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.displayName,
    super.phoneNumber,
    super.photoUrl,
    super.isEmailVerified,
    this.lastSyncAt,
    this.isLocalOnly = false,
    this.syncVersion = 1,
    this.preferences,
  });

  /// Create UserModel from UserEntity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      phoneNumber: entity.phoneNumber,
      photoUrl: entity.photoUrl,
      role: entity.role,
      isActive: entity.isActive,
      isEmailVerified: entity.isEmailVerified,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      // Initialize offline fields with defaults
      lastSyncAt: DateTime.now(),
      isLocalOnly: false,
      syncVersion: 1,
    );
  }

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      photoUrl: json['photoUrl'] as String?,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      // Handle offline-specific fields
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.parse(json['lastSyncAt'] as String)
          : null,
      isLocalOnly: json['isLocalOnly'] as bool? ?? false,
      syncVersion: json['syncVersion'] as int? ?? 1,
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'role': role,
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // Include offline-specific fields
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'isLocalOnly': isLocalOnly,
      'syncVersion': syncVersion,
      'preferences': preferences?.toJson(),
    };
  }

  /// Create a copy with updated fields (for offline operations)
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    String? role,
    bool? isActive,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncAt,
    bool? isLocalOnly,
    int? syncVersion,
    UserPreferences? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
      syncVersion: syncVersion ?? this.syncVersion,
      preferences: preferences ?? this.preferences,
    );
  }

  /// Mark as synced with server
  UserModel markAsSynced() {
    return copyWith(
      lastSyncAt: DateTime.now(),
      isLocalOnly: false,
    );
  }

  /// Increment sync version for conflict resolution
  UserModel incrementSyncVersion() {
    return copyWith(syncVersion: syncVersion + 1);
  }

  /// Check if user data needs sync
  bool get needsSync => isLocalOnly ||
      (lastSyncAt != null && updatedAt.isAfter(lastSyncAt!));
}

/// User preferences for offline functionality and app behavior
class UserPreferences {
  final bool offlineMode;
  final bool autoSync;
  final bool wifiOnlySync;
  final String language;
  final String theme;
  final bool notificationsEnabled;
  final bool locationEnabled;
  final Map<String, dynamic> customSettings;

  const UserPreferences({
    this.offlineMode = false,
    this.autoSync = true,
    this.wifiOnlySync = true,
    this.language = 'pt-BR',
    this.theme = 'light',
    this.notificationsEnabled = true,
    this.locationEnabled = false,
    this.customSettings = const {},
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      offlineMode: json['offlineMode'] as bool? ?? false,
      autoSync: json['autoSync'] as bool? ?? true,
      wifiOnlySync: json['wifiOnlySync'] as bool? ?? true,
      language: json['language'] as String? ?? 'pt-BR',
      theme: json['theme'] as String? ?? 'light',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      locationEnabled: json['locationEnabled'] as bool? ?? false,
      customSettings: json['customSettings'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offlineMode': offlineMode,
      'autoSync': autoSync,
      'wifiOnlySync': wifiOnlySync,
      'language': language,
      'theme': theme,
      'notificationsEnabled': notificationsEnabled,
      'locationEnabled': locationEnabled,
      'customSettings': customSettings,
    };
  }

  UserPreferences copyWith({
    bool? offlineMode,
    bool? autoSync,
    bool? wifiOnlySync,
    String? language,
    String? theme,
    bool? notificationsEnabled,
    bool? locationEnabled,
    Map<String, dynamic>? customSettings,
  }) {
    return UserPreferences(
      offlineMode: offlineMode ?? this.offlineMode,
      autoSync: autoSync ?? this.autoSync,
      wifiOnlySync: wifiOnlySync ?? this.wifiOnlySync,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}
