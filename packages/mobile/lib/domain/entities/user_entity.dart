import 'package:equatable/equatable.dart';

/// User entity in the domain layer
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final String role;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.photoUrl,
    required this.role,
    required this.isActive,
    this.isEmailVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        phoneNumber,
        photoUrl,
        role,
        isActive,
        isEmailVerified,
        createdAt,
        updatedAt,
      ];
}