import 'package:flutter/material.dart';
import '../controllers/appointment_details_controller.dart';
import '../../../core/constants/app_colors.dart';

/// Status Timeline Widget
/// Displays appointment status timeline with visual indicators
class StatusTimeline extends StatelessWidget {
  final List<TimelineEvent> events;

  const StatusTimeline({
    Key? key,
    required this.events,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: events.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        final isLast = index == events.length - 1;
        
        return _buildTimelineItem(event, isLast);
      }).toList(),
    );
  }

  Widget _buildTimelineItem(TimelineEvent event, bool isLast) {
    final statusColor = Color(int.parse(event.status.color.substring(1), radix: 16) + 0xFF000000);
    final icon = _getIconData(event.icon);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: event.status == TimelineEventStatus.current 
                      ? statusColor 
                      : statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor,
                    width: event.status == TimelineEventStatus.current ? 0 : 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: event.status == TimelineEventStatus.current 
                      ? Colors.white 
                      : statusColor,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 50,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.formattedTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'add_circle':
        return Icons.add_circle;
      case 'schedule':
        return Icons.schedule;
      case 'check_circle':
        return Icons.check_circle;
      case 'how_to_reg':
        return Icons.how_to_reg;
      case 'medical_services':
        return Icons.medical_services;
      case 'check_circle_outline':
        return Icons.check_circle_outline;
      case 'cancel':
        return Icons.cancel;
      case 'person_off':
        return Icons.person_off;
      case 'event_busy':
        return Icons.event_busy;
      case 'description':
        return Icons.description;
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.circle;
    }
  }
}