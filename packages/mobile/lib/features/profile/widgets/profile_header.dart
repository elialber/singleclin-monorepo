import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../../../core/constants/app_colors.dart';

/// Profile Header Widget
/// Displays user photo, name, and completion progress
class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final bool isEditing;
  final bool isUpdatingPhoto;
  final VoidCallback? onPhotoUpdate;
  final VoidCallback? onPhotoRemove;

  const ProfileHeader({
    Key? key,
    required this.profile,
    this.isEditing = false,
    this.isUpdatingPhoto = false,
    this.onPhotoUpdate,
    this.onPhotoRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.1),
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildProfilePhoto(),
          const SizedBox(height: 16),
          _buildUserInfo(),
          const SizedBox(height: 16),
          _buildCompletionProgress(),
        ],
      ),
    );
  }

  /// Build profile photo with edit functionality
  Widget _buildProfilePhoto() {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: profile.photoUrl?.isNotEmpty == true
                ? Image.network(
                    profile.photoUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar();
                    },
                  )
                : _buildDefaultAvatar(),
          ),
        ),
        if (isEditing) ...[
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'update':
                      onPhotoUpdate?.call();
                      break;
                    case 'remove':
                      onPhotoRemove?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'update',
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt, size: 18),
                        SizedBox(width: 8),
                        Text('Alterar Foto'),
                      ],
                    ),
                  ),
                  if (profile.photoUrl?.isNotEmpty == true) ...[
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18),
                          SizedBox(width: 8),
                          Text('Remover Foto'),
                        ],
                      ),
                    ),
                  ],
                ],
                icon: isUpdatingPhoto
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                offset: const Offset(0, 30),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build default avatar with initials
  Widget _buildDefaultAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          profile.initials,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Build user information
  Widget _buildUserInfo() {
    return Column(
      children: [
        Text(
          profile.displayName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInfoBadge(
              icon: Icons.verified,
              text: profile.isVerified ? 'Verificado' : 'Não Verificado',
              color: profile.isVerified ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: 12),
            _buildInfoBadge(
              icon: Icons.schedule,
              text: 'Membro desde ${profile.createdAt.year}',
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  /// Build info badge
  Widget _buildInfoBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build completion progress
  Widget _buildCompletionProgress() {
    final completionPercentage = profile.completionPercentage;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Completude do Perfil',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${(completionPercentage * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completionPercentage,
              backgroundColor: AppColors.lightGrey,
              valueColor: AlwaysStoppedAnimation(
                completionPercentage >= 0.8 
                    ? AppColors.success 
                    : completionPercentage >= 0.5 
                        ? AppColors.warning 
                        : AppColors.error,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getCompletionMessage(completionPercentage),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Get completion message based on percentage
  String _getCompletionMessage(double percentage) {
    if (percentage >= 0.9) {
      return 'Perfil completo! Você tem acesso a todos os recursos.';
    } else if (percentage >= 0.7) {
      return 'Quase lá! Complete algumas informações para ter acesso total.';
    } else if (percentage >= 0.5) {
      return 'Adicione mais informações para melhorar sua experiência.';
    } else {
      return 'Complete seu perfil para aproveitar todos os recursos do app.';
    }
  }
}