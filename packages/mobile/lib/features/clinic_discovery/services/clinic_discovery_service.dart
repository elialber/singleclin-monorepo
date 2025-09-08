import 'package:geolocator/geolocator.dart';
import '../models/clinic.dart';
import '../../../data/services/clinic_api_service.dart';

class ClinicDiscoveryService {
  final ClinicApiService _clinicApiService = ClinicApiService();
  
  // Cache for clinics to avoid excessive API calls
  List<Clinic>? _cachedClinics;
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // Mock data for demonstration - will be replaced with API calls
  static final List<Clinic> _mockClinics = [
    Clinic(
      id: '1',
      name: 'Clínica São João',
      address: 'Rua das Flores, 123 - Centro',
      distance: 2.1,
      rating: 4.8,
      reviewCount: 145,
      specializations: ['Cardiologia', 'Clínica Geral', 'Pediatria'],
      imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=400',
      isAvailable: true,
      nextAvailableSlot: DateTime.now().add(const Duration(hours: 2)),
      type: ClinicType.partner,
      services: ['Consulta', 'Exames', 'Procedimentos'],
      contact: const ContactInfo(
        phone: '(11) 3456-7890',
        email: 'contato@clinicasaojoao.com.br',
        whatsapp: '(11) 98765-4321',
        website: 'https://clinicasaojoao.com.br',
      ),
      coordinates: const Location(latitude: -23.5505, longitude: -46.6333),
      isPartner: true,
      description: 'Clínica moderna com atendimento humanizado e tecnologia de ponta.',
    ),
    Clinic(
      id: '2',
      name: 'Hospital Santa Maria',
      address: 'Av. Paulista, 567 - Bela Vista',
      distance: 4.3,
      rating: 4.6,
      reviewCount: 289,
      specializations: ['Neurologia', 'Ortopedia', 'Cardiologia'],
      imageUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=400',
      isAvailable: true,
      nextAvailableSlot: DateTime.now().add(const Duration(hours: 4)),
      type: ClinicType.origin,
      services: ['Consulta', 'Cirurgia', 'UTI', 'Pronto Socorro'],
      contact: const ContactInfo(
        phone: '(11) 2345-6789',
        email: 'atendimento@santamaria.com.br',
        whatsapp: '(11) 99876-5432',
      ),
      coordinates: const Location(latitude: -23.5618, longitude: -46.6565),
      isPartner: false,
      description: 'Hospital referência em alta complexidade na região metropolitana.',
    ),
    Clinic(
      id: '3',
      name: 'Centro Médico Esperança',
      address: 'Rua da Consolação, 890 - Consolação',
      distance: 1.8,
      rating: 4.9,
      reviewCount: 67,
      specializations: ['Dermatologia', 'Ginecologia', 'Oftalmologia'],
      imageUrl: 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=400',
      isAvailable: true,
      nextAvailableSlot: DateTime.now().add(const Duration(hours: 1)),
      type: ClinicType.partner,
      services: ['Consulta', 'Exames Estéticos', 'Laser'],
      contact: const ContactInfo(
        phone: '(11) 3333-4444',
        email: 'agendamento@esperanca.med.br',
        whatsapp: '(11) 97777-8888',
      ),
      coordinates: const Location(latitude: -23.5431, longitude: -46.6291),
      isPartner: true,
      description: 'Centro especializado em cuidados estéticos e saúde da mulher.',
    ),
    Clinic(
      id: '4',
      name: 'Clínica Vida & Saúde',
      address: 'Rua Augusta, 1234 - Jardins',
      distance: 3.2,
      rating: 4.5,
      reviewCount: 198,
      specializations: ['Psiquiatria', 'Psicologia', 'Neurologia'],
      imageUrl: 'https://images.unsplash.com/photo-1559757175-0eb30cd8c063?w=400',
      isAvailable: false,
      nextAvailableSlot: DateTime.now().add(const Duration(days: 1)),
      type: ClinicType.partner,
      services: ['Consulta', 'Terapia', 'Grupos Terapêuticos'],
      contact: const ContactInfo(
        phone: '(11) 4444-5555',
        email: 'contato@vidasaude.com.br',
        whatsapp: '(11) 96666-7777',
      ),
      coordinates: const Location(latitude: -23.5558, longitude: -46.6396),
      isPartner: true,
      description: 'Especializada em saúde mental e bem-estar emocional.',
    ),
    Clinic(
      id: '5',
      name: 'Instituto Cardio Plus',
      address: 'Al. Santos, 456 - Paraíso',
      distance: 5.7,
      rating: 4.7,
      reviewCount: 312,
      specializations: ['Cardiologia', 'Hemodinâmica', 'Cirurgia Cardíaca'],
      imageUrl: 'https://images.unsplash.com/photo-1551190822-a9333d879b1f?w=400',
      isAvailable: true,
      nextAvailableSlot: DateTime.now().add(const Duration(hours: 6)),
      type: ClinicType.origin,
      services: ['Consulta', 'Cateterismo', 'Cirurgia', 'Check-up'],
      contact: const ContactInfo(
        phone: '(11) 5555-6666',
        email: 'agendamento@cardioplus.com.br',
        whatsapp: '(11) 95555-4444',
      ),
      coordinates: const Location(latitude: -23.5781, longitude: -46.6459),
      isPartner: false,
      description: 'Instituto especializado em cardiologia e cirurgias cardíacas.',
    ),
    Clinic(
      id: '6',
      name: 'Clínica Ortopédica São Paulo',
      address: 'Rua Haddock Lobo, 321 - Cerqueira César',
      distance: 2.9,
      rating: 4.4,
      reviewCount: 156,
      specializations: ['Ortopedia', 'Fisioterapia', 'Traumatologia'],
      imageUrl: 'https://images.unsplash.com/photo-1584982751755-d86c8d132556?w=400',
      isAvailable: true,
      nextAvailableSlot: DateTime.now().add(const Duration(hours: 3)),
      type: ClinicType.partner,
      services: ['Consulta', 'Fisioterapia', 'Exames de Imagem'],
      contact: const ContactInfo(
        phone: '(11) 6666-7777',
        email: 'contato@ortopedicasp.com.br',
        whatsapp: '(11) 94444-3333',
      ),
      coordinates: const Location(latitude: -23.5489, longitude: -46.6388),
      isPartner: true,
      description: 'Especializada em tratamento de lesões e reabilitação.',
    ),
  ];

