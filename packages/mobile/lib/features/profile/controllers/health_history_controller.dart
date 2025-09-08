import 'package:get/get.dart';
import '../models/health_record.dart';

/// Health History Controller
/// Manages medical history and health records
class HealthHistoryController extends GetxController {
  // Observable state
  final _records = <HealthRecord>[].obs;
  final _metrics = <HealthMetric>[].obs;
  final _isLoading = false.obs;
  final _isRefreshing = false.obs;
  final _errorMessage = ''.obs;
  final _selectedFilter = HealthRecordType.other.obs;
  final _searchQuery = ''.obs;
  final _selectedDateRange = DateRange.all.obs;
  
  // Getters
  List<HealthRecord> get records => _records;
  List<HealthMetric> get metrics => _metrics;
  bool get isLoading => _isLoading.value;
  bool get isRefreshing => _isRefreshing.value;
  String get errorMessage => _errorMessage.value;
  HealthRecordType get selectedFilter => _selectedFilter.value;
  String get searchQuery => _searchQuery.value;
  DateRange get selectedDateRange => _selectedDateRange.value;
  
  // Filtered records
  List<HealthRecord> get filteredRecords {
    var filtered = _records.where((record) {
      // Filter by type
      if (_selectedFilter.value != HealthRecordType.other) {
        if (record.type != _selectedFilter.value.value) return false;
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!record.title.toLowerCase().contains(query) &&
            !record.description.toLowerCase().contains(query) &&
            !(record.clinicName?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }
      
      // Filter by date range
      final now = DateTime.now();
      switch (_selectedDateRange.value) {
        case DateRange.lastMonth:
          if (record.date.isBefore(now.subtract(const Duration(days: 30)))) {
            return false;
          }
          break;
        case DateRange.last3Months:
          if (record.date.isBefore(now.subtract(const Duration(days: 90)))) {
            return false;
          }
          break;
        case DateRange.lastYear:
          if (record.date.isBefore(now.subtract(const Duration(days: 365)))) {
            return false;
          }
          break;
        case DateRange.all:
          break;
      }
      
      return record.status == HealthRecordStatus.active;
    }).toList();
    
    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));
    
