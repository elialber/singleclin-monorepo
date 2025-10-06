import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';
import 'package:singleclin_mobile/features/discovery/controllers/discovery_controller.dart';
import 'package:singleclin_mobile/features/discovery/controllers/map_controller.dart';
import 'package:singleclin_mobile/features/discovery/models/clinic.dart';
import 'package:singleclin_mobile/features/discovery/widgets/clinic_card.dart';

/// Map view screen with Google Maps integration and interactive markers
class MapViewScreen extends StatefulWidget {
  const MapViewScreen({required this.clinics, super.key, this.onClinicTap});
  final List<Clinic> clinics;
  final Function(Clinic)? onClinicTap;

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen>
    with TickerProviderStateMixin {
  final MapController mapController = Get.put(MapController());
  final DiscoveryController discoveryController =
      Get.find<DiscoveryController>();

  late AnimationController _bottomSheetController;
  late Animation<Offset> _bottomSheetAnimation;

  @override
  void initState() {
    super.initState();

    _bottomSheetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bottomSheetAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _bottomSheetController,
            curve: Curves.easeOut,
          ),
        );

    // Listen for selected clinic changes
    ever(mapController.selectedClinic, (Clinic? clinic) {
      if (clinic != null) {
        _bottomSheetController.forward();
      } else {
        _bottomSheetController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _bottomSheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildTopControls(),
          _buildBottomControls(),
          _buildSelectedClinicBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Obx(() {
      return GoogleMap(
        mapType: mapController.mapType,
        markers: Set<Marker>.from(mapController.markers.values),
        onMapCreated: mapController.onMapCreated,
        onCameraMove: mapController.onCameraMove,
        onTap: (_) => mapController.clearSelection(),
        initialCameraPosition: const CameraPosition(
          target: LatLng(-23.5505, -46.6333), // São Paulo center
          zoom: 14.0,
        ),
        myLocationEnabled: mapController.showUserLocation,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        minMaxZoomPreference: const MinMaxZoomPreference(10.0, 18.0),
        style: '''
          [
            {
              "featureType": "poi.business",
              "stylers": [{"visibility": "off"}]
            },
            {
              "featureType": "transit",
              "stylers": [{"visibility": "off"}]
            }
          ]
        ''',
      );
    });
  }

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.layers,
            onPressed: mapController.toggleMapType,
            tooltip: 'Tipo do mapa',
          ),
          const SizedBox(height: 8),
          Obx(
            () => _buildControlButton(
              icon: mapController.showClustering
                  ? Icons.scatter_plot
                  : Icons.place,
              onPressed: mapController.toggleClustering,
              tooltip: mapController.showClustering ? 'Desagrupar' : 'Agrupar',
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => _buildControlButton(
              icon: mapController.showUserLocation
                  ? Icons.my_location
                  : Icons.location_disabled,
              onPressed: mapController.toggleUserLocation,
              tooltip: 'Minha localização',
              backgroundColor: mapController.showUserLocation
                  ? AppColors.primary
                  : Colors.white,
              iconColor: mapController.showUserLocation
                  ? Colors.white
                  : AppColors.mediumGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 100,
      right: 16,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.add,
            onPressed: mapController.zoomIn,
            tooltip: 'Ampliar',
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.remove,
            onPressed: mapController.zoomOut,
            tooltip: 'Reduzir',
          ),
          const SizedBox(height: 16),
          _buildControlButton(
            icon: Icons.center_focus_strong,
            onPressed: () async {
              final userLocation = discoveryController.userLocation;
              if (userLocation != null) {
                await mapController.animateToLocation(
                  LatLng(userLocation.latitude, userLocation.longitude),
                  14.0,
                );
              }
            },
            tooltip: 'Centralizar',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor ?? AppColors.mediumGrey, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }

  Widget _buildSelectedClinicBottomSheet() {
    return Obx(() {
      final selectedClinic = mapController.selectedClinic;
      if (selectedClinic == null) return const SizedBox.shrink();

      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: SlideTransition(
          position: _bottomSheetAnimation,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Clinic card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClinicCard(
                    clinic: selectedClinic,
                    onTap: () {
                      widget.onClinicTap?.call(selectedClinic);
                    },
                    onFavoritePressed: () {
                      discoveryController.toggleClinicFavorite(
                        selectedClinic.id,
                      );
                    },
                  ),
                ),
                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openDirections(selectedClinic),
                          icon: const Icon(Icons.directions),
                          label: const Text('Direções'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.onClinicTap?.call(selectedClinic);
                          },
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Ver Detalhes'),
                        ),
                      ),
                    ],
                  ),
                ),
                // Safe area bottom padding
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _openDirections(Clinic clinic) {
    // This would open the default maps app with directions
    // For now, just show a message
    Get.snackbar(
      'Direções',
      'Abrindo direções para ${clinic.name}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
