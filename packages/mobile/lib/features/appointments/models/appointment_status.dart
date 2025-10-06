import 'package:flutter/material.dart';

/// Appointment Status Enum
/// Defines all possible states of a medical appointment
enum AppointmentStatus {
  /// Appointment has been created but not confirmed by clinic
  pending(
    'pending',
    'Pendente',
    'Em análise pela clínica',
    '#FF9800',
    Icons.schedule,
  ),

  /// Appointment confirmed by clinic
  confirmed(
    'confirmed',
    'Confirmado',
    'Confirmado pela clínica',
    '#4CAF50',
    Icons.check_circle,
  ),

  /// Patient has checked in for appointment
  checkedIn(
    'checked_in',
    'Check-in',
    'Check-in realizado',
    '#2196F3',
    Icons.how_to_reg,
  ),

  /// Appointment is in progress
  inProgress(
    'in_progress',
    'Em atendimento',
    'Procedimento em andamento',
    '#9C27B0',
    Icons.medical_services,
  ),

  /// Appointment completed successfully
  completed(
    'completed',
    'Concluído',
    'Procedimento finalizado',
    '#2E7D32',
    Icons.check_circle_outline,
  ),

  /// Appointment cancelled by patient
  cancelled(
    'cancelled',
    'Cancelado',
    'Cancelado pelo paciente',
    '#F44336',
    Icons.cancel,
  ),

  /// Appointment cancelled by clinic
  cancelledByClinic(
    'cancelled_by_clinic',
    'Cancelado',
    'Cancelado pela clínica',
    '#D32F2F',
    Icons.cancel_outlined,
  ),

  /// Patient didn't show up
  noShow(
    'no_show',
    'Falta',
    'Paciente não compareceu',
    '#795548',
    Icons.person_off,
  ),

  /// Appointment needs to be rescheduled
  needsRescheduling(
    'needs_rescheduling',
    'Reagendar',
    'Necessita reagendamento',
    '#FF5722',
    Icons.event_busy,
  ),

  /// Waiting for patient documents/consent
  waitingDocuments(
    'waiting_documents',
    'Aguardando docs',
    'Documentos pendentes',
    '#607D8B',
    Icons.description,
  ),

  /// Appointment refunded
  refunded(
    'refunded',
    'Reembolsado',
    'Créditos reembolsados',
    '#00BCD4',
    Icons.attach_money,
  );

  const AppointmentStatus(
    this.value,
    this.label,
    this.description,
    this.colorHex,
    this.iconData,
  );

  /// String value used in API communication
  final String value;

  /// Display label for UI
  final String label;

  /// Detailed description
  final String description;

  /// Hex color code for UI theming
  final String colorHex;

  /// Material icon for visual representation
  final IconData iconData;

  /// Get color object from hex
  Color get color {
    return Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
  }

  /// Get icon widget
  Widget get icon {
    return Icon(iconData, color: color);
  }

  /// Create status from string value
  static AppointmentStatus fromString(String value) {
    for (final status in AppointmentStatus.values) {
      if (status.value == value.toLowerCase()) {
        return status;
      }
    }
    return AppointmentStatus.pending; // Default fallback
  }

  /// Get all upcoming appointment statuses
  static List<AppointmentStatus> get upcomingStatuses => [
    pending,
    confirmed,
    checkedIn,
    inProgress,
    waitingDocuments,
  ];

  /// Get all completed appointment statuses
  static List<AppointmentStatus> get completedStatuses => [completed];

  /// Get all cancelled appointment statuses
  static List<AppointmentStatus> get cancelledStatuses => [
    cancelled,
    cancelledByClinic,
    noShow,
    refunded,
  ];

  /// Check if status allows cancellation
  bool get allowsCancellation {
    return [pending, confirmed, waitingDocuments].contains(this);
  }

  /// Check if status allows rescheduling
  bool get allowsRescheduling {
    return [pending, confirmed, needsRescheduling].contains(this);
  }

  /// Check if status allows rating/review
  bool get allowsRating {
    return this == completed;
  }

  /// Check if appointment is active (not cancelled or completed)
  bool get isActive {
    return ![
      cancelled,
      cancelledByClinic,
      noShow,
      completed,
      refunded,
    ].contains(this);
  }

  /// Check if appointment is final (cannot be modified)
  bool get isFinal {
    return [
      completed,
      cancelled,
      cancelledByClinic,
      noShow,
      refunded,
    ].contains(this);
  }

  /// Check if appointment is in progress or checked in
  bool get isInProgress {
    return [checkedIn, inProgress].contains(this);
  }

  /// Check if appointment requires patient action
  bool get requiresPatientAction {
    return [waitingDocuments, needsRescheduling].contains(this);
  }

  /// Get next possible statuses from current status
  List<AppointmentStatus> getNextPossibleStatuses() {
    switch (this) {
      case pending:
        return [confirmed, cancelled, cancelledByClinic];
      case confirmed:
        return [checkedIn, cancelled, cancelledByClinic, waitingDocuments];
      case checkedIn:
        return [inProgress, cancelled];
      case inProgress:
        return [completed];
      case waitingDocuments:
        return [confirmed, cancelled];
      case needsRescheduling:
        return [confirmed, cancelled];
      default:
        return [];
    }
  }

  /// Get status priority for sorting (lower number = higher priority)
  int get priority {
    switch (this) {
      case inProgress:
        return 1;
      case checkedIn:
        return 2;
      case confirmed:
        return 3;
      case pending:
        return 4;
      case waitingDocuments:
        return 5;
      case needsRescheduling:
        return 6;
      case completed:
        return 7;
      case cancelled:
      case cancelledByClinic:
        return 8;
      case noShow:
        return 9;
      case refunded:
        return 10;
    }
  }

  @override
  String toString() => label;
}

/// Helper extension for appointment status operations
extension AppointmentStatusExtension on AppointmentStatus {
  /// Get light version of status color
  Color get lightColor {
    return color.withOpacity(0.1);
  }

  /// Get status badge widget
  Widget statusBadge({double? fontSize}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: fontSize ?? 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Get notification message for status change
  String getStatusChangeMessage(String serviceName) {
    switch (this) {
      case confirmed:
        return 'Seu agendamento para $serviceName foi confirmado!';
      case checkedIn:
        return 'Check-in realizado para $serviceName. Aguarde ser chamado.';
      case inProgress:
        return 'Seu procedimento $serviceName está em andamento.';
      case completed:
        return 'Procedimento $serviceName finalizado com sucesso!';
      case cancelled:
      case cancelledByClinic:
        return 'Agendamento para $serviceName foi cancelado.';
      case waitingDocuments:
        return 'Documentos pendentes para $serviceName. Verifique os requisitos.';
      case needsRescheduling:
        return 'Reagendamento necessário para $serviceName.';
      default:
        return 'Status do agendamento $serviceName foi atualizado.';
    }
  }
}
