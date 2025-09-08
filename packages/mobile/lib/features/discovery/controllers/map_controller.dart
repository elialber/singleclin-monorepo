import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/location_service.dart';
import '../../../core/constants/app_colors.dart';
import '../models/clinic.dart';
import '../models/filter_options.dart';
import 'discovery_controller.dart';

/// Map controller managing Google Maps integration and marker management
class MapController extends GetxController {
  final LocationService _locationService = Get.find<LocationService>();
  final DiscoveryController _discoveryController = Get.find<DiscoveryController>();

  // Map controller
  Completer<GoogleMapController>? _mapController;
  
  // Observables
  final _isMapReady = false.obs;
  final _currentZoomLevel = 14.0.obs;
  final _mapType = MapType.normal.obs;
  final _markers = <String, Marker>{}.obs;
  final _selectedClinic = Rxn<Clinic>();
  final _showUserLocation = true.obs;
  final _isFollowingUser = false.obs;
  final _clusterMarkers = <String, ClusterMarker>{}.obs;
  final _showClustering = true.obs;

  // Map style
  String? _mapStyle;

  // Custom marker icons
  BitmapDescriptor? _clinicMarkerIcon;
  BitmapDescriptor? _selectedClinicMarkerIcon;
  BitmapDescriptor? _userLocationIcon;
  BitmapDescriptor? _clusterMarkerIcon;

  // Clustering settings
  static const double _clusterDistance = 100.0; // pixels
  static const int _clusterMinSize = 2;

  // Camera settings
  static const double _defaultZoom = 14.0;
  static const double _maxZoom = 18.0;
  static const double _minZoom = 10.0;

  // Getters
  bool get isMapReady => _isMapReady.value;
  double get currentZoomLevel => _currentZoomLevel.value;
  MapType get mapType => _mapType.value;
  Map<String, Marker> get markers => _markers;
  Clinic? get selectedClinic => _selectedClinic.value;
  bool get showUserLocation => _showUserLocation.value;
  bool get isFollowingUser => _isFollowingUser.value;
  bool get showClustering => _showClustering.value;

  @override
  void onInit() {
    super.onInit();
    _initializeMap();
    
    // Listen to clinic updates from discovery controller
    ever(_discoveryController.filteredClinics, _updateMapMarkers);
    ever(_discoveryController.userLocation, _updateUserLocation);
  }

  @override
  void onClose() {
    _mapController = null;
    super.onClose();
  }

  /// Initialize map with custom styles and markers
  Future<void> _initializeMap() async {
    await Future.wait([
      _loadMapStyle(),
      _createCustomMarkers(),
    ]);
  }

  /// Load custom map style
  Future<void> _loadMapStyle() async {
    try {
      _mapStyle = await rootBundle.loadString('assets/map_style.json');
    } catch (e) {
      debugPrint('Não foi possível carregar estilo do mapa: $e');
    }
  }

  /// Create custom marker icons
  Future<void> _createCustomMarkers() async {
    try {
      await Future.wait([
        _createClinicMarkerIcon(),
        _createSelectedClinicMarkerIcon(),
        _createUserLocationIcon(),
        _createClusterMarkerIcon(),
      ]);
    } catch (e) {
      debugPrint('Erro ao criar marcadores customizados: $e');
    }
  }

  /// Map ready callback
  void onMapCreated(GoogleMapController controller) async {
    if (_mapController?.isCompleted == false) {
      _mapController!.complete(controller);
    }

    // Apply custom map style
    if (_mapStyle != null) {
      await controller.setMapStyle(_mapStyle);
    }

    _isMapReady.value = true;

    // Center map on user location or São Paulo as fallback
    await _centerMapOnUserLocation();
  }

  /// Center map on user's current location
  Future<void> _centerMapOnUserLocation() async {
    try {
      final userLocation = _discoveryController.userLocation;
      LatLng targetLocation;

      if (userLocation != null) {
        targetLocation = LatLng(userLocation.latitude, userLocation.longitude);
      } else {
        // Fallback to São Paulo center
        targetLocation = const LatLng(-23.5505, -46.6333);
      }

      await animateToLocation(targetLocation, _defaultZoom);
    } catch (e) {
      debugPrint('Erro ao centralizar mapa na localização: $e');
    }
  }

  /// Update markers when clinics change
  void _updateMapMarkers(List<Clinic> clinics) async {
    if (!_isMapReady.value) return;

    _markers.clear();
    _clusterMarkers.clear();

    if (_showClustering.value && clinics.length > 10) {
      await _createClusteredMarkers(clinics);
    } else {
      await _createIndividualMarkers(clinics);
    }
  }

