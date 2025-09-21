import 'package:flutter/material.dart';\nimport 'package:get/get.dart';
import '../models/appointment.dart';
import '../models/appointment_status.dart';
import '../models/cancellation_policy.dart';

/// Appointments Controller
/// Manages appointment list, filtering, and operations
class AppointmentsController extends GetxController with GetSingleTickerProviderStateMixin {
  // Observable state
  final _appointments = <Appointment>[].obs;
  final _isLoading = false.obs;
  final _isRefreshing = false.obs;
  final _selectedTabIndex = 0.obs;
  final _searchQuery = ''.obs;
  final _errorMessage = ''.obs;
  
  // Tab controller for appointment tabs
  late TabController tabController;
  
  // Getters
  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading.value;
  bool get isRefreshing => _isRefreshing.value;
  int get selectedTabIndex => _selectedTabIndex.value;
  String get searchQuery => _searchQuery.value;
  String get errorMessage => _errorMessage.value;
  
  // Filtered appointments by tab
  List<Appointment> get upcomingAppointments {
    return _filterAppointments(AppointmentStatus.upcomingStatuses);
  }
  
  List<Appointment> get historyAppointments {
    return _filterAppointments(AppointmentStatus.completedStatuses);
  }
  
  List<Appointment> get cancelledAppointments {
    return _filterAppointments(AppointmentStatus.cancelledStatuses);
  }
  
  @override
  void onInit() {
    super.onInit();
    
    // Initialize tab controller
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(_onTabChanged);
    
    // Load initial data
    loadAppointments();
    
    // Set up refresh timer for upcoming appointments
    _setupRefreshTimer();
  }
  
  @override
  void onClose() {
    tabController.removeListener(_onTabChanged);
    tabController.dispose();
    super.onClose();
  }
  