  Future<List<Clinic>> getNearbyClinics({Position? position}) async {
    try {
      // Check if we have cached data that's still valid
      if (_cachedClinics != null && 
          _lastFetchTime != null && 
          DateTime.now().difference(_lastFetchTime!) < _cacheExpiration) {
        print('📦 Using cached clinic data');
        return List.from(_cachedClinics!);
      }

      print('🌐 Fetching clinics from backend API...');
      
      // Fetch real clinics from backend
      final clinics = await _clinicApiService.getActiveClinics();
      
      // Cache the results
      _cachedClinics = clinics;
      _lastFetchTime = DateTime.now();
      
      print('✅ Fetched ${clinics.length} clinics from backend');
      
      // If no clinics from backend, fallback to mock data for demo purposes
      if (clinics.isEmpty) {
        print('⚠️ No clinics from backend, using fallback mock data');
        return List.from(_mockClinics);
      }
      
      return clinics;
    } catch (e) {
      print('❌ Error fetching clinics from backend: $e');
      // Fallback to mock data on error
      print('🔄 Falling back to mock data');
      return List.from(_mockClinics);
    }
  }

  Future<List<Clinic>> searchClinicsByName(String name) async {
    try {
      print('🔍 Searching clinics by name: $name');
      
      // Use API search if available
      final searchResults = await _clinicApiService.searchClinics(name);
      
      if (searchResults.isNotEmpty) {
        return searchResults;
      }
      
      // Fallback to local search in cached data
      final allClinics = await getNearbyClinics();
      final query = name.toLowerCase();
      
      return allClinics.where((clinic) {
        return clinic.name.toLowerCase().contains(query) ||
               clinic.address.toLowerCase().contains(query);
      }).toList();
    } catch (e) {
      print('❌ Error searching clinics: $e');
      // Fallback to mock search
      await Future.delayed(const Duration(milliseconds: 500));
      final query = name.toLowerCase();
      return _mockClinics.where((clinic) {
        return clinic.name.toLowerCase().contains(query) ||
               clinic.address.toLowerCase().contains(query);
      }).toList();
    }
  }

