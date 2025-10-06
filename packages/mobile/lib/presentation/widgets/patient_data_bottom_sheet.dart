import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bottom sheet widget to display patient data after successful QR scan
class PatientDataBottomSheet extends StatefulWidget {
  const PatientDataBottomSheet({
    required this.qrCode,
    required this.onConfirm,
    super.key,
  });
  final String qrCode;
  final Function(String serviceId) onConfirm;

  @override
  State<PatientDataBottomSheet> createState() => _PatientDataBottomSheetState();
}

class _PatientDataBottomSheetState extends State<PatientDataBottomSheet> {
  final Dio _dio = Dio();
  bool _isLoadingPatient = true;
  bool _isLoadingServices = true;
  bool _isProcessing = false;
  String? _error;

  // Patient data
  late Map<String, dynamic>? _patientData;
  String? _patientName;
  String? _patientPhoto;
  String? _activePlan;
  int _remainingCredits = 0;

  // Services data
  List<Map<String, dynamic>> _services = [];
  String? _selectedServiceId;

  @override
  void initState() {
    super.initState();
    _setupDio();
    _loadData();
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

  /// Load both patient data and clinic services
  Future<void> _loadData() async {
    await Future.wait([_loadPatientData(), _loadClinicServices()]);
  }

  /// Load patient data from QR code
  Future<void> _loadPatientData() async {
    try {
      setState(() {
        _isLoadingPatient = true;
        _error = null;
      });

      // Extract user ID from QR code format: USR-{userId}-{timestamp}
      final parts = widget.qrCode.split('-');
      if (parts.length < 3 || parts[0] != 'USR') {
        throw Exception('Formato de QR code inválido');
      }

      final userId = parts[1];

      // TODO(api): Replace with actual endpoint when available
      // For now, simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Simulated response
      _patientData = {
        'id': userId,
        'name': 'João Silva',
        'email': 'joao.silva@email.com',
        'photo': null, // TODO(api): Add photo URL when available
        'activePlan': {
          'id': 'plan123',
          'name': 'Plano Premium',
          'remainingCredits': 15,
          'totalCredits': 20,
        },
      };

      if (mounted) {
        setState(() {
          final patientMap = _patientData!;
          _patientName = patientMap['name'] as String?;
          _patientPhoto = patientMap['photo'] as String?;
          final activePlanData =
              patientMap['activePlan'] as Map<String, dynamic>?;
          _activePlan = activePlanData?['name'] as String?;
          _remainingCredits =
              (activePlanData?['remainingCredits'] as int?) ?? 0;
          _isLoadingPatient = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar dados do paciente: ${e.toString()}';
          _isLoadingPatient = false;
        });
      }
    }
  }

  /// Load available services from clinic
  Future<void> _loadClinicServices() async {
    try {
      setState(() {
        _isLoadingServices = true;
      });

      // Get clinic ID from preferences for future API implementation
      final prefs = await SharedPreferences.getInstance();
      final clinicId = prefs.getString('clinic_id') ?? 'clinic123';
      debugPrint('Loading services for clinic: $clinicId');

      // TODO(api): Replace with actual endpoint when available
      // For now, simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Simulated response
      _services = [
        {
          'id': 'service1',
          'name': 'Consulta Geral',
          'creditCost': 1,
          'description': 'Consulta médica geral',
        },
        {
          'id': 'service2',
          'name': 'Exame de Sangue',
          'creditCost': 2,
          'description': 'Coleta e análise de sangue',
        },
        {
          'id': 'service3',
          'name': 'Raio-X',
          'creditCost': 3,
          'description': 'Exame de raio-x digital',
        },
        {
          'id': 'service4',
          'name': 'Ultrassonografia',
          'creditCost': 4,
          'description': 'Exame de ultrassom',
        },
      ];

      if (mounted) {
        setState(() {
          _isLoadingServices = false;
          // Pre-select first service if available
          if (_services.isNotEmpty) {
            _selectedServiceId = _services.first['id'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar serviços: ${e.toString()}';
          _isLoadingServices = false;
        });
      }
    }
  }

  /// Get selected service details
  Map<String, dynamic>? get _selectedService {
    if (_selectedServiceId == null) {
      return null;
    }
    return _services.firstWhere(
      (s) => s['id'] == _selectedServiceId,
      orElse: () => {},
    );
  }

  /// Handle service selection
  void _onServiceChanged(String? serviceId) {
    setState(() {
      _selectedServiceId = serviceId;
    });
  }

  /// Handle attendance confirmation
  Future<void> _confirmAttendance() async {
    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um serviço para continuar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedService = _selectedService;
    if (selectedService == null) {
      return;
    }

    final creditCost = selectedService['creditCost'] as int;

    // Check if patient has enough credits
    if (_remainingCredits < creditCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Paciente não possui créditos suficientes. '
            'Necessário: $creditCost, Disponível: $_remainingCredits',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Call the onConfirm callback with selected service
      await widget.onConfirm(_selectedServiceId!);

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao confirmar atendimento: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dados do Paciente',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: _buildContent()),

          // Bottom actions
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return _buildErrorState();
    }

    if (_isLoadingPatient || _isLoadingServices) {
      return _buildLoadingState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient info card
          _buildPatientCard(),
          const SizedBox(height: 24),

          // Service selection
          _buildServiceSelection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Carregando dados...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
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
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Patient photo
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.1),
              backgroundImage: _patientPhoto != null
                  ? NetworkImage(_patientPhoto!)
                  : null,
              child: _patientPhoto == null
                  ? Text(
                      _patientName?.substring(0, 1).toUpperCase() ?? '?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Patient info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _patientName ?? 'Nome não disponível',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_activePlan != null) ...[
                    Text(
                      _activePlan!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _remainingCredits > 0
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 16,
                          color: _remainingCredits > 0
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_remainingCredits créditos',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _remainingCredits > 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecione o serviço',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Service dropdown
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedServiceId,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              hint: const Text('Escolha um serviço'),
              items: _services.map((service) {
                final creditCost = service['creditCost'] as int;
                final canAfford = _remainingCredits >= creditCost;

                return DropdownMenuItem<String>(
                  value: service['id'],
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              service['name'],
                              style: TextStyle(
                                fontSize: 16,
                                color: canAfford ? null : Colors.grey,
                              ),
                            ),
                            if (service['description'] != null)
                              Text(
                                service['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: canAfford
                              ? Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$creditCost crédito${creditCost > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: canAfford
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _onServiceChanged,
            ),
          ),
        ),

        // Selected service details
        if (_selectedService != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custo do serviço: ${_selectedService!['creditCost'] as int} crédito${(_selectedService!['creditCost'] as int) > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Créditos após atendimento: ${_remainingCredits - (_selectedService!['creditCost'] as int)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing
                    ? null
                    : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _confirmAttendance,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Confirmar Atendimento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
