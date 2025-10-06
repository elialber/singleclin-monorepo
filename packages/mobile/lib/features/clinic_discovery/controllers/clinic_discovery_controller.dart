import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/features/clinic_discovery/models/clinic.dart';
import 'package:singleclin_mobile/features/clinic_discovery/services/clinic_discovery_service.dart';

class ClinicDiscoveryController extends GetxController {
  final ClinicDiscoveryService _clinicService = ClinicDiscoveryService();

  // Observable states
  final _isLoading = false.obs;
  final _isLoadingLocation = true.obs;
  final _clinics = <Clinic>[].obs;
  final _filteredClinics = <Clinic>[].obs;
  final _selectedSpecializations = <String>[].obs;
  final _availableSpecializations = <String>[].obs;

  // Search controller
  final searchController = TextEditingController();

  // User location
  Position? _currentPosition;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isLoadingLocation => _isLoadingLocation.value;
  List<Clinic> get clinics => _clinics;
  List<Clinic> get filteredClinics => _filteredClinics;
  List<String> get selectedSpecializations => _selectedSpecializations;
  List<String> get availableSpecializations => _availableSpecializations;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> _initializeData() async {
    _isLoading.value = true;

    try {
      // Get user location and load clinics in parallel
      await Future.wait([_getCurrentLocation(), _loadClinics()]);

      // Update clinics with distance if location is available
      if (_currentPosition != null) {
        await _updateClinicsWithDistance();
      }

      _extractSpecializations();
      _filterClinics();
    } catch (e) {
      _handleError('Erro ao carregar clínicas: $e');
    } finally {
      _isLoading.value = false;
      _isLoadingLocation.value = false;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied.');
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadClinics() async {
    try {
      final loadedClinics = await _clinicService.getNearbyClinics(
        position: _currentPosition,
      );
      _clinics.assignAll(loadedClinics);
    } catch (e) {
      throw Exception('Falha ao carregar clínicas');
    }
  }

  Future<void> _updateClinicsWithDistance() async {
    if (_currentPosition == null) return;

    final updatedClinics = await Future.wait(
      _clinics.map((clinic) async {
        final distance =
            Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              clinic.coordinates.latitude,
              clinic.coordinates.longitude,
            ) /
            1000; // Convert to kilometers

        return Clinic(
          id: clinic.id,
          name: clinic.name,
          address: clinic.address,
          distance: distance,
          rating: clinic.rating,
          reviewCount: clinic.reviewCount,
          specializations: clinic.specializations,
          imageUrl: clinic.imageUrl,
          images: clinic.images,
          isAvailable: clinic.isAvailable,
          nextAvailableSlot: clinic.nextAvailableSlot,
          type: clinic.type,
          services: clinic.services,
          contact: clinic.contact,
          coordinates: clinic.coordinates,
          isPartner: clinic.isPartner,
          description: clinic.description,
        );
      }),
    );

    // Sort by distance
    updatedClinics.sort((a, b) => a.distance.compareTo(b.distance));
    _clinics.assignAll(updatedClinics);
  }

  void _extractSpecializations() {
    final Set<String> specializations = {};
    for (final clinic in _clinics) {
      specializations.addAll(clinic.specializations);
    }

    final sortedSpecializations = specializations.toList()..sort();
    _availableSpecializations.assignAll(sortedSpecializations);

    // Debug: Print extracted categories for verification
    print('🏷️ Extracted service categories for quick filters:');
    for (final String category in sortedSpecializations) {
      print('  - $category');
    }
    print('📊 Total categories found: ${sortedSpecializations.length}');
  }

  void searchClinics(String query) {
    _filterClinics(searchQuery: query);
  }

  void addSpecializationFilter(String specialization) {
    if (!_selectedSpecializations.contains(specialization)) {
      _selectedSpecializations.add(specialization);
      print('🏷️ Filtro adicionado: $specialization');
      print('📋 Filtros ativos: ${_selectedSpecializations.toList()}');
      _filterClinics();
    }
  }

  void removeSpecializationFilter(String specialization) {
    _selectedSpecializations.remove(specialization);
    print('🗑️ Filtro removido: $specialization');
    print('📋 Filtros ativos: ${_selectedSpecializations.toList()}');
    _filterClinics();
  }

  void clearFilters() {
    _selectedSpecializations.clear();
    searchController.clear();
    _filterClinics();
  }

  void _filterClinics({String? searchQuery}) {
    final query = searchQuery ?? searchController.text.toLowerCase();

    print('🔍 Filtrando clínicas...');
    print('📝 Query de busca: "$query"');
    print(
      '🏷️ Filtros de categoria ativos: ${_selectedSpecializations.toList()}',
    );
    print('🏥 Total de clínicas: ${_clinics.length}');

    final List<Clinic> filtered = _clinics.where((clinic) {
      // Text search filter
      final bool matchesSearch =
          query.isEmpty ||
          clinic.name.toLowerCase().contains(query) ||
          clinic.address.toLowerCase().contains(query) ||
          clinic.specializations.any(
            (spec) => spec.toLowerCase().contains(query),
          ) ||
          clinic.services.any(
            (service) => (service['name'] ?? '').toLowerCase().contains(query),
          );

      // Specialization filter
      final bool matchesSpecialization =
          _selectedSpecializations.isEmpty ||
          clinic.specializations.any(_selectedSpecializations.contains);

      final bool passes = matchesSearch && matchesSpecialization;

      if (_selectedSpecializations.isNotEmpty) {
        print(
          '  📍 ${clinic.name}: categorias = ${clinic.specializations}, passa filtro = $passes',
        );
      }

      return passes;
    }).toList();

    // Sort filtered results
    filtered.sort((a, b) {
      // Prioritize available clinics
      if (a.isAvailable && !b.isAvailable) return -1;
      if (!a.isAvailable && b.isAvailable) return 1;

      // Then by distance if location is available
      if (_currentPosition != null) {
        return a.distance.compareTo(b.distance);
      }

      // Finally by rating
      return b.rating.compareTo(a.rating);
    });

    _filteredClinics.assignAll(filtered);

    print('✅ Filtragem concluída: ${filtered.length} clínicas encontradas');
    if (_selectedSpecializations.isNotEmpty) {
      print(
        '📊 Clínicas filtradas por categoria: ${filtered.map((c) => c.name).toList()}',
      );
    }
  }

  Future<void> refreshClinics() async {
    await _initializeData();
    Get.snackbar(
      'Atualizado',
      'Lista de clínicas atualizada com sucesso',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<List<Clinic>> searchClinicsByName(String name) async {
    try {
      return await _clinicService.searchClinicsByName(name);
    } catch (e) {
      _handleError('Erro na busca: $e');
      return [];
    }
  }

  Future<List<Clinic>> getClinicsBySpecialization(String specialization) async {
    try {
      return await _clinicService.getClinicsBySpecialization(specialization);
    } catch (e) {
      _handleError('Erro ao filtrar especialização: $e');
      return [];
    }
  }

  Future<void> requestLocationPermission() async {
    try {
      final LocationPermission permission =
          await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        await _getCurrentLocation();
        await _updateClinicsWithDistance();
        _filterClinics();

        Get.snackbar(
          'Localização',
          'Clínicas ordenadas por proximidade',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      _handleError('Erro ao solicitar permissão de localização: $e');
    }
  }

  void _handleError(String message) {
    print(message);
    Get.snackbar(
      'Erro',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // Analytics methods
  void trackClinicView(String clinicId) {
    // Implement analytics tracking
    print('Clinic viewed: $clinicId');
  }

  void trackSearchQuery(String query) {
    // Implement analytics tracking
    print('Search query: $query');
  }

  void trackSpecializationFilter(String specialization) {
    // Implement analytics tracking
    print('Specialization filtered: $specialization');
  }
}
