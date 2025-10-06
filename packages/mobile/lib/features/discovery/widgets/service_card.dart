import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';
import 'package:singleclin_mobile/features/discovery/models/service.dart';
import 'package:singleclin_mobile/shared/widgets/sg_credit_widget.dart';

/// Service card widget optimized for mobile touch interactions
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.service,
    super.key,
    this.onTap,
    this.onBookPressed,
    this.compact = false,
    this.showDescription = true,
    this.userSGCredits,
  });
  final Service service;
  final VoidCallback? onTap;
  final VoidCallback? onBookPressed;
  final bool compact;
  final bool showDescription;
  final int? userSGCredits;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          _buildServiceImage(size: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServiceName(maxLines: 1),
                const SizedBox(height: 4),
                _buildDurationAndPrice(),
              ],
            ),
          ),
          _buildBookButton(compact: true),
        ],
      ),
    );
  }

  Widget _buildFullCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServiceImage(size: 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServiceName(),
                    const SizedBox(height: 4),
                    _buildCategoryChip(),
                    const SizedBox(height: 8),
                    _buildDurationAndPrice(),
                  ],
                ),
              ),
            ],
          ),
          if (showDescription && service.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDescription(),
          ],
          const SizedBox(height: 12),
          _buildServiceFeatures(),
          const SizedBox(height: 16),
          _buildActionSection(),
        ],
      ),
    );
  }

  Widget _buildServiceImage({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.getCategoryColor(service.category).withOpacity(0.1),
      ),
      child: service.imageUrl != null
          ? CachedNetworkImage(
              imageUrl: service.imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildImagePlaceholder(size),
              errorWidget: (context, url, error) =>
                  _buildImagePlaceholder(size),
            )
          : _buildImagePlaceholder(size),
    );
  }

  Widget _buildImagePlaceholder(double size) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.getCategoryColor(service.category).withOpacity(0.1),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(service.category),
          size: size * 0.4,
          color: AppColors.getCategoryColor(service.category),
        ),
      ),
    );
  }

  Widget _buildServiceName({int maxLines = 2}) {
    return Text(
      service.name,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.getCategoryColor(service.category).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        service.category,
        style: TextStyle(
          fontSize: 10,
          color: AppColors.getCategoryColor(service.category),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDurationAndPrice() {
    final isAffordable = userSGCredits != null
        ? userSGCredits! >= service.priceInSG
        : true;

    return Row(
      children: [
        const Icon(Icons.schedule, size: 14, color: AppColors.mediumGrey),
        const SizedBox(width: 4),
        Text(
          service.formattedDuration,
          style: const TextStyle(fontSize: 12, color: AppColors.mediumGrey),
        ),
        const SizedBox(width: 12),
        SgCostChip(cost: service.priceInSG, isAffordable: isAffordable),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      service.description,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.mediumGrey,
        height: 1.4,
      ),
      maxLines: compact ? 2 : 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildServiceFeatures() {
    final features = <Widget>[];

    if (service.requiresConsultation) {
      features.add(
        _buildFeatureChip(
          'Consulta necessária',
          Icons.medical_services,
          AppColors.warning,
        ),
      );
    }

    if (service.recommendedSessions != null &&
        service.recommendedSessions! > 1) {
      features.add(
        _buildFeatureChip(
          service.recommendedSessionsText,
          Icons.repeat,
          AppColors.info,
        ),
      );
    }

    if (service.isFeatured) {
      features.add(
        _buildFeatureChip('Destaque', Icons.star, AppColors.sgPrimary),
      );
    }

    if (service.isPopular) {
      features.add(
        _buildFeatureChip('Popular', Icons.trending_up, AppColors.success),
      );
    }

    if (features.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 6, runSpacing: 6, children: features);
  }

  Widget _buildFeatureChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    if (compact) return _buildBookButton();

    return Column(
      children: [
        if (service.pricing != null) _buildPackageDeals(),
        const SizedBox(height: 12),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildPackageDeals() {
    final pricing = service.pricing!;
    final deals = [
      pricing.package3Sessions,
      pricing.package5Sessions,
      pricing.package10Sessions,
    ].where((deal) => deal != null).cast<PackageDeal>().toList();

    if (deals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pacotes promocionais:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.mediumGrey,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: deals.map(_buildPackageDealCard).toList()),
        ),
      ],
    );
  }

  Widget _buildPackageDealCard(PackageDeal deal) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.sgPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.sgPrimary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${deal.sessions} sessões',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '${deal.totalPrice}SG',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.sgPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            deal.formattedSavings,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('Detalhes'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _buildBookButton()),
      ],
    );
  }

  Widget _buildBookButton({bool compact = false}) {
    final isAffordable = userSGCredits != null
        ? userSGCredits! >= service.priceInSG
        : true;

    return ElevatedButton.icon(
      onPressed: isAffordable ? onBookPressed : null,
      icon: Icon(Icons.calendar_today, size: compact ? 14 : 16),
      label: Text(
        compact ? 'Agendar' : 'Agendar Agora',
        style: TextStyle(fontSize: compact ? 12 : 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isAffordable ? AppColors.primary : AppColors.disabled,
        padding: EdgeInsets.symmetric(
          vertical: compact ? 8 : 12,
          horizontal: compact ? 12 : 16,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'estética facial':
      case 'estetica facial':
        return Icons.face;
      case 'estética corporal':
      case 'estetica corporal':
        return Icons.fitness_center;
      case 'terapias injetáveis':
      case 'terapias injetaveis':
        return Icons.medical_services;
      case 'dermatologia':
        return Icons.healing;
      case 'bem-estar':
        return Icons.spa;
      case 'diagnósticos':
      case 'diagnosticos':
        return Icons.biotech;
      case 'performance':
        return Icons.sports_score;
      case 'fisioterapia':
        return Icons.accessibility_new;
      default:
        return Icons.medical_services;
    }
  }
}
