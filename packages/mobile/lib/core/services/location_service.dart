import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../constants/app_constants.dart';

class LocationService extends GetxService {
  // Observable properties
  final Rx<Position?> _currentPosition = Rx<Position?>(null);
  final RxBool _isLocationEnabled = false.obs;
  final RxBool _hasPermission = false.obs;
  final RxBool _isLoading = false.obs;

  // Getters
  Position? get currentPosition => _currentPosition.value;
  bool get isLocationEnabled => _isLocationEnabled.value;
  bool get hasPermission => _hasPermission.value;
  bool get isLoading => _isLoading.value;

  double get currentLatitude => _currentPosition.value?.latitude ?? AppConstants.defaultLatitude;
  double get currentLongitude => _currentPosition.value?.longitude ?? AppConstants.defaultLongitude;

  @override
  void onInit() {
    super.onInit();
    _checkLocationServices();
  }

  /// Verificar serviços de localização
  Future<void> _checkLocationServices() async {
    try {
      _isLoading.value = true;
      
      // Verificar se o GPS está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _isLocationEnabled.value = serviceEnabled;

      if (!serviceEnabled) {
        return;
      }

      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      _hasPermission.value = permission == LocationPermission.always ||
                            permission == LocationPermission.whileInUse;

    } catch (e) {
      print('Erro ao verificar serviços de localização: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Solicitar permissões de localização
  Future<bool> requestPermission() async {
    try {
      _isLoading.value = true;

      // Verificar se o serviço está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Pedir para habilitar o GPS
        serviceEnabled = await Geolocator.openLocationSettings();
        if (!serviceEnabled) {
          return false;
        }
      }
      _isLocationEnabled.value = serviceEnabled;

      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied
        _hasPermission.value = false;
        return false;
      }

      _hasPermission.value = permission == LocationPermission.always ||
                            permission == LocationPermission.whileInUse;

      return _hasPermission.value;

    } catch (e) {
      print('Erro ao solicitar permissões: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Obter localização atual
  Future<Position?> getCurrentPosition() async {
    try {
      _isLoading.value = true;

      // Verificar permissões primeiro
      if (!_hasPermission.value) {
        final hasPermission = await requestPermission();
        if (!hasPermission) {
          return null;
        }
      }

      // Obter posição atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition.value = position;
      return position;

    } catch (e) {
      print('Erro ao obter localização atual: $e');
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Obter localização contínua
  Stream<Position> getPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Atualizar a cada 10 metros
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Calcular distância entre duas coordenadas
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Converter para km
  }

  /// Calcular distância da posição atual
  double calculateDistanceFromCurrent({
    required double latitude,
    required double longitude,
  }) {
    if (_currentPosition.value == null) return 0.0;

    return calculateDistance(
      startLatitude: currentLatitude,
      startLongitude: currentLongitude,
      endLatitude: latitude,
      endLongitude: longitude,
    );
  }

  /// Obter endereço a partir das coordenadas (geocoding reverso)
  Future<String?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}';
      }
    } catch (e) {
      print('Erro no geocoding reverso: $e');
    }
    return null;
  }

  /// Obter coordenadas a partir do endereço (geocoding)
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        Location location = locations[0];
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    } catch (e) {
      print('Erro no geocoding: $e');
    }
    return null;
  }

  /// Verificar se está próximo de uma localização
  bool isNearLocation({
    required double latitude,
    required double longitude,
    double radiusInKm = 1.0,
  }) {
    if (_currentPosition.value == null) return false;

    double distance = calculateDistanceFromCurrent(
      latitude: latitude,
      longitude: longitude,
    );

    return distance <= radiusInKm;
  }

  /// Obter localização usando endereço padrão se necessário
  Future<Position> getLocationOrDefault() async {
    Position? position = await getCurrentPosition();
    
    if (position != null) {
      return position;
    } else {
      // Retornar localização padrão (São Paulo)
      return Position(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  /// Abrir configurações de localização
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Abrir configurações do app
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}

