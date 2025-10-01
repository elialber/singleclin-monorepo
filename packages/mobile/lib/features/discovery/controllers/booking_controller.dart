import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:singleclin_mobile/core/services/api_service.dart';
import 'package:singleclin_mobile/core/constants/app_constants.dart';
import 'package:singleclin_mobile/features/discovery/models/booking.dart';
import 'package:singleclin_mobile/features/discovery/models/clinic.dart';
import 'package:singleclin_mobile/features/discovery/models/service.dart';

/// Booking controller managing appointment scheduling and calendar integration
class BookingController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Booking process state
  final _selectedClinic = Rxn<Clinic>();
  final _selectedService = Rxn<Service>();
  final _selectedDate = Rxn<DateTime>();
  final _selectedTimeSlot = Rxn<TimeSlot>();
  final _selectedProfessional = Rxn<String>();
  final _bookingNotes = ''.obs;
  final _agreedToTerms = false.obs;

  // Calendar state
  final _focusedDay = DateTime.now().obs;
  final _calendarFormat = CalendarFormat.month.obs;
  final _availableDates = <DateTime>[].obs;
  final _availableTimeSlots = <TimeSlot>[].obs;

  // Loading states
  final _isLoadingAvailability = false.obs;
  final _isLoadingTimeSlots = false.obs;
  final _isCreatingBooking = false.obs;

  // UI state
  final _currentStep = 0.obs;
  final _bookingReminders = const BookingReminders().obs;
  final _showCalendarEvents = true.obs;
  final _selectedPackageDeal = Rxn<PackageDeal>();
  final _totalSessions = 1.obs;

  // Constants
  static const int maxSteps = 4; // Service -> Date -> Time -> Confirmation
  static const int daysAhead = 60; // How many days ahead to show availability

  // Getters
  Clinic? get selectedClinic => _selectedClinic.value;
  Service? get selectedService => _selectedService.value;
  DateTime? get selectedDate => _selectedDate.value;
  TimeSlot? get selectedTimeSlot => _selectedTimeSlot.value;
  String? get selectedProfessional => _selectedProfessional.value;
  String get bookingNotes => _bookingNotes.value;
  bool get agreedToTerms => _agreedToTerms.value;
  DateTime get focusedDay => _focusedDay.value;
  CalendarFormat get calendarFormat => _calendarFormat.value;
  List<DateTime> get availableDates => _availableDates;
  List<TimeSlot> get availableTimeSlots => _availableTimeSlots;
  bool get isLoadingAvailability => _isLoadingAvailability.value;
  bool get isLoadingTimeSlots => _isLoadingTimeSlots.value;
  bool get isCreatingBooking => _isCreatingBooking.value;
  int get currentStep => _currentStep.value;
  BookingReminders get bookingReminders => _bookingReminders.value;
  bool get showCalendarEvents => _showCalendarEvents.value;
  PackageDeal? get selectedPackageDeal => _selectedPackageDeal.value;
  int get totalSessions => _totalSessions.value;

  // Computed properties
  bool get canProceedToNextStep {
    switch (_currentStep.value) {
      case 0: // Service selection
        return _selectedService.value != null;
      case 1: // Date selection
        return _selectedDate.value != null;
      case 2: // Time selection
        return _selectedTimeSlot.value != null;
      case 3: // Confirmation
        return _agreedToTerms.value;
      default:
        return false;
    }
  }

  bool get canGoBack => _currentStep.value > 0;

  int get totalCostSG {
    final service = _selectedService.value;
    if (service == null) return 0;

    final deal = _selectedPackageDeal.value;
    if (deal != null) {
      return deal.totalPrice;
    }

    return service.priceInSG * _totalSessions.value;
  }

  String get stepTitle {
    switch (_currentStep.value) {
      case 0:
        return 'Selecionar Serviço';
      case 1:
        return 'Escolher Data';
      case 2:
        return 'Escolher Horário';
      case 3:
        return 'Confirmar Agendamento';
      default:
        return 'Agendamento';
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Set minimum selectable date to tomorrow
    _focusedDay.value = DateTime.now().add(const Duration(days: 1));
  }

  /// Initialize booking flow with clinic and optional service
  void initializeBooking(Clinic clinic, [Service? service]) {
    _selectedClinic.value = clinic;
    _selectedService.value = service;
    _currentStep.value = service != null
        ? 1
        : 0; // Skip service selection if provided

    if (service != null) {
      _loadServiceAvailability();
    }
  }

  /// Select service for booking
  void selectService(Service service) {
    _selectedService.value = service;
    _selectedDate.value = null;
    _selectedTimeSlot.value = null;
    _selectedPackageDeal.value = null;
    _totalSessions.value = 1;

    _loadServiceAvailability();
  }

  /// Select package deal
  void selectPackageDeal(PackageDeal? deal) {
    _selectedPackageDeal.value = deal;
    _totalSessions.value = deal?.sessions ?? 1;
  }

  /// Load service availability for calendar
  Future<void> _loadServiceAvailability() async {
    final service = _selectedService.value;
    final clinic = _selectedClinic.value;

    if (service == null || clinic == null) return;

    try {
      _isLoadingAvailability.value = true;

      final endDate = DateTime.now().add(const Duration(days: daysAhead));
      final response = await _apiService
          .get('/clinics/${clinic.id}/services/${service.id}/availability', {
            'startDate': DateTime.now().toIso8601String(),
            'endDate': endDate.toIso8601String(),
          });

      if (response.isSuccess && response.data != null) {
        final datesData = response.data['availableDates'] as List;
        _availableDates.value = datesData
            .map((d) => DateTime.parse(d as String))
            .toList();
      }
    } catch (e) {
      _handleError('Erro ao carregar disponibilidade', e);
    } finally {
      _isLoadingAvailability.value = false;
    }
  }

  /// Check if date is available for booking
  bool isDateAvailable(DateTime date) {
    if (date.isBefore(DateTime.now())) return false;

    if (_availableDates.isEmpty) {
      // If no specific availability data, check service general availability
      return _selectedService.value?.isAvailableOn(date) ?? false;
    }

    return _availableDates.any(
      (availableDate) => isSameDay(availableDate, date),
    );
  }

  /// Select booking date
  void selectDate(DateTime date) {
    if (!isDateAvailable(date)) return;

    _selectedDate.value = date;
    _selectedTimeSlot.value = null; // Reset time selection
    _loadTimeSlots(date);
  }

  /// Load available time slots for selected date
  Future<void> _loadTimeSlots(DateTime date) async {
    final service = _selectedService.value;
    final clinic = _selectedClinic.value;

    if (service == null || clinic == null) return;

    try {
      _isLoadingTimeSlots.value = true;

      final response = await _apiService.get(
        '/clinics/${clinic.id}/services/${service.id}/timeslots',
        {'date': date.toIso8601String()},
      );

      if (response.isSuccess && response.data != null) {
        final slotsData = response.data['timeSlots'] as List;
        _availableTimeSlots.value = slotsData
            .map((slot) => TimeSlot.fromJson(slot))
            .toList();
      }
    } catch (e) {
      _handleError('Erro ao carregar horários', e);
      // Generate default time slots as fallback
      _generateFallbackTimeSlots();
    } finally {
      _isLoadingTimeSlots.value = false;
    }
  }

  /// Generate fallback time slots when API fails
  void _generateFallbackTimeSlots() {
    final slots = <TimeSlot>[];
    const startHour = 8;
    const endHour = 18;
    const slotDuration = 60; // minutes

    for (int hour = startHour; hour < endHour; hour++) {
      for (int minute = 0; minute < 60; minute += slotDuration) {
        if (hour == endHour - 1 && minute > 0) break;

        slots.add(
          TimeSlot(
            time: TimeOfDay(hour: hour, minute: minute),
            isAvailable: true,
          ),
        );
      }
    }

    _availableTimeSlots.value = slots;
  }

  /// Select time slot
  void selectTimeSlot(TimeSlot timeSlot) {
    if (!timeSlot.isAvailable) return;

    _selectedTimeSlot.value = timeSlot;
    _selectedProfessional.value = timeSlot.professionalId;
  }

  /// Update booking notes
  void updateNotes(String notes) {
    _bookingNotes.value = notes;
  }

  /// Toggle terms agreement
  void toggleTermsAgreement(bool agreed) {
    _agreedToTerms.value = agreed;
  }

  /// Update reminder settings
  void updateReminders(BookingReminders reminders) {
    _bookingReminders.value = reminders;
  }

  /// Navigate to next step
  void nextStep() {
    if (canProceedToNextStep && _currentStep.value < maxSteps - 1) {
      _currentStep.value++;
    }
  }

  /// Navigate to previous step
  void previousStep() {
    if (canGoBack) {
      _currentStep.value--;
    }
  }

  /// Jump to specific step
  void goToStep(int step) {
    if (step >= 0 && step < maxSteps) {
      _currentStep.value = step;
    }
  }

  /// Create booking
  Future<bool> createBooking() async {
    if (!_validateBookingData()) return false;

    try {
      _isCreatingBooking.value = true;

      final bookingRequest = BookingRequest(
        clinicId: _selectedClinic.value!.id,
        serviceId: _selectedService.value!.id,
        scheduledDate: _selectedDate.value!,
        scheduledTime: _selectedTimeSlot.value!.time,
        notes: _bookingNotes.value.isEmpty ? null : _bookingNotes.value,
        professionalId: _selectedProfessional.value,
        reminders: _bookingReminders.value,
        agreedToTerms: _agreedToTerms.value,
      );

      final response = await _apiService.post(
        '/bookings',
        bookingRequest.toJson(),
      );

      if (response.isSuccess) {
        _showBookingSuccessDialog();
        _resetBookingState();
        return true;
      } else {
        throw Exception(response.message ?? 'Erro ao criar agendamento');
      }
    } catch (e) {
      _handleError('Erro ao confirmar agendamento', e);
      return false;
    } finally {
      _isCreatingBooking.value = false;
    }
  }

  /// Validate booking data before creation
  bool _validateBookingData() {
    if (_selectedClinic.value == null) {
      Get.snackbar('Erro', 'Clínica não selecionada');
      return false;
    }

    if (_selectedService.value == null) {
      Get.snackbar('Erro', 'Serviço não selecionado');
      return false;
    }

    if (_selectedDate.value == null) {
      Get.snackbar('Erro', 'Data não selecionada');
      return false;
    }

    if (_selectedTimeSlot.value == null) {
      Get.snackbar('Erro', 'Horário não selecionado');
      return false;
    }

    if (!_agreedToTerms.value) {
      Get.snackbar('Erro', 'É necessário aceitar os termos e condições');
      return false;
    }

    return true;
  }

  /// Show booking success dialog
  void _showBookingSuccessDialog() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Agendamento Confirmado!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seu agendamento foi confirmado com sucesso.'),
            const SizedBox(height: 16),
            Text('Clínica: ${_selectedClinic.value?.name}'),
            Text('Serviço: ${_selectedService.value?.name}'),
            Text(
              'Data: ${_selectedDate.value?.day}/${_selectedDate.value?.month}/${_selectedDate.value?.year}',
            ),
            Text('Horário: ${_selectedTimeSlot.value?.formattedTime}'),
            const SizedBox(height: 16),
            Text(
              'Você receberá lembretes conforme suas configurações.',
              style: Get.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Return to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Reset booking state for new booking
  void _resetBookingState() {
    _selectedService.value = null;
    _selectedDate.value = null;
    _selectedTimeSlot.value = null;
    _selectedProfessional.value = null;
    _bookingNotes.value = '';
    _agreedToTerms.value = false;
    _currentStep.value = 0;
    _selectedPackageDeal.value = null;
    _totalSessions.value = 1;
    _availableDates.clear();
    _availableTimeSlots.clear();
  }

  /// Cancel booking process
  void cancelBooking() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: const Text(
          'Tem certeza de que deseja cancelar este agendamento?',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Não')),
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Return to previous screen
              _resetBookingState();
            },
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );
  }

  /// Toggle calendar format
  void toggleCalendarFormat() {
    _calendarFormat.value = _calendarFormat.value == CalendarFormat.month
        ? CalendarFormat.twoWeeks
        : CalendarFormat.month;
  }

  /// Update focused day in calendar
  void updateFocusedDay(DateTime day) {
    _focusedDay.value = day;
  }

  /// Toggle calendar events visibility
  void toggleCalendarEvents() {
    _showCalendarEvents.value = !_showCalendarEvents.value;
  }

  /// Get booking summary for confirmation
  Map<String, dynamic> getBookingSummary() {
    return {
      'clinic': _selectedClinic.value?.name ?? '',
      'service': _selectedService.value?.name ?? '',
      'date': _selectedDate.value != null
          ? '${_selectedDate.value!.day}/${_selectedDate.value!.month}/${_selectedDate.value!.year}'
          : '',
      'time': _selectedTimeSlot.value?.formattedTime ?? '',
      'duration': _selectedService.value?.formattedDuration ?? '',
      'cost': '${totalCostSG}SG',
      'sessions': _totalSessions.value,
      'deal': _selectedPackageDeal.value?.description,
      'professional': _selectedTimeSlot.value?.professionalName,
      'notes': _bookingNotes.value.isEmpty ? null : _bookingNotes.value,
    };
  }

  /// Handle errors with user-friendly messages
  void _handleError(String message, dynamic error) {
    debugPrint('$message: $error');
    Get.snackbar(
      'Erro',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
    );
  }
}
