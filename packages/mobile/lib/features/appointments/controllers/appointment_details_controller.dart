import 'package:get/get.dart';
import 'package:singleclin_mobile/features/appointments/models/appointment.dart';
import 'package:singleclin_mobile/features/appointments/models/appointment_status.dart';

/// Appointment Details Controller
/// Manages detailed appointment view and actions
class AppointmentDetailsController extends GetxController {
  // Observable state
  final _appointment = Rx<Appointment?>(null);
  final _isLoading = false.obs;
  final _isUpdating = false.obs;
  final _errorMessage = ''.obs;
  final _timeline = <TimelineEvent>[].obs;

  // Getters
  Appointment? get appointment => _appointment.value;
  bool get isLoading => _isLoading.value;
  bool get isUpdating => _isUpdating.value;
  String get errorMessage => _errorMessage.value;
  List<TimelineEvent> get timeline => _timeline;

  @override
  void onInit() {
    super.onInit();

    // Get appointment from arguments
    if (Get.arguments != null && Get.arguments is Appointment) {
      _appointment.value = Get.arguments as Appointment;
      _buildTimeline();
      loadAppointmentDetails();
    }
  }

  /// Load detailed appointment information
  Future<void> loadAppointmentDetails() async {
    if (_appointment.value == null) return;

    try {
      _isLoading(true);
      _errorMessage('');

      // Simulate API call for detailed info
      await Future.delayed(const Duration(milliseconds: 1000));

      // Mock additional details (would come from API)
      final updatedAppointment = _appointment.value!.copyWith(
        metadata: {
          'procedureDuration': 60,
          'preparationTime': 15,
          'arrivalTime': '14:15',
          'clinicAddress': 'Rua das Flores, 123 - Centro',
          'clinicPhone': '(11) 99999-9999',
          'parkingAvailable': true,
          'wheelchairAccessible': true,
        },
        preInstructions:
            _appointment.value!.preInstructions ??
            'Chegue 15 minutos antes do horário marcado. Evite maquiagem no dia do procedimento.',
        postInstructions:
            _appointment.value!.postInstructions ??
            'Evitar exposição solar por 48h. Aplicar protetor solar FPS 60+.',
      );

      _appointment.value = updatedAppointment;
      _buildTimeline();
    } catch (e) {
      _errorMessage('Erro ao carregar detalhes: $e');
    } finally {
      _isLoading(false);
    }
  }

  /// Update appointment status
  Future<void> updateAppointmentStatus(AppointmentStatus newStatus) async {
    if (_appointment.value == null) return;

    try {
      _isUpdating(true);

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));

      final updatedAppointment = _appointment.value!.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      _appointment.value = updatedAppointment;
      _buildTimeline();