  Future<List<Clinic>> getClinicsBySpecialization(String specialization) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return _mockClinics.where((clinic) {
      return clinic.specializations.any((spec) =>
          spec.toLowerCase() == specialization.toLowerCase());
    }).toList();
  }

  Future<List<Clinic>> getAvailableClinics() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return _mockClinics.where((clinic) => clinic.isAvailable).toList();
  }

  Future<List<Clinic>> getFavoriteClinics(List<String> favoriteIds) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _mockClinics.where((clinic) =>
        favoriteIds.contains(clinic.id)).toList();
  }

  Future<Clinic?> getClinicById(String id) async {
    try {
      print('🏥 Fetching clinic by ID: $id');
      
      // Try to get from API first
      final clinic = await _clinicApiService.getClinicById(id);
      
      if (clinic != null) {
        return clinic;
      }
      
      // Fallback to cached data
      final allClinics = await getNearbyClinics();
      try {
        return allClinics.firstWhere((clinic) => clinic.id == id);
      } catch (e) {
        return null;
      }
    } catch (e) {
      print('❌ Error fetching clinic by ID: $e');
      // Fallback to mock data
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        return _mockClinics.firstWhere((clinic) => clinic.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  Future<List<String>> getAvailableSpecializations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final Set<String> specializations = {};
    for (final clinic in _mockClinics) {
      specializations.addAll(clinic.specializations);
    }
    
    return specializations.toList()..sort();
  }

  Future<List<Clinic>> getEmergencyClinics() async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Return clinics that are available now or have emergency services
    return _mockClinics.where((clinic) {
      return clinic.isAvailable && (
        clinic.services.any((service) =>
            service.toLowerCase().contains('urgência') ||
            service.toLowerCase().contains('pronto socorro') ||
            service.toLowerCase().contains('emergência')
        ) ||
        clinic.nextAvailableSlot?.isBefore(
          DateTime.now().add(const Duration(hours: 2))
        ) == true
      );
    }).toList();
  }

  // Method to update clinic availability - would typically call API
  Future<bool> updateClinicAvailability(String clinicId, bool isAvailable) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final clinicIndex = _mockClinics.indexWhere((c) => c.id == clinicId);
    if (clinicIndex != -1) {
      // In real implementation, this would be an API call
      // _mockClinics[clinicIndex] = _mockClinics[clinicIndex].copyWith(isAvailable: isAvailable);
      return true;
    }
    
    return false;
  }

  // Method to book appointment - would typically call API
  Future<bool> bookAppointment({
    required String clinicId,
    required DateTime dateTime,
    required String patientId,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Simulate booking logic
    final clinic = await getClinicById(clinicId);
    if (clinic != null && clinic.isAvailable) {
      return true; // Booking successful
    }
    
    return false; // Booking failed
  }

  /// Clear the clinic cache to force fresh data on next request
  void clearCache() {
    _cachedClinics = null;
    _lastFetchTime = null;
    print('🗑️ Clinic cache cleared');
  }

  /// Check if backend API is available
  Future<bool> isBackendAvailable() async {
    try {
      await _clinicApiService.getActiveClinics();
      return true;
    } catch (e) {
      return false;
    }
  }
}