import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/trust_certification.dart';
import '../../../core/constants/app_colors.dart';

/// Trust badge widget for displaying certifications
class TrustBadge extends StatelessWidget {
  final TrustCertification certification;
  final VoidCallback? onTap;
  final double size;
  final bool showTooltip;

  const TrustBadge({
    Key? key,
    required this.certification,
    this.onTap,
    this.size = 48.0,
    this.showTooltip = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final widget = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _getStatusColor(),
            width: 2,
          ),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            children: [
              if (certification.logoUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: certification.logoUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.lightGrey,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildDefaultIcon(),
                )
              else
                _buildDefaultIcon(),
              if (certification.isExpiringSoon || certification.isExpired)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: certification.isExpired 
                          ? AppColors.error 
                          : AppColors.warning,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (showTooltip) {
      return Tooltip(
        message: '${certification.name}\n${_getStatusText()}',
        child: widget,
      );
    }

    return widget;
  }

  Widget _buildDefaultIcon() {
    IconData icon;
    Color color;

    switch (certification.type) {
      case CertificationType.security:
        icon = Icons.security;
        color = AppColors.primary;
        break;
      case CertificationType.privacy:
        icon = Icons.privacy_tip;
        color = AppColors.info;
        break;
      case CertificationType.quality:
        icon = Icons.verified;
        color = AppColors.success;
        break;
      case CertificationType.medical:
        icon = Icons.medical_services;
        color = AppColors.categoryDiagnostic;
        break;
      case CertificationType.regulatory:
        icon = Icons.gavel;
        color = AppColors.categoryInjectable;
        break;
      case CertificationType.industry:
        icon = Icons.business;
        color = AppColors.categoryPerformance;
        break;
      case CertificationType.compliance:
        icon = Icons.checklist;
        color = AppColors.categoryAesthetic;
        break;
      case CertificationType.audit:
        icon = Icons.fact_check;
        color = AppColors.warning;
        break;
    }

    return Container(
      color: color.withOpacity(0.1),
      child: Icon(
        icon,
        color: color,
        size: size * 0.5,
      ),
    );
  }

  Color _getStatusColor() {
    switch (certification.status) {
      case CertificationStatus.active:
        return AppColors.success;
      case CertificationStatus.expired:
        return AppColors.error;
      case CertificationStatus.suspended:
        return AppColors.warning;
      case CertificationStatus.revoked:
        return AppColors.error;
      case CertificationStatus.pending:
        return AppColors.info;
    }
  }

  String _getStatusText() {
    switch (certification.status) {
      case CertificationStatus.active:
        return 'Certificação Ativa';
      case CertificationStatus.expired:
        return 'Certificação Expirada';
      case CertificationStatus.suspended:
        return 'Certificação Suspensa';
      case CertificationStatus.revoked:
        return 'Certificação Revogada';
      case CertificationStatus.pending:
        return 'Certificação Pendente';
    }
  }
}

/// Trust score widget with circular progress
class TrustScoreWidget extends StatelessWidget {
  final int score;
  final double size;
  final bool showLabel;

  const TrustScoreWidget({
    Key? key,
    required this.score,
    this.size = 80.0,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: AppColors.lightGrey,
                  color: _getScoreColor(score),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(score),
                    ),
                  ),
                  Text(
                    '/100',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          Text(
            'Confiança',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.darkGrey,
            ),
          ),
          Text(
            _getScoreDescription(score),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mediumGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.success;
    if (score >= 80) return Colors.lightGreen;
    if (score >= 70) return AppColors.sgPrimary;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String _getScoreDescription(int score) {
    if (score >= 90) return 'Excelente';
    if (score >= 80) return 'Muito Bom';
    if (score >= 70) return 'Bom';
    if (score >= 60) return 'Regular';
    return 'Necessita Melhoria';
  }
}

/// Trust metrics summary widget
class TrustMetricsSummary extends StatelessWidget {
  final TrustMetrics metrics;

