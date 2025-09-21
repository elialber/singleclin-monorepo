import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model for scan history item
class ScanHistoryItem {
  ScanHistoryItem({
    required this.id,
    required this.patientName,
    required this.patientId,
    required this.serviceName,
    required this.creditCost,
    required this.scanTime,
    required this.status,
    required this.canCancel,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    final scanTime = DateTime.parse(json['scanTime']);
    final now = DateTime.now();
    final canCancel = now.difference(scanTime).inMinutes < 5;

    return ScanHistoryItem(
      id: json['id'],
      patientName: json['patientName'],
      patientId: json['patientId'],
      serviceName: json['serviceName'],
      creditCost: json['creditCost'],
      scanTime: scanTime,
      status: json['status'],
      canCancel: canCancel && json['status'] == 'active',
    );
  }
  final String id;
  final String patientName;
  final String patientId;
  final String serviceName;
  final int creditCost;
  final DateTime scanTime;
  final String status;
  final bool canCancel;

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientName': patientName,
    'patientId': patientId,
    'serviceName': serviceName,
    'creditCost': creditCost,
    'scanTime': scanTime.toIso8601String(),
    'status': status,
  };
}

/// Screen to display scan history for the current day
class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final Dio _dio = Dio();
  final List<ScanHistoryItem> _scanHistory = [];
  bool _isLoading = true;
  String? _error;
  late Box<Map> _cacheBox;

  // Totals
  int _totalScans = 0;
  int _totalCredits = 0;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  /// Initialize Hive for caching
  Future<void> _initializeHive() async {
    try {
      _cacheBox = await Hive.openBox<Map>('scan_history_cache');
      await _setupDio();
      await _loadScanHistory();
    } catch (e) {
      debugPrint('Error initializing Hive: $e');
      setState(() {
        _error = 'Erro ao inicializar cache: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Configure Dio with base URL and auth token
  Future<void> _setupDio() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    const baseUrl = 'https://api.singleclin.com.br/api';

    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );
  }

  /// Load scan history from API or cache
  Future<void> _loadScanHistory({bool forceRefresh = false}) async {
    if (!forceRefresh && _scanHistory.isNotEmpty) {
      return;
    }

    try {
      setState(() {
        _isLoading = !forceRefresh;
        _error = null;
      });

      // Try to load from cache first if not forcing refresh
      if (!forceRefresh) {
        _loadFromCache();
      }

      // Get clinic ID (for future API calls)
      final prefs = await SharedPreferences.getInstance();
      final clinicId = prefs.getString('clinic_id') ?? 'clinic123';
      debugPrint('Using clinic ID: $clinicId');

      // Get today's date (for future API calls)
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      debugPrint('Loading scans for date: $today');

      // TODO(api): Replace with actual API call
      // final response = await _dio.get('/clinics/$clinicId/scans',
      //   queryParameters: {'date': today}
      // );

      // Simulate API response
      await Future.delayed(const Duration(seconds: 1));

      final mockData = _generateMockData();

      // Process and update data
      _scanHistory
        ..clear()
        ..addAll(mockData);
      _calculateTotals();

      // Save to cache
      await _saveToCache();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading scan history: $e');
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar histórico: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Generate mock data for testing
  List<ScanHistoryItem> _generateMockData() {
    final now = DateTime.now();
    return [
      ScanHistoryItem(
        id: 'scan1',
        patientName: 'João Silva',
        patientId: 'patient1',
        serviceName: 'Consulta Geral',
        creditCost: 1,
        scanTime: now.subtract(const Duration(minutes: 2)),
        status: 'active',
        canCancel: true,
      ),
      ScanHistoryItem(
        id: 'scan2',
        patientName: 'Maria Santos',
        patientId: 'patient2',
        serviceName: 'Exame de Sangue',
        creditCost: 2,
        scanTime: now.subtract(const Duration(hours: 1)),
        status: 'active',
        canCancel: false,
      ),
      ScanHistoryItem(
        id: 'scan3',
        patientName: 'Pedro Oliveira',
        patientId: 'patient3',
        serviceName: 'Raio-X',
        creditCost: 3,
        scanTime: now.subtract(const Duration(hours: 2)),
        status: 'active',
        canCancel: false,
      ),
      ScanHistoryItem(
        id: 'scan4',
        patientName: 'Ana Costa',
        patientId: 'patient4',
        serviceName: 'Ultrassonografia',
        creditCost: 4,
        scanTime: now.subtract(const Duration(hours: 3)),
        status: 'cancelled',
        canCancel: false,
      ),
    ];
  }

  /// Load data from cache
  void _loadFromCache() {
    try {
      final cachedData = _cacheBox.get('today_scans');
      if (cachedData != null) {
        final List<dynamic> jsonList = cachedData['data'] ?? [];
        _scanHistory
          ..clear()
          ..addAll(
            jsonList.map((json) => ScanHistoryItem.fromJson(json)).toList(),
          );
        _calculateTotals();
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }
  }

  /// Save data to cache
  Future<void> _saveToCache() async {
    try {
      await _cacheBox.put('today_scans', {
        'data': _scanHistory.map((item) => item.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  /// Calculate totals
  void _calculateTotals() {
    _totalScans = _scanHistory.where((item) => item.status == 'active').length;
    _totalCredits = _scanHistory
        .where((item) => item.status == 'active')
        .fold(0, (sum, item) => sum + item.creditCost);
  }

  /// Cancel a scan
  Future<void> _cancelScan(ScanHistoryItem item) async {
    try {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancelar Atendimento'),
          content: Text(
            'Deseja cancelar o atendimento de ${item.patientName}?\n'
            'Serviço: ${item.serviceName}\n'
            'Créditos: ${item.creditCost}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sim, Cancelar'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        return;
      }

      // TODO(api): Implement actual cancellation
      // await _dio.delete('/scans/${item.id}');

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Update local data
      final index = _scanHistory.indexWhere((s) => s.id == item.id);
      if (index != -1) {
        _scanHistory[index] = ScanHistoryItem(
          id: item.id,
          patientName: item.patientName,
          patientId: item.patientId,
          serviceName: item.serviceName,
          creditCost: item.creditCost,
          scanTime: item.scanTime,
          status: 'cancelled',
          canCancel: false,
        );
        _calculateTotals();
        await _saveToCache();
        setState(() {});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atendimento cancelado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cancelar atendimento: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Scans'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        // Totals card
        _buildTotalsCard(),

        // Scan list
        Expanded(child: _buildScanList()),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadScanHistory(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTotalItem(
            icon: Icons.qr_code_scanner,
            label: 'Atendimentos',
            value: _totalScans.toString(),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildTotalItem(
            icon: Icons.credit_card,
            label: 'Créditos',
            value: _totalCredits.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildScanList() {
    if (_scanHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum scan realizado hoje',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadScanHistory(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        itemCount: _scanHistory.length,
        itemBuilder: (context, index) {
          final item = _scanHistory[index];
          return _buildScanCard(item);
        },
      ),
    );
  }

  Widget _buildScanCard(ScanHistoryItem item) {
    final timeFormat = DateFormat('HH:mm');
    final isActive = item.status == 'active';

    return Dismissible(
      key: Key(item.id),
      direction: item.canCancel
          ? DismissDirection.endToStart
          : DismissDirection.none,
      onDismissed: (_) => _cancelScan(item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Time
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      timeFormat.format(item.scanTime),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Status
                  if (!isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Cancelado',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (item.canCancel)
                    Icon(Icons.swipe_left, size: 20, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              // Patient name
              Text(
                item.patientName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: isActive ? null : TextDecoration.lineThrough,
                  color: isActive ? null : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              // Service
              Row(
                children: [
                  Icon(
                    Icons.medical_services,
                    size: 16,
                    color: isActive ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.serviceName,
                    style: TextStyle(
                      fontSize: 14,
                      color: isActive ? Colors.grey[600] : Colors.grey[400],
                      decoration: isActive ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Credits
              Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    size: 16,
                    color: isActive ? Colors.green : Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.creditCost} crédito${item.creditCost > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.green : Colors.grey[400],
                      decoration: isActive ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cacheBox.close();
    super.dispose();
  }
}
