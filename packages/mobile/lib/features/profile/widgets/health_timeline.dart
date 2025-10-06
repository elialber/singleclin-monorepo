import 'package:flutter/material.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';
import 'package:singleclin_mobile/features/profile/models/health_record.dart';

/// Health Timeline Widget
/// Displays a health record in timeline format
class HealthTimeline extends StatelessWidget {
  const HealthTimeline({
    required this.record, super.key,
    this.onTap,
    this.onEdit,
    this.onArchive,
    this.onDelete,
  });
  final HealthRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final recordType = HealthRecordType.fromString(record.type);
    final typeColor = Color(
      int.parse(recordType.color.substring(1), radix: 16) + 0xFF000000,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(recordType, typeColor),
              const SizedBox(height: 12),
              _buildContent(),
              if (record.hasAttachments ||
                  record.recommendations.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildMetadata(),
              ],
              if (_hasActions()) ...[
                const SizedBox(height: 12),
                _buildActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build record header
  Widget _buildHeader(HealthRecordType recordType, Color typeColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconData(recordType.icon),
            color: typeColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    recordType.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: typeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '•',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    record.formattedDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              record.timeAgo,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            if (record.isImportant) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'IMPORTANTE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Build record content
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (record.description.isNotEmpty) ...[
          Text(
            record.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (record.clinicName != null || record.professionalName != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (record.clinicName != null) ...[
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.mediumGrey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    record.clinicName!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              if (record.professionalName != null) ...[
                if (record.clinicName != null) const SizedBox(width: 12),
                const Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.mediumGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  record.professionalName!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  /// Build metadata section
  Widget _buildMetadata() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (record.hasAttachments) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.attach_file, size: 14, color: AppColors.info),
                const SizedBox(width: 4),
                Text(
                  '${record.totalAttachments} anexo${record.totalAttachments > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (record.recommendations.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: AppColors.success,
                ),
                SizedBox(width: 4),
                Text(
                  'Recomendações',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (record.hasFollowUp) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: record.isFollowUpDue
                  ? AppColors.warning.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  record.isFollowUpDue
                      ? Icons.notification_important
                      : Icons.event,
                  size: 14,
                  color: record.isFollowUpDue
                      ? AppColors.warning
                      : AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  record.isFollowUpDue ? 'Retorno vencido' : 'Retorno agendado',
                  style: TextStyle(
                    fontSize: 11,
                    color: record.isFollowUpDue
                        ? AppColors.warning
                        : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        ...record.tags.map(
          (tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build action buttons
  Widget _buildActions() {
    return Row(
      children: [
        if (onEdit != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Editar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
        if (onEdit != null && (onArchive != null || onDelete != null)) ...[
          const SizedBox(width: 8),
        ],
        if (onArchive != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onArchive,
              icon: const Icon(Icons.archive_outlined, size: 16),
              label: const Text('Arquivar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
        if (onDelete != null && onArchive == null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Excluir'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Check if has actions
  bool _hasActions() {
    return onEdit != null || onArchive != null || onDelete != null;
  }

  /// Get icon data from string
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'medical_services':
        return Icons.medical_services;
      case 'biotech':
        return Icons.biotech;
      case 'healing':
        return Icons.healing;
      case 'vaccines':
        return Icons.vaccines;
      case 'medication':
        return Icons.medication;
      case 'warning':
        return Icons.warning;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'psychology':
        return Icons.psychology;
      case 'restaurant':
        return Icons.restaurant;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'mood':
        return Icons.mood;
      case 'monitor_heart':
        return Icons.monitor_heart;
      case 'emergency':
        return Icons.emergency;
      case 'event_repeat':
        return Icons.event_repeat;
      default:
        return Icons.description;
    }
  }
}
