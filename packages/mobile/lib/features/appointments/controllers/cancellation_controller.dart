import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/features/appointments/models/appointment.dart';
import 'package:singleclin_mobile/features/appointments/models/cancellation_policy.dart';

/// Cancellation Controller
/// Manages appointment cancellation process and policy calculations
class CancellationController extends GetxController {
  // Observable state
  final _appointment = Rx<Appointment?>(null);
  final _policy = Rx<CancellationPolicy?>(null);
  final _calculation = Rx<CancellationCalculation?>(null);
  final _selectedReason = Rx<CancellationReason?>(null);
  final _isEmergency = false.obs;
  final _customReason = ''.obs;
  final _isLoading = false.obs;
  final _isProcessing = false.obs;
  final _errorMessage = ''.obs;

  // Getters
  Appointment? get appointment => _appointment.value;
  CancellationPolicy? get policy => _policy.value;
  CancellationCalculation? get calculation => _calculation.value;
  CancellationReason? get selectedReason => _selectedReason.value;
  bool get isEmergency => _isEmergency.value;
  String get customReason => _customReason.value;
  bool get isLoading => _isLoading.value;
  bool get isProcessing => _isProcessing.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();

    // Get appointment from arguments
    if (Get.arguments != null && Get.arguments is Appointment) {
      _appointment.value = Get.arguments as Appointment;
      loadCancellationPolicy();
    }
  }

  /// Load cancellation policy for the appointment
  Future<void> loadCancellationPolicy() async {
    if (_appointment.value == null) return;

    try {
      _isLoading(true);
      _errorMessage('');

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 1000));

      // For demo, use default policy
      _policy.value = CancellationPolicy.getDefault();

      // Calculate refund immediately
      _calculateRefund();
    } catch (e) {
      _errorMessage('Erro ao carregar política de cancelamento: $e');
    } finally {
      _isLoading(false);
    }
  }

  /// Calculate refund amount
  void _calculateRefund() {
    if (_appointment.value == null || _policy.value == null) return;

    final appointment = _appointment.value!;
    final policy = _policy.value!;

    final calculation = policy.calculateRefund(
      appointmentDate: DateTime(
        appointment.scheduledDate.year,
        appointment.scheduledDate.month,
        appointment.scheduledDate.day,
        int.parse(appointment.scheduledTime.split(':')[0]),
        int.parse(appointment.scheduledTime.split(':')[1]),
      ),
      cancellationDate: DateTime.now(),
      appointmentPrice: appointment.price,
      sgCreditsUsed: appointment.sgCreditsUsed,
      isEmergency: _isEmergency.value,
    );

    _calculation.value = calculation;
  }

  /// Update emergency status
  void updateEmergencyStatus(bool isEmergency) {
    _isEmergency(isEmergency);
    _calculateRefund();

    // Reset reason if changing emergency status
    if (isEmergency) {
      _selectedReason.value = CancellationReason.medicalEmergency;
    } else {
      _selectedReason.value = null;
    }
  }

  /// Update selected cancellation reason
  void updateSelectedReason(CancellationReason? reason) {
    _selectedReason.value = reason;

    // Update emergency status based on reason
    if (reason?.isEmergency ?? false) {
      _isEmergency(true);
      _calculateRefund();
    }
  }

  /// Update custom reason
  void updateCustomReason(String reason) {
    _customReason(reason);
  }

  /// Process appointment cancellation
  Future<void> processCancellation() async {
    if (_appointment.value == null ||
        _calculation.value == null ||
        _selectedReason.value == null) {
      Get.snackbar(
        'Erro',
        'Por favor, selecione um motivo para o cancelamento',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final calculation = _calculation.value!;

    if (!calculation.canCancel) {
      Get.snackbar(
        'Não é possível cancelar',
        calculation.reason,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      _isProcessing(true);

      // Show confirmation dialog
      final confirmed = await _showCancellationConfirmation();
      if (!confirmed) return;

      // Simulate API call to cancel appointment
      await Future.delayed(const Duration(milliseconds: 2000));

      // Process refund if applicable
      if (calculation.refundAmount > 0) {
        await _processRefund(calculation.refundAmount);
      }

      Get.snackbar(
        'Cancelamento Processado',
        calculation.formattedMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );

      // Return success to previous screen
      Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao processar cancelamento: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isProcessing(false);
    }
  }

  /// Show cancellation confirmation dialog
  Future<bool> _showCancellationConfirmation() async {
    final calculation = _calculation.value!;

    return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Confirmar Cancelamento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tem certeza que deseja cancelar este agendamento?'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumo do Reembolso:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(calculation.formattedMessage),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Voltar'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cancelar Agendamento'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Process refund credits
  Future<void> _processRefund(double refundAmount) async {
    try {
      // Simulate refund processing
      await Future.delayed(const Duration(milliseconds: 1500));

      // In real app, this would call the credits API
      // to add refund credits to user's account
    } catch (e) {
      throw Exception('Erro ao processar reembolso: $e');
    }
  }

  /// Get available cancellation reasons
  List<CancellationReason> get availableReasons {
    return CancellationReason.values.where((reason) {
      // Filter reasons based on emergency status
      if (_isEmergency.value) {
        return reason.isEmergency;
      } else {
        return !reason.isEmergency;
      }
    }).toList();
  }

  /// Check if cancellation form is valid
  bool get isFormValid {
    return _selectedReason.value != null &&
        (_selectedReason.value != CancellationReason.other ||
            _customReason.value.isNotEmpty);
  }

  /// Get formatted cancellation summary
  String get cancellationSummary {
    if (_calculation.value == null) return '';

    final calc = _calculation.value!;
    final appointment = _appointment.value!;

    return '''
Agendamento: ${appointment.serviceName}
Data: ${appointment.formattedDate} às ${appointment.formattedTime}
Tempo até o agendamento: ${calc.timeDescription}

${calc.formattedMessage}
''';
  }
}

/// Cancellation Reason Enum
enum CancellationReason {
  personalReasons('personal_reasons', 'Motivos pessoais', false),
  scheduleConflict('schedule_conflict', 'Conflito de agenda', false),
  financialReasons('financial_reasons', 'Motivos financeiros', false),
  changeOfMind('change_of_mind', 'Mudança de ideia', false),
  foundBetterOption('found_better_option', 'Encontrou melhor opção', false),
  medicalEmergency('medical_emergency', 'Emergência médica', true),
  familyEmergency('family_emergency', 'Emergência familiar', true),
  illnessSymptoms('illness_symptoms', 'Sintomas de doença', true),
  forceeMajeure('force_majeure', 'Força maior', true),
  other('other', 'Outro motivo', false);

  const CancellationReason(this.value, this.label, this.isEmergency);

  final String value;
  final String label;
  final bool isEmergency;

  static CancellationReason fromString(String value) {
    return values.firstWhere(
      (reason) => reason.value == value,
      orElse: () => personalReasons,
    );
  }

  /// Get emergency reasons
  static List<CancellationReason> get emergencyReasons =>
      values.where((r) => r.isEmergency).toList();

  /// Get regular reasons
  static List<CancellationReason> get regularReasons =>
      values.where((r) => !r.isEmergency).toList();
}
