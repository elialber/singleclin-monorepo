import 'package:flutter/material.dart';
import 'package:mobile/domain/entities/user_plan_entity.dart';

/// Main plan visualization card component
///
/// Displays user's current plan information including:
/// - Plan name and description
/// - Credit usage with progress indicator
/// - Expiration date and status
/// - Visual status indicators (colors)
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    this.userPlan,
    this.onTap,
    this.onRefresh,
    this.isLoading = false,
  });
  final UserPlanEntity? userPlan;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingCard(context);
    }

    if (userPlan == null) {
      return _buildNoPlanCard(context);
    }

    return _buildPlanCard(context, userPlan!);
  }

  /// Build loading state card
  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Container(
        constraints: const BoxConstraints(minHeight: 160), // Consistente com o outro card
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Carregando plano...',
                style: TextStyle(fontSize: 12, color: Colors.grey), // Fonte menor para iOS
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build no plan available card
  Widget _buildNoPlanCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Container(
        constraints: const BoxConstraints(minHeight: 160), // Altura mínima ainda menor
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Padding mais compacto
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribuição uniforme
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.credit_card_off, size: 36, color: Colors.grey[400]), // Ícone ainda menor
            Text(
              'Nenhum plano ativo',
              style: Theme.of(context).textTheme.titleSmall?.copyWith( // titleSmall para iOS
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            Flexible( // Permite flexibilidade no texto
              child: Text(
                'Você não possui um plano ativo\nno momento',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontSize: 12, // Fonte ainda menor
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox( // Botão compacto
              height: 32, // Altura ainda menor
              child: ElevatedButton(
                onPressed: onRefresh,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  minimumSize: const Size(80, 32), // Tamanho mínimo
                ),
                child: const Text(
                  'Atualizar',
                  style: TextStyle(fontSize: 12), // Fonte menor
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build main plan card with all information
  Widget _buildPlanCard(BuildContext context, UserPlanEntity plan) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(plan.statusColor);
    final usagePercentage = plan.usagePercentage;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [statusColor.withValues(alpha: 0.1), Colors.white],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with plan name and status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.plan.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.plan.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(plan, statusColor),
                ],
              ),

              const SizedBox(height: 20),

              // Credits usage section
              _buildCreditsSection(context, plan, usagePercentage, statusColor),

              const SizedBox(height: 16),

              // Footer with expiration and refresh
              _buildFooterSection(context, plan),
            ],
          ),
        ),
      ),
    );
  }

  /// Build status chip indicator
  Widget _buildStatusChip(UserPlanEntity plan, Color statusColor) {
    String statusText;
    IconData statusIcon;

    if (plan.isExpired) {
      statusText = 'Expirado';
      statusIcon = Icons.error_outline;
    } else if (plan.isRunningLow) {
      statusText = 'Baixo';
      statusIcon = Icons.warning_amber_outlined;
    } else {
      statusText = 'Ativo';
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build credits usage section with progress bar
  Widget _buildCreditsSection(
    BuildContext context,
    UserPlanEntity plan,
    double usagePercentage,
    Color statusColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Créditos Utilizados',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '${plan.remainingCredits}/${plan.totalCredits}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: usagePercentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            minHeight: 8,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(usagePercentage * 100).toStringAsFixed(1)}% utilizado',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            Text(
              '${plan.usedCredits} créditos usados',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  /// Build footer section with expiration date and refresh button
  Widget _buildFooterSection(BuildContext context, UserPlanEntity plan) {
    final theme = Theme.of(context);
    final daysUntilExpiration = plan.daysUntilExpiration;

    String expirationText;
    Color expirationColor;

    if (plan.isExpired) {
      expirationText = 'Plano expirado';
      expirationColor = Colors.red;
    } else if (daysUntilExpiration <= 7) {
      expirationText = 'Expira em $daysUntilExpiration dias';
      expirationColor = Colors.orange;
    } else if (daysUntilExpiration <= 30) {
      expirationText = 'Expira em $daysUntilExpiration dias';
      expirationColor = Colors.amber[700]!;
    } else {
      expirationText =
          'Expira em ${plan.expirationDate.day}/${plan.expirationDate.month}/${plan.expirationDate.year}';
      expirationColor = Colors.grey[600]!;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: expirationColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      expirationText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: expirationColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (plan.isRunningLow) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_outlined,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Créditos baixos',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Refresh button
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar dados do plano',
          iconSize: 20,
        ),
      ],
    );
  }

  /// Get status color based on plan status
  Color _getStatusColor(String statusColor) {
    switch (statusColor.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'yellow':
      case 'amber':
        return Colors.amber[700]!;
      case 'red':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