  /// Create individual markers for each clinic
  Future<void> _createIndividualMarkers(List<Clinic> clinics) async {
    for (final clinic in clinics) {
      final marker = await _createClinicMarker(clinic);
      _markers[clinic.id] = marker;
    }
  }

  /// Create clustered markers for dense areas
  Future<void> _createClusteredMarkers(List<Clinic> clinics) async {
    final clusters = _createClusters(clinics);
    
    for (final cluster in clusters) {
      if (cluster.clinics.length == 1) {
        // Single clinic marker
        final marker = await _createClinicMarker(cluster.clinics.first);
        _markers[cluster.clinics.first.id] = marker;
      } else {
        // Cluster marker
        final marker = await _createClusterMarker(cluster);
        _markers[cluster.id] = marker;
      }
    }
  }

  /// Create marker for individual clinic
  Future<Marker> _createClinicMarker(Clinic clinic) async {
    final isSelected = _selectedClinic.value?.id == clinic.id;
    final icon = isSelected && _selectedClinicMarkerIcon != null
        ? _selectedClinicMarkerIcon!
        : _clinicMarkerIcon ?? BitmapDescriptor.defaultMarker;

    return Marker(
      markerId: MarkerId(clinic.id),
      position: LatLng(clinic.latitude, clinic.longitude),
      icon: icon,
      infoWindow: InfoWindow(
        title: clinic.name,
        snippet: '${clinic.priceRange} • ${clinic.formattedDistance}',
        onTap: () => _onMarkerTap(clinic),
      ),
      onTap: () => _onMarkerTap(clinic),
    );
  }

  /// Handle marker tap
  void _onMarkerTap(Clinic clinic) {
    _selectedClinic.value = clinic;
    
    // Update marker appearance
    _updateMapMarkers(_discoveryController.filteredClinics);
    
    // Animate camera to marker
    animateToLocation(
      LatLng(clinic.latitude, clinic.longitude),
      _currentZoomLevel.value,
    );
  }