  const TrustMetricsSummary({
    Key? key,
    required this.metrics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Métricas de Confiança',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TrustScoreWidget(
                  score: metrics.overallTrustScore,
                  size: 60,
                  showLabel: false,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    context,
                    'Avaliações',
                    '${metrics.userReviews}',
                    Icons.star,
                    AppColors.sgPrimary,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    context,
                    'Média',
                    metrics.avgRating.toStringAsFixed(1),
                    Icons.thumb_up,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    context,
                    'Resolvidas',
                    '${metrics.resolvedComplaints}',
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    context,
                    'Pendentes',
                    '${metrics.totalComplaints - metrics.resolvedComplaints}',
                    Icons.pending,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Certificações Ativas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (metrics.certifications.isEmpty)
              Text(
                'Nenhuma certificação disponível',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mediumGrey,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: metrics.certifications
                    .where((cert) => cert.status == CertificationStatus.active)
                    .take(6)
                    .map((cert) => TrustBadge(
                          certification: cert,
                          size: 40,
                        ))
                    .toList(),
              ),
            const SizedBox(height: 8),
            Text(
              'Última atualização: ${_formatDate(metrics.lastUpdated)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mediumGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mediumGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} dias atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} horas atrás';
    } else {
      return 'há poucos minutos';
    }
  }
}

/// Security score badge
class SecurityScoreBadge extends StatelessWidget {
  final String score;
  final VoidCallback? onTap;

  const SecurityScoreBadge({
    Key? key,
    required this.score,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getScoreColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _getScoreColor().withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.security,
              size: 16,
              color: _getScoreColor(),
            ),
            const SizedBox(width: 4),
            Text(
              'Segurança: $score',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getScoreColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor() {
    switch (score.toUpperCase()) {
      case 'A+':
      case 'A':
        return AppColors.success;
      case 'A-':
      case 'B+':
        return Colors.lightGreen;
      case 'B':
      case 'B-':
        return AppColors.sgPrimary;
      case 'C+':
      case 'C':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }
}

/// LGPD compliance indicator
class LgpdComplianceIndicator extends StatelessWidget {
  final LgpdCompliance compliance;
  final VoidCallback? onTap;

  const LgpdComplianceIndicator({
    Key? key,
    required this.compliance,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final compliancePercentage = _getCompliancePercentage();
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: compliance.isCompliant 
              ? AppColors.success.withOpacity(0.1)
              : AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: compliance.isCompliant 
                ? AppColors.success.withOpacity(0.3)
                : AppColors.warning.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              compliance.isCompliant ? Icons.verified_user : Icons.warning,
              color: compliance.isCompliant ? AppColors.success : AppColors.warning,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LGPD Compliance',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: compliance.isCompliant 
                          ? AppColors.success 
                          : AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(compliancePercentage * 100).round()}% em conformidade',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: compliancePercentage,
                    backgroundColor: AppColors.lightGrey,
                    color: compliance.isCompliant 
                        ? AppColors.success 
                        : AppColors.warning,
                    minHeight: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getCompliancePercentage() {
    final total = compliance.requirements.length;
    if (total == 0) return 0.0;
    
    final compliant = compliance.requirements.where((r) => r.isCompliant).length;
    return compliant / total;
  }
}

/// Emergency contact card
class EmergencyContactCard extends StatelessWidget {
  final String title;
  final String contact;
  final IconData icon;
  final VoidCallback? onTap;

  const EmergencyContactCard({
    Key? key,
    required this.title,
    required this.contact,
    required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.error.withOpacity(0.1),
                AppColors.error.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.error,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                contact,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mediumGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trust level indicator
class TrustLevelIndicator extends StatelessWidget {
  final int trustScore;
  final bool isCompact;

  const TrustLevelIndicator({
    Key? key,
    required this.trustScore,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final level = _getTrustLevel(trustScore);
    final color = _getLevelColor(level);
    
    if (isCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getLevelIcon(level),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            level,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getLevelIcon(level),
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            '$level ($trustScore/100)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getTrustLevel(int score) {
    if (score >= 90) return 'Excelente';
    if (score >= 80) return 'Muito Confiável';
    if (score >= 70) return 'Confiável';
    if (score >= 60) return 'Moderado';
    return 'Baixo';
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Excelente':
        return AppColors.success;
      case 'Muito Confiável':
        return Colors.lightGreen;
      case 'Confiável':
        return AppColors.sgPrimary;
      case 'Moderado':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'Excelente':
        return Icons.verified;
      case 'Muito Confiável':
        return Icons.thumb_up;
      case 'Confiável':
        return Icons.check_circle;
      case 'Moderado':
        return Icons.info;
      default:
        return Icons.warning;
    }
  }
}