  /// Load appointments from API
  Future<void> loadAppointments() async {
    try {
      _isLoading(true);
      _errorMessage('');
      
      // Simulate API call - replace with actual service
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Mock data for demonstration
      final mockAppointments = _generateMockAppointments();
      _appointments.assignAll(mockAppointments);
      
    } catch (e) {
      _errorMessage('Erro ao carregar agendamentos: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível carregar os agendamentos',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }
  
  /// Refresh appointments
  Future<void> refreshAppointments() async {
    try {
      _isRefreshing(true);
      await loadAppointments();
    } finally {
      _isRefreshing(false);
    }
  }
  
  /// Filter appointments by status list
  List<Appointment> _filterAppointments(List<AppointmentStatus> statuses) {
    var filtered = _appointments.where((appointment) => 
        statuses.contains(appointment.status)).toList();
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((appointment) =>
          appointment.serviceName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          appointment.clinicName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    // Sort by date
    filtered.sort((a, b) {
      final aDateTime = DateTime(
        a.scheduledDate.year,
        a.scheduledDate.month,
        a.scheduledDate.day,
        int.parse(a.scheduledTime.split(':')[0]),
        int.parse(a.scheduledTime.split(':')[1]),
      );
      final bDateTime = DateTime(
        b.scheduledDate.year,
        b.scheduledDate.month,
        b.scheduledDate.day,
        int.parse(b.scheduledTime.split(':')[0]),
        int.parse(b.scheduledTime.split(':')[1]),
      );
      
      // Upcoming: earliest first, History: latest first
      if (statuses == AppointmentStatus.upcomingStatuses) {
        return aDateTime.compareTo(bDateTime);
      } else {
        return bDateTime.compareTo(aDateTime);
      }
    });
    
    return filtered;
  }
  
  /// Handle tab change
  void _onTabChanged() {
    _selectedTabIndex(tabController.index);
  }
  
  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery(query);
  }
  
  /// Cancel an appointment
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      _isLoading(true);
      
      // Find appointment
      final appointment = _appointments.firstWhere((a) => a.id == appointmentId);
      
      // Navigate to cancellation screen
      final result = await Get.toNamed('/appointments/cancel', arguments: appointment);
      
      if (result == true) {
        // Refresh appointments after cancellation
        await loadAppointments();
        
        Get.snackbar(
          'Sucesso',
          'Agendamento cancelado com sucesso',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao cancelar agendamento: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }
  
  /// Reschedule an appointment
  Future<void> rescheduleAppointment(String appointmentId) async {
    try {
      final appointment = _appointments.firstWhere((a) => a.id == appointmentId);
      
      // Navigate to booking screen with reschedule context
      final result = await Get.toNamed('/discovery/booking', arguments: {
        'reschedule': true,
        'appointment': appointment,
      });
      
      if (result == true) {
        await loadAppointments();
        Get.snackbar(
          'Sucesso',
          'Agendamento reagendado com sucesso',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao reagendar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  /// Rate an appointment
  Future<void> rateAppointment(String appointmentId) async {
    try {
      final appointment = _appointments.firstWhere((a) => a.id == appointmentId);
      
      // Navigate to rating screen
      final result = await Get.toNamed('/appointments/rate', arguments: appointment);
      
      if (result == true) {
        await loadAppointments();
      }
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao avaliar: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  /// Setup refresh timer for real-time updates
  void _setupRefreshTimer() {
    // Refresh every 5 minutes for upcoming appointments
    Stream.periodic(const Duration(minutes: 5)).listen((_) {
      if (selectedTabIndex == 0) { // Upcoming tab
        refreshAppointments();
      }
    });
  }
  
  /// Get appointment statistics
  Map<String, int> get appointmentStats {
    return {
      'upcoming': upcomingAppointments.length,
      'completed': historyAppointments.length,
      'cancelled': cancelledAppointments.length,
      'total': _appointments.length,
    };
  }
  
  /// Get next appointment
  Appointment? get nextAppointment {
    final upcoming = upcomingAppointments;
    return upcoming.isNotEmpty ? upcoming.first : null;
  }
  
  /// Check if user has appointments today
  bool get hasAppointmentsToday {
    final today = DateTime.now();
    return _appointments.any((appointment) =>
        appointment.scheduledDate.year == today.year &&
        appointment.scheduledDate.month == today.month &&
        appointment.scheduledDate.day == today.day);
  }
  
  /// Generate mock appointments for demonstration
  List<Appointment> _generateMockAppointments() {
    final now = DateTime.now();
    
    return [
      // Upcoming appointments
      Appointment(
        id: '1',
        userId: 'user1',
        clinicId: 'clinic1',
        clinicName: 'Clínica Bella Vita',
        serviceId: 'service1',
        serviceName: 'Limpeza de Pele Profunda',
        categoryId: 'aesthetic',
        categoryName: 'Estética Facial',
        scheduledDate: now.add(const Duration(days: 2)),
        scheduledTime: '14:30',
        status: AppointmentStatus.confirmed,
        professionalName: 'Dra. Maria Silva',
        price: 2.5,
        sgCreditsUsed: 2.5,
        sgCreditsEarned: 0.5,
        preInstructions: 'Evitar produtos com ácidos 48h antes do procedimento.',
        canCancel: true,
        canReschedule: true,
        isConfirmed: true,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      
      Appointment(
        id: '2',
        userId: 'user1',
        clinicId: 'clinic2',
        clinicName: 'Estética Harmonia',
        serviceId: 'service2',
        serviceName: 'Botox Facial',
        categoryId: 'injectable',
        categoryName: 'Terapias Injetáveis',
        scheduledDate: now.add(const Duration(days: 7)),
        scheduledTime: '09:00',
        status: AppointmentStatus.pending,
        professionalName: 'Dr. João Santos',
        price: 3.0,
        sgCreditsUsed: 3.0,
        sgCreditsEarned: 0.3,
        requiresConsent: true,
        canCancel: true,
        canReschedule: true,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      
      // Completed appointments
      Appointment(
        id: '3',
        userId: 'user1',
        clinicId: 'clinic1',
        clinicName: 'Clínica Bella Vita',
        serviceId: 'service3',
        serviceName: 'Peeling Químico',
        categoryId: 'aesthetic',
        categoryName: 'Estética Facial',
        scheduledDate: now.subtract(const Duration(days: 15)),
        scheduledTime: '16:00',
        status: AppointmentStatus.completed,
        professionalName: 'Dra. Ana Costa',
        price: 2.0,
        sgCreditsUsed: 2.0,
        sgCreditsEarned: 0.2,
        postInstructions: 'Usar protetor solar FPS 60+ por 30 dias.',
        canRate: true,
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),
      
      // Cancelled appointment
      Appointment(
        id: '4',
        userId: 'user1',
        clinicId: 'clinic3',
        clinicName: 'Centro de Estética Total',
        serviceId: 'service4',
        serviceName: 'Microagulhamento',
        categoryId: 'aesthetic',
        categoryName: 'Estética Facial',
        scheduledDate: now.subtract(const Duration(days: 5)),
        scheduledTime: '11:30',
        status: AppointmentStatus.cancelled,
        price: 1.5,
        sgCreditsUsed: 1.5,
        refundAmount: 1.5,
        cancellationReason: 'Cancelamento devido a conflito de horário',
        cancelledAt: now.subtract(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }
}