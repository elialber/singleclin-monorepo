import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';
import 'package:singleclin_mobile/features/discovery/controllers/booking_controller.dart';
import 'package:singleclin_mobile/features/discovery/controllers/discovery_controller.dart';
import 'package:singleclin_mobile/features/discovery/models/clinic.dart';
import 'package:singleclin_mobile/features/discovery/models/service.dart';
import 'package:singleclin_mobile/features/discovery/screens/booking_screen.dart';
import 'package:singleclin_mobile/features/discovery/widgets/service_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// Clinic details screen with gallery, services, and booking CTA
class ClinicDetailsScreen extends StatefulWidget {
  const ClinicDetailsScreen({required this.clinic, super.key});
  final Clinic clinic;

  @override
  State<ClinicDetailsScreen> createState() => _ClinicDetailsScreenState();
}

class _ClinicDetailsScreenState extends State<ClinicDetailsScreen>
    with SingleTickerProviderStateMixin {
  final DiscoveryController discoveryController =
      Get.find<DiscoveryController>();
  final BookingController bookingController = Get.put(BookingController());

  late TabController _tabController;
  late PageController _imageController;
  late ScrollController _scrollController;

  final _currentImageIndex = 0.obs;
  final _showAppBarTitle = false.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _imageController = PageController();
    _scrollController = ScrollController();

    _scrollController.addListener(_onScroll);
    _loadClinicDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const threshold = 200.0; // Height of hero image
    _showAppBarTitle.value = _scrollController.offset > threshold;
  }

  Future<void> _loadClinicDetails() async {
    // Load full clinic details if needed
    await discoveryController.getClinicDetails(widget.clinic.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildClinicHeader(),
                _buildTabBarSection(),
                _buildTabContent(),
                _buildBookingSection(),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return Obx(
      () => SliverAppBar(
        expandedHeight: 300,
        pinned: true,
        backgroundColor: AppColors.primary,
        title: _showAppBarTitle.value ? Text(widget.clinic.name) : null,
        actions: [
          IconButton(
            icon: Icon(
              widget.clinic.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.clinic.isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: () =>
                discoveryController.toggleClinicFavorite(widget.clinic.id),
          ),
          IconButton(icon: const Icon(Icons.share), onPressed: _shareClinic),
        ],
        flexibleSpace: FlexibleSpaceBar(background: _buildImageGallery()),
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = widget.clinic.images.isNotEmpty
        ? widget.clinic.images
        : ['']; // Placeholder for empty images

    return Stack(
      children: [
        PageView.builder(
          controller: _imageController,
          itemCount: images.length,
          onPageChanged: (index) => _currentImageIndex.value = index,
          itemBuilder: (context, index) {
            return Hero(
              tag: 'clinic-${widget.clinic.id}-image-$index',
              child: GestureDetector(
                onTap: () => _openImageGallery(index),
                child: images[index].isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.lightGrey,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
            );
          },
        ),
        // Image overlay gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),
        // Image indicators
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: images.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex.value == entry.key
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        // Status badges
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          left: 16,
          child: Row(
            children: [
              if (widget.clinic.isVerified)
                _buildStatusBadge(
                  'Verificado',
                  Icons.verified,
                  AppColors.primary,
                ),
              if (widget.clinic.isCurrentlyOpen)
                _buildStatusBadge('Aberto', Icons.schedule, AppColors.success),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.primaryLight.withOpacity(0.3),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.medical_services_outlined,
          size: 80,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.clinic.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: widget.clinic.rating,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: AppColors.sgPrimary,
                          ),
                          itemSize: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.clinic.formattedRating,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.clinic.formattedReviews,
                          style: const TextStyle(color: AppColors.mediumGrey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.clinic.distanceKm != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.clinic.formattedDistance,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildQuickInfo(),
        ],
      ),
    );
  }

  Widget _buildQuickInfo() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoTile(
            Icons.location_on,
            'Localização',
            widget.clinic.location,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoTile(
            Icons.schedule,
            'Horário',
            widget.clinic.isCurrentlyOpen
                ? 'Aberto agora'
                : widget.clinic.nextOpeningTime,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoTile(
            Icons.monetization_on,
            'Preços',
            widget.clinic.priceRange,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.mediumGrey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBarSection() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.mediumGrey,
        indicatorColor: AppColors.primary,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Serviços'),
          Tab(text: 'Sobre'),
          Tab(text: 'Localização'),
          Tab(text: 'Avaliações'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: 400, // Fixed height for tab content
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildServicesTab(),
          _buildAboutTab(),
          _buildLocationTab(),
          _buildReviewsTab(),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    final services = widget.clinic.services;

    if (services.isEmpty) {
      return const Center(child: Text('Nenhum serviço disponível'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return ServiceCard(
          service: services[index],
          compact: true,
          onTap: () => _showServiceDetails(services[index]),
          onBookPressed: () => _bookService(services[index]),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.clinic.description.isNotEmpty) ...[
            const Text(
              'Descrição',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              widget.clinic.description,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.clinic.specialtyDescription != null) ...[
            const Text(
              'Especialidades',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              widget.clinic.specialtyDescription!,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Comodidades',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.clinic.amenities.map((amenity) {
              return Chip(
                label: Text(amenity),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                labelStyle: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Endereço'),
            subtitle: Text(widget.clinic.fullAddress),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Telefone'),
            subtitle: Text(widget.clinic.phone),
            contentPadding: EdgeInsets.zero,
            onTap: () => _makePhoneCall(widget.clinic.phone),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('E-mail'),
            subtitle: Text(widget.clinic.email),
            contentPadding: EdgeInsets.zero,
            onTap: () => _sendEmail(widget.clinic.email),
          ),
          if (widget.clinic.website != null)
            ListTile(
              leading: const Icon(Icons.web),
              title: const Text('Website'),
              subtitle: Text(widget.clinic.website!),
              contentPadding: EdgeInsets.zero,
              onTap: () => _openWebsite(widget.clinic.website!),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openDirections,
              icon: const Icon(Icons.directions),
              label: const Text('Como chegar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return const Center(
      child: Text(
        'Sistema de avaliações em desenvolvimento',
        style: TextStyle(color: AppColors.mediumGrey),
      ),
    );
  }

  Widget _buildBookingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.lightGrey)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Agendar consulta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text(
                'A partir de ${widget.clinic.priceRange}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makePhoneCall(widget.clinic.phone),
                  icon: const Icon(Icons.phone),
                  label: const Text('Ligar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _bookNow,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Agendar Online'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openImageGallery(int initialIndex) {
    // This would open a full-screen image gallery
    Get.snackbar(
      'Galeria',
      'Visualização de imagens em tela cheia será implementada',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _shareClinic() {
    // This would share clinic information
    Get.snackbar(
      'Compartilhar',
      'Link da clínica copiado para a área de transferência',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showServiceDetails(Service service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ServiceCard(
                  service: service,
                  onBookPressed: () {
                    Get.back();
                    _bookService(service);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _bookService(Service service) {
    bookingController.initializeBooking(widget.clinic, service);
    Get.to(() => const BookingScreen(), transition: Transition.rightToLeft);
  }

  void _bookNow() {
    bookingController.initializeBooking(widget.clinic);
    Get.to(() => const BookingScreen(), transition: Transition.rightToLeft);
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWebsite(String website) async {
    final uri = Uri.parse(website);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openDirections() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.clinic.latitude},${widget.clinic.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