      Get.snackbar(
        'Sucesso',
        'Status atualizado para: ${newStatus.label}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao atualizar status: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isUpdating(false);
    }
  }

  /// Cancel appointment
  Future<void> cancelAppointment() async {
    final result = await Get.toNamed(
      '/appointments/cancel',
      arguments: _appointment.value,
    );

    if (result == true) {
      // Reload appointment data
      await loadAppointmentDetails();
    }
  }

  /// Reschedule appointment
  Future<void> rescheduleAppointment() async {
    final result = await Get.toNamed(
      '/discovery/booking',
      arguments: {'reschedule': true, 'appointment': _appointment.value},
    );

    if (result == true) {
      await loadAppointmentDetails();
    }
  }

  /// Rate appointment
  Future<void> rateAppointment() async {
    final result = await Get.toNamed(
      '/appointments/rate',
      arguments: _appointment.value,
    );

    if (result == true) {
      await loadAppointmentDetails();
    }
  }

  /// Share appointment details
  void shareAppointment() {
    if (_appointment.value == null) return;

    final appointment = _appointment.value!;
    final shareText =
        '''
SingleClin - Detalhes do Agendamento

📅 ${appointment.formattedDate} às ${appointment.formattedTime}
🏥 ${appointment.clinicName}
💉 ${appointment.serviceName}
👨‍⚕️ ${appointment.professionalName ?? 'Profissional não informado'}
💰 ${appointment.sgCreditsUsed.toStringAsFixed(0)} SG
📍 Status: ${appointment.status.label}

#SingleClin #SaúdeEBeleza
    ''';

    // Use share_plus package
    try {
      // Share.share(shareText);
      Get.snackbar(
        'Compartilhar',
        'Funcionalidade de compartilhamento será implementada',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao compartilhar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Download appointment receipt
  Future<void> downloadReceipt() async {
    if (_appointment.value == null) return;

    try {
      _isLoading(true);

      // Simulate receipt generation
      await Future.delayed(const Duration(milliseconds: 1500));

      Get.snackbar(
        'Download',
        'Comprovante salvo na galeria',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao baixar comprovante: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }

  /// Contact clinic
  void contactClinic() {
    if (_appointment.value == null) return;

    final clinicPhone = _appointment.value!.metadata?['clinicPhone'] as String?;

    if (clinicPhone != null) {
      // Use url_launcher to open phone dialer
      // launchUrl(Uri.parse('tel:$clinicPhone'));
      Get.snackbar(
        'Contato',
        'Ligando para ${_appointment.value!.clinicName}...',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Indisponível',
        'Telefone da clínica não disponível',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Open clinic location
  void openClinicLocation() {
    final address = _appointment.value!.metadata?['clinicAddress'] as String?;

    if (address != null) {
      // Use url_launcher to open maps
      // final encodedAddress = Uri.encodeComponent(address);
      // launchUrl(Uri.parse('https://maps.google.com/?q=$encodedAddress'));
      Get.snackbar(
        'Navegação',
        'Abrindo localização no mapa...',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Indisponível',
        'Endereço não disponível',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Build appointment timeline
  void _buildTimeline() {
    if (_appointment.value == null) return;

    final appointment = _appointment.value!;
    final events = <TimelineEvent>[];

    // Created event
    events.add(
      TimelineEvent(
        title: 'Agendamento Criado',
        description: 'Solicitação de agendamento realizada',
        timestamp: appointment.createdAt,
        status: TimelineEventStatus.completed,
        icon: 'add_circle',
      ),
    );

    // Status-based events
    switch (appointment.status) {
      case AppointmentStatus.pending:
        events.add(
          TimelineEvent(
            title: 'Aguardando Confirmação',
            description: 'Clínica analisará sua solicitação em até 24h',
            timestamp: appointment.createdAt.add(const Duration(minutes: 5)),
            status: TimelineEventStatus.current,
            icon: 'schedule',
          ),
        );
        break;

      case AppointmentStatus.confirmed:
        events.add(
          TimelineEvent(
            title: 'Agendamento Confirmado',
            description: 'Clínica confirmou seu agendamento',
            timestamp: appointment.updatedAt,
            status: TimelineEventStatus.completed,
            icon: 'check_circle',
          ),
        );

        // Future events
        final appointmentDateTime = DateTime(
          appointment.scheduledDate.year,
          appointment.scheduledDate.month,
          appointment.scheduledDate.day,
          int.parse(appointment.scheduledTime.split(':')[0]),
          int.parse(appointment.scheduledTime.split(':')[1]),
        );

        if (DateTime.now().isBefore(appointmentDateTime)) {
          events.add(
            TimelineEvent(
              title: 'Procedimento Agendado',
              description:
                  '${appointment.serviceName} - ${appointment.formattedDate} às ${appointment.formattedTime}',
              timestamp: appointmentDateTime,
              status: TimelineEventStatus.upcoming,
              icon: 'medical_services',
            ),
          );
        }
        break;

      case AppointmentStatus.completed:
        events.add(
          TimelineEvent(
            title: 'Procedimento Realizado',
            description: 'Seu procedimento foi concluído com sucesso',
            timestamp: appointment.updatedAt,
            status: TimelineEventStatus.completed,
            icon: 'check_circle_outline',
          ),
        );
        break;

      case AppointmentStatus.cancelled:
        events.add(
          TimelineEvent(
            title: 'Agendamento Cancelado',
            description:
                appointment.cancellationReason ?? 'Agendamento cancelado',
            timestamp: appointment.cancelledAt ?? appointment.updatedAt,
            status: TimelineEventStatus.cancelled,
            icon: 'cancel',
          ),
        );
        break;

      default:
        break;
    }

    // Sort events by timestamp
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    _timeline.assignAll(events);
  }

  /// Get appointment instructions based on status
  List<String> get currentInstructions {
    if (_appointment.value == null) return [];

    final appointment = _appointment.value!;
    final instructions = <String>[];

    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        if (appointment.preInstructions != null) {
          instructions.add('📋 PRÉ-PROCEDIMENTO:');
          instructions.add(appointment.preInstructions!);
        }

        final arrivalTime = appointment.metadata?['arrivalTime'] as String?;
        if (arrivalTime != null) {
          instructions.add('🕐 Chegue às $arrivalTime (15 min antes)');
        }
        break;

      case AppointmentStatus.completed:
        if (appointment.postInstructions != null) {
          instructions.add('📋 PÓS-PROCEDIMENTO:');
          instructions.add(appointment.postInstructions!);
        }
        break;

      default:
        break;
    }

    return instructions;
  }

  /// Get available actions for current appointment
  List<AppointmentAction> get availableActions {
    if (_appointment.value == null) return [];

    final appointment = _appointment.value!;
    final actions = <AppointmentAction>[];

    // Cancel action
    if (appointment.canCancel && appointment.status.allowsCancellation) {
      actions.add(
        AppointmentAction(
          title: 'Cancelar',
          icon: 'cancel',
          color: '#F44336',
          action: cancelAppointment,
        ),
      );
    }

    // Reschedule action
    if (appointment.canReschedule && appointment.status.allowsRescheduling) {
      actions.add(
        AppointmentAction(
          title: 'Reagendar',
          icon: 'event',
          color: '#FF9800',
          action: rescheduleAppointment,
        ),
      );
    }

    // Rate action
    if (appointment.canRate && appointment.status.allowsRating) {
      actions.add(
        AppointmentAction(
          title: 'Avaliar',
          icon: 'star',
          color: '#FFC107',
          action: rateAppointment,
        ),
      );
    }

    // Share action
    actions.add(
      AppointmentAction(
        title: 'Compartilhar',
        icon: 'share',
        color: '#2196F3',
        action: shareAppointment,
      ),
    );

    // Download receipt
    if (appointment.status == AppointmentStatus.completed) {
      actions.add(
        AppointmentAction(
          title: 'Comprovante',
          icon: 'download',
          color: '#4CAF50',
          action: downloadReceipt,
        ),
      );
    }

    return actions;
  }
}

/// Timeline Event Model
class TimelineEvent {
  TimelineEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.status,
    required this.icon,
  });
  final String title;
  final String description;
  final DateTime timestamp;
  final TimelineEventStatus status;
  final String icon;

  String get formattedTime {
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

/// Timeline Event Status
enum TimelineEventStatus {
  completed('#4CAF50'),
  current('#2196F3'),
  upcoming('#9E9E9E'),
  cancelled('#F44336');

  const TimelineEventStatus(this.color);
  final String color;
}

/// Appointment Action Model
class AppointmentAction {
  AppointmentAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.action,
  });
  final String title;
  final String icon;
  final String color;
  final VoidCallback action;
}
