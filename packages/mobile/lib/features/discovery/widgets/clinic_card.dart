import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/sg_credit_widget.dart';
import '../models/clinic.dart';

/// Clinic card widget optimized for mobile with touch-friendly design
class ClinicCard extends StatelessWidget {
  final Clinic clinic;
  final VoidCallback? onTap;
  final VoidCallback? onFavoritePressed;
  final bool showDistance;
  final bool compact;

  const ClinicCard({
    Key? key,
    required this.clinic,
    this.onTap,
    this.onFavoritePressed,
    this.showDistance = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: compact ? _buildCompactCard() : _buildFullCard(),
      ),
    );
  }

  Widget _buildCompactCard() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildClinicImage(size: 60),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClinicName(),
                const SizedBox(height: 4),
                _buildRatingAndDistance(),
                const SizedBox(height: 4),
                _buildPriceRange(),
              ],
            ),
          ),
          _buildFavoriteButton(),
        ],
      ),
    );
  }

  Widget _buildFullCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardHeader(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClinicInfo(),
              const SizedBox(height: 12),
              _buildServiceInfo(),
              const SizedBox(height: 12),
              _buildActionButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardHeader() {
    return Stack(
      children: [
        _buildClinicImage(height: 160),
        _buildOverlayGradient(),
        _buildHeaderContent(),
        _buildFavoriteButton(),
      ],
    );
  }

  Widget _buildClinicImage({double? height, double? size}) {
    final imageUrl = clinic.images.isNotEmpty ? clinic.images.first : null;
    
    return Container(
      height: height ?? size,
      width: size,
      decoration: BoxDecoration(
        borderRadius: height != null 
            ? const BorderRadius.vertical(top: Radius.circular(12))
            : BorderRadius.circular(8),
        color: AppColors.lightGrey.withOpacity(0.3),
      ),
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.lightGrey.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => _buildImagePlaceholder(),
            )
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primaryLight.withOpacity(0.1),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.medical_services_outlined,
          size: 40,
          color: AppColors.mediumGrey,
        ),
      ),
    );
  }

  Widget _buildOverlayGradient() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Positioned(
      left: 16,
      right: 60, // Account for favorite button
      bottom: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (clinic.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.verified, color: Colors.white, size: 12),
                      SizedBox(width: 2),
                      Text(
                        'Verificado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              if (clinic.isCurrentlyOpen)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Aberto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            clinic.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            clinic.location,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            clinic.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: clinic.isFavorite ? Colors.red : AppColors.mediumGrey,
          ),
          onPressed: onFavoritePressed,
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildClinicInfo() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact) ...[
                Text(
                  clinic.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  clinic.location,
                  style: const TextStyle(
                    color: AppColors.mediumGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _buildRatingAndDistance(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClinicName() {
    return Text(
      clinic.name,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRatingAndDistance() {
    return Row(
      children: [
        RatingBarIndicator(
          rating: clinic.rating,
          itemBuilder: (context, index) => const Icon(
            Icons.star,
            color: AppColors.sgPrimary,
          ),
          itemCount: 5,
          itemSize: 14,
          unratedColor: AppColors.lightGrey,
        ),
        const SizedBox(width: 4),
        Text(
          clinic.formattedRating,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${clinic.reviewCount})',
          style: const TextStyle(
            color: AppColors.mediumGrey,
            fontSize: 12,
          ),
        ),
        if (showDistance && clinic.distanceKm != null) ...[
          const SizedBox(width: 8),
          const Icon(
            Icons.location_on,
            size: 12,
            color: AppColors.mediumGrey,
          ),
          const SizedBox(width: 2),
          Text(
            clinic.formattedDistance,
            style: const TextStyle(
              color: AppColors.mediumGrey,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceRange() {
    return Text(
      clinic.priceRange,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildServiceInfo() {
    final mainServices = clinic.services.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.medical_services,
              size: 16,
              color: AppColors.mediumGrey,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                mainServices.map((s) => s.name).join(', '),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mediumGrey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (clinic.services.length > 3) ...[
          const SizedBox(height: 4),
          Text(
            '+${clinic.services.length - 3} outros serviços',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 8),
        _buildPriceAndSchedule(),
      ],
    );
  }

  Widget _buildPriceAndSchedule() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A partir de',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mediumGrey,
              ),
            ),
            Text(
              clinic.priceRange,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              clinic.isCurrentlyOpen ? 'Aberto agora' : clinic.nextOpeningTime,
              style: TextStyle(
                fontSize: 12,
                color: clinic.isCurrentlyOpen ? AppColors.success : AppColors.mediumGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (clinic.mainCategory.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.getCategoryColor(clinic.mainCategory).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  clinic.mainCategory,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.getCategoryColor(clinic.mainCategory),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('Ver Detalhes'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text('Agendar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}