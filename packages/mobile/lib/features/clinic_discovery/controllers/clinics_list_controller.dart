import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:singleclin_mobile/features/clinic_discovery/models/clinic.dart';
import 'package:singleclin_mobile/features/clinic_services/services/clinic_services_api.dart';

class ClinicsListController extends GetxController {
  final RxList<Clinic> _allClinics = <Clinic>[].obs;
  final RxList<Clinic> clinics = <Clinic>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;
  Position? userLocation;

  @override
  void onInit() {
    super.onInit();
    _getUserLocation();
    loadClinics();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ Location permissions are permanently denied');
        return;
      }

      userLocation = await Geolocator.getCurrentPosition();
      print('📍 User location: ${userLocation?.latitude}, ${userLocation?.longitude}');
      
      // Recalcular distâncias
      if (_allClinics.isNotEmpty) {
        _calculateDistances();
      }
    } catch (e) {
      print('❌ Error getting user location: $e');
    }
  }

  void _calculateDistances() {
    if (userLocation == null) return;

    for (var clinic in _allClinics) {
      if (clinic.coordinates.latitude != 0 && clinic.coordinates.longitude != 0) {
        final distance = Geolocator.distanceBetween(
          userLocation!.latitude,
          userLocation!.longitude,
          clinic.coordinates.latitude,
          clinic.coordinates.longitude,
        );
        // Converter para km
        clinic.distance = distance / 1000;
      }
    }

    // Ordenar por distância
    _allClinics.sort((a, b) => a.distance.compareTo(b.distance));
    _applyFilters();
  }

  Future<void> loadClinics() async {
    try {
      isLoading.value = true;
      error.value = '';

      final loadedClinics = await ClinicServicesApi.getClinics();
      _allClinics.value = loadedClinics;
      
      if (userLocation != null) {
        _calculateDistances();
      } else {
        clinics.value = _allClinics;
      }
    } catch (e) {
      error.value = 'Erro ao carregar clínicas: $e';
      clinics.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query.toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    if (searchQuery.value.isEmpty) {
      clinics.value = _allClinics;
    } else {
      clinics.value = _allClinics.where((clinic) {
        final nameMatch = clinic.name.toLowerCase().contains(searchQuery.value);
        final specializationMatch = clinic.specializations.any(
          (spec) => spec.toLowerCase().contains(searchQuery.value),
        );
        return nameMatch || specializationMatch;
      }).toList();
    }
  }
}