  /// Handle cluster marker tap
  void _onClusterMarkerTap(ClusterMarker cluster) {
    // Calculate bounds for all clinics in cluster
    var minLat = cluster.clinics.first.latitude;
    var maxLat = cluster.clinics.first.latitude;
    var minLng = cluster.clinics.first.longitude;
    var maxLng = cluster.clinics.first.longitude;

    for (final clinic in cluster.clinics) {
      minLat = minLat < clinic.latitude ? minLat : clinic.latitude;
      maxLat = maxLat > clinic.latitude ? maxLat : clinic.latitude;
      minLng = minLng < clinic.longitude ? minLng : clinic.longitude;
      maxLng = maxLng > clinic.longitude ? maxLng : clinic.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    animateToLatLngBounds(bounds, EdgeInsets.all(100));
  }

  /// Animate camera to specific location
  Future<void> animateToLocation(LatLng location, double zoom) async {
    final controller = await _mapController?.future;
    if (controller != null) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: zoom),
        ),
      );
    }
  }

  /// Animate camera to bounds
  Future<void> animateToLatLngBounds(LatLngBounds bounds, EdgeInsets padding) async {
    final controller = await _mapController?.future;
    if (controller != null) {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    }
  }

  /// Toggle map type
  void toggleMapType() {
    switch (_mapType.value) {
      case MapType.normal:
        _mapType.value = MapType.satellite;
        break;
      case MapType.satellite:
        _mapType.value = MapType.hybrid;
        break;
      case MapType.hybrid:
        _mapType.value = MapType.terrain;
        break;
      case MapType.terrain:
        _mapType.value = MapType.normal;
        break;
    }
  }

  /// Toggle user location display
  void toggleUserLocation() {
    _showUserLocation.value = !_showUserLocation.value;
  }

  /// Toggle following user location
  void toggleFollowUser() {
    _isFollowingUser.value = !_isFollowingUser.value;
    if (_isFollowingUser.value) {
      _centerMapOnUserLocation();
    }
  }

  /// Toggle clustering
  void toggleClustering() {
    _showClustering.value = !_showClustering.value;
    _updateMapMarkers(_discoveryController.filteredClinics);
  }

  /// Zoom in
  Future<void> zoomIn() async {
    if (_currentZoomLevel.value < _maxZoom) {
      _currentZoomLevel.value = (_currentZoomLevel.value + 1).clamp(_minZoom, _maxZoom);
      final controller = await _mapController?.future;
      await controller?.animateCamera(
        CameraUpdate.zoomTo(_currentZoomLevel.value),
      );
    }
  }

  /// Zoom out
  Future<void> zoomOut() async {
    if (_currentZoomLevel.value > _minZoom) {
      _currentZoomLevel.value = (_currentZoomLevel.value - 1).clamp(_minZoom, _maxZoom);
      final controller = await _mapController?.future;
      await controller?.animateCamera(
        CameraUpdate.zoomTo(_currentZoomLevel.value),
      );
    }
  }

  /// Camera move callback
  void onCameraMove(CameraPosition position) {
    _currentZoomLevel.value = position.zoom;
    
    // Stop following user if camera moved manually
    if (_isFollowingUser.value) {
      _isFollowingUser.value = false;
    }
  }

  /// Update user location marker
  void _updateUserLocation(Position? position) {
    if (position == null || !_showUserLocation.value) return;

    if (_isFollowingUser.value) {
      animateToLocation(
        LatLng(position.latitude, position.longitude),
        _currentZoomLevel.value,
      );
    }
  }

  /// Clear selected clinic
  void clearSelection() {
    _selectedClinic.value = null;
    _updateMapMarkers(_discoveryController.filteredClinics);
  }

  /// Get visible region bounds
  Future<LatLngBounds?> getVisibleRegion() async {
    final controller = await _mapController?.future;
    return await controller?.getVisibleRegion();
  }

  /// Private helper methods for markers

  Future<void> _createClinicMarkerIcon() async {
    _clinicMarkerIcon = await _createCustomIcon(
      color: AppColors.primary,
      size: 120,
      text: null,
    );
  }

  Future<void> _createSelectedClinicMarkerIcon() async {
    _selectedClinicMarkerIcon = await _createCustomIcon(
      color: AppColors.sgPrimary,
      size: 140,
      text: null,
    );
  }

  Future<void> _createUserLocationIcon() async {
    _userLocationIcon = await _createCustomIcon(
      color: Colors.blue,
      size: 80,
      text: null,
    );
  }

  Future<void> _createClusterMarkerIcon() async {
    _clusterMarkerIcon = await _createCustomIcon(
      color: AppColors.primaryDark,
      size: 100,
      text: null,
    );
  }

  Future<Marker> _createClusterMarker(ClusterMarker cluster) async {
    final icon = await _createCustomIcon(
      color: AppColors.primaryDark,
      size: 120,
      text: cluster.clinics.length.toString(),
    );

    return Marker(
      markerId: MarkerId(cluster.id),
      position: cluster.center,
      icon: icon,
      infoWindow: InfoWindow(
        title: '${cluster.clinics.length} clínicas',
        snippet: 'Toque para expandir',
        onTap: () => _onClusterMarkerTap(cluster),
      ),
      onTap: () => _onClusterMarkerTap(cluster),
    );
  }

  Future<BitmapDescriptor> _createCustomIcon({
    required Color color,
    required double size,
    String? text,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw circle
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, paint);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, strokePaint);

    // Draw text if provided
    if (text != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size - textPainter.width) / 2,
          (size - textPainter.height) / 2,
        ),
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  /// Clustering algorithm
  List<ClusterMarker> _createClusters(List<Clinic> clinics) {
    final clusters = <ClusterMarker>[];
    final processed = <String>{};

    for (int i = 0; i < clinics.length; i++) {
      if (processed.contains(clinics[i].id)) continue;

      final cluster = ClusterMarker(
        id: 'cluster_${clusters.length}',
        clinics: [clinics[i]],
        center: LatLng(clinics[i].latitude, clinics[i].longitude),
      );

      // Find nearby clinics
      for (int j = i + 1; j < clinics.length; j++) {
        if (processed.contains(clinics[j].id)) continue;

        final distance = Geolocator.distanceBetween(
          clinics[i].latitude,
          clinics[i].longitude,
          clinics[j].latitude,
          clinics[j].longitude,
        );

        // If within clustering distance (converted from pixels to meters approximation)
        if (distance < _clusterDistance * 10) {
          cluster.clinics.add(clinics[j]);
          processed.add(clinics[j].id);
        }
      }

      processed.add(clinics[i].id);

      // Calculate cluster center
      if (cluster.clinics.length > 1) {
        double avgLat = 0, avgLng = 0;
        for (final clinic in cluster.clinics) {
          avgLat += clinic.latitude;
          avgLng += clinic.longitude;
        }
        cluster.center = LatLng(
          avgLat / cluster.clinics.length,
          avgLng / cluster.clinics.length,
        );
      }

      clusters.add(cluster);
    }

    return clusters;
  }
}

/// Cluster marker model
class ClusterMarker {
  final String id;
  final List<Clinic> clinics;
  LatLng center;

  ClusterMarker({
    required this.id,
    required this.clinics,
    required this.center,
  });
}