    return filtered;
  }
  
  // Metrics by type
  Map<HealthMetricType, List<HealthMetric>> get metricsByType {
    final grouped = <HealthMetricType, List<HealthMetric>>{};
    
    for (final metric in _metrics) {
      final type = metric.metricType;
      grouped[type] = (grouped[type] ?? [])..add(metric);
    }
    
    // Sort metrics within each type by date
    for (final type in grouped.keys) {
      grouped[type]!.sort((a, b) => b.recordedDate.compareTo(a.recordedDate));
    }
    
    return grouped;
  }
  
  @override
  void onInit() {
    super.onInit();
    loadHealthHistory();
  }
  
  /// Load health history from API
  Future<void> loadHealthHistory() async {
    try {
      _isLoading(true);
      _errorMessage('');
      
      // Simulate API calls
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Load mock data
      final mockRecords = _generateMockRecords();
      final mockMetrics = _generateMockMetrics();
      
      _records.assignAll(mockRecords);
      _metrics.assignAll(mockMetrics);
      
    } catch (e) {
      _errorMessage('Erro ao carregar histórico: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível carregar o histórico médico',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }
  
  /// Refresh health history
  Future<void> refreshHealthHistory() async {
    try {
      _isRefreshing(true);
      await loadHealthHistory();
    } finally {
      _isRefreshing(false);
    }
  }
  
  /// Update filter
  void updateFilter(HealthRecordType filter) {
    _selectedFilter(filter);
  }
  
  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery(query);
  }
  
  /// Update date range filter
  void updateDateRange(DateRange range) {
    _selectedDateRange(range);
  }
  
  /// Add new health record
  Future<void> addHealthRecord(HealthRecord record) async {
    try {
      _isLoading(true);
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 1000));
      
      _records.insert(0, record);
      
      Get.snackbar(
        'Sucesso',
        'Registro médico adicionado',
        snackPosition: SnackPosition.BOTTOM,
      );
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao adicionar registro: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }
  
  /// Update health record
  Future<void> updateHealthRecord(HealthRecord record) async {
    try {
      _isLoading(true);
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));
      
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _records[index] = record.copyWith(updatedAt: DateTime.now());
      }
      
      Get.snackbar(
        'Sucesso',
        'Registro atualizado',
        snackPosition: SnackPosition.BOTTOM,
      );
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao atualizar registro: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }
  
  /// Archive health record
  Future<void> archiveHealthRecord(String recordId) async {
    try {
      _isLoading(true);
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      final index = _records.indexWhere((r) => r.id == recordId);
      if (index != -1) {
        _records[index] = _records[index].copyWith(
          status: HealthRecordStatus.archived,
          updatedAt: DateTime.now(),
        );
      }
      
      Get.snackbar(
        'Sucesso',
        'Registro arquivado',
        snackPosition: SnackPosition.BOTTOM,
      );
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao arquivar registro: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }
  
  /// Delete health record
  Future<void> deleteHealthRecord(String recordId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Excluir Registro'),
        content: const Text('Tem certeza que deseja excluir este registro médico?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirmed) return;
    
    try {
      _isLoading(true);
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      _records.removeWhere((r) => r.id == recordId);
      
      Get.snackbar(
        'Sucesso',
        'Registro excluído',
        snackPosition: SnackPosition.BOTTOM,
      );
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao excluir registro: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }
  
  /// Add health metric
  Future<void> addHealthMetric(HealthMetric metric) async {
    try {
      _isLoading(true);
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      _metrics.insert(0, metric);
      
      Get.snackbar(
        'Sucesso',
        'Métrica adicionada',
        snackPosition: SnackPosition.BOTTOM,
      );
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao adicionar métrica: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }
  
  /// Export health data to PDF
  Future<void> exportHealthData() async {
    try {
      _isLoading(true);
      
      // Simulate PDF generation
      await Future.delayed(const Duration(milliseconds: 2500));
      
      Get.snackbar(
        'Export Concluído',
        'Relatório de saúde salvo na galeria',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao exportar dados: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }
  
  /// Get statistics
  Map<String, dynamic> get statistics {
    final totalRecords = _records.length;
    final recordsByType = <String, int>{};
    final recentRecords = _records.where((r) => 
        r.date.isAfter(DateTime.now().subtract(const Duration(days: 30)))).length;
    
    for (final record in _records) {
      final type = HealthRecordType.fromString(record.type);
      recordsByType[type.label] = (recordsByType[type.label] ?? 0) + 1;
    }
    
    final followUpsDue = _records.where((r) => r.isFollowUpDue).length;
    
    return {
      'totalRecords': totalRecords,
      'recentRecords': recentRecords,
      'recordsByType': recordsByType,
      'followUpsDue': followUpsDue,
      'totalMetrics': _metrics.length,
    };
  }
  
  /// Get upcoming follow-ups
  List<HealthRecord> get upcomingFollowUps {
    return _records.where((record) => record.hasFollowUp && !record.isFollowUpDue).toList()
      ..sort((a, b) {
        final aDate = DateTime.parse(a.followUpDate!);
        final bDate = DateTime.parse(b.followUpDate!);
        return aDate.compareTo(bDate);
      });
  }
  
  /// Get overdue follow-ups
  List<HealthRecord> get overdueFollowUps {
    return _records.where((record) => record.isFollowUpDue).toList();
  }
  
  /// Generate mock health records
  List<HealthRecord> _generateMockRecords() {
    final now = DateTime.now();
    
    return [
      HealthRecord(
        id: '1',
        userId: 'user123',
        type: 'procedure',
        title: 'Limpeza de Pele Profunda',
        description: 'Procedimento de limpeza facial realizado com extração de cravos e aplicação de máscara calmante.',
        date: now.subtract(const Duration(days: 15)),
        clinicId: 'clinic1',
        clinicName: 'Clínica Bella Vita',
        professionalName: 'Dra. Maria Silva',
        appointmentId: 'appt1',
        recommendations: [
          'Usar protetor solar FPS 60+',
          'Evitar exposição solar por 48h',
          'Aplicar hidratante 2x ao dia'
        ],
        followUpDate: now.add(const Duration(days: 30)).toIso8601String(),
        isImportant: true,
        tags: ['estética', 'facial', 'limpeza'],
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),
      
      HealthRecord(
        id: '2',
        userId: 'user123',
        type: 'exam',
        title: 'Hemograma Completo',
        description: 'Exame de sangue para avaliação geral do estado de saúde.',
        date: now.subtract(const Duration(days: 30)),
        clinicName: 'Laboratório Saúde+',
        results: {
          'hemoglobina': '14.2 g/dL',
          'hematocrito': '42.5%',
          'leucocitos': '7200/μL',
          'plaquetas': '320000/μL',
        },
        recommendations: [
          'Valores dentro da normalidade',
          'Manter hábitos saudáveis'
        ],
        attachments: ['hemograma_202401.pdf'],
        tags: ['exame', 'sangue', 'rotina'],
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
      
      HealthRecord(
        id: '3',
        userId: 'user123',
        type: 'consultation',
        title: 'Consulta Dermatológica',
        description: 'Avaliação de pele e orientações para cuidados específicos.',
        date: now.subtract(const Duration(days: 45)),
        professionalName: 'Dr. Carlos Santos',
        clinicName: 'Dermatologia & Estética',
        recommendations: [
          'Usar protetor solar diariamente',
          'Hidratante específico para pele oleosa',
          'Retorno em 3 meses'
        ],
        followUpDate: now.add(const Duration(days: 45)).toIso8601String(),
        tags: ['dermatologia', 'consulta', 'pele'],
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 45)),
      ),
      
      HealthRecord(
        id: '4',
        userId: 'user123',
        type: 'vaccination',
        title: 'Vacina Influenza',
        description: 'Vacinação anual contra gripe.',
        date: now.subtract(const Duration(days: 90)),
        clinicName: 'UBS Centro',
        professionalName: 'Enfermeira Ana',
        metadata: {
          'vaccineType': 'Influenza tetravalente',
          'lot': 'INF2024-001',
          'manufacturer': 'Instituto Butantan',
        },
        tags: ['vacina', 'gripe', 'prevenção'],
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 90)),
      ),
    ];
  }
  
  /// Generate mock health metrics
  List<HealthMetric> _generateMockMetrics() {
    final now = DateTime.now();
    final metrics = <HealthMetric>[];
    
    // Weight measurements (last 6 months)
    for (int i = 0; i < 6; i++) {
      metrics.add(HealthMetric(
        id: 'weight_$i',
        userId: 'user123',
        type: 'weight',
        value: 65.5 + (i * 0.2) - 0.5,
        unit: 'kg',
        recordedDate: now.subtract(Duration(days: i * 30)),
        source: 'Manual',
      ));
    }
    
    // Blood pressure measurements
    for (int i = 0; i < 4; i++) {
      metrics.add(HealthMetric(
        id: 'bp_$i',
        userId: 'user123',
        type: 'blood_pressure',
        value: 120 + (i * 2),
        unit: 'mmHg',
        recordedDate: now.subtract(Duration(days: i * 45)),
        source: 'Clínica',
        notes: '${120 + (i * 2)}/${80 + i} mmHg',
      ));
    }
    
    return metrics;
  }
}

/// Date Range Filter
enum DateRange {
  all('Todos'),
  lastMonth('Último mês'),
  last3Months('Últimos 3 meses'),
  lastYear('Último ano');
  
  const DateRange(this.label);
  final String label;
}