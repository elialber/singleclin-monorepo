import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class SgCreditWidget extends StatelessWidget {
  final int credits;
  final VoidCallback? onTap;
  final bool showRenewInfo;
  final DateTime? renewDate;
  final bool compact;

  const SgCreditWidget({
    Key? key,
    required this.credits,
    this.onTap,
    this.showRenewInfo = false,
    this.renewDate,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactWidget(context);
    }
    return _buildFullWidget(context);
  }

  Widget _buildCompactWidget(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.sgPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.sgPrimary, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 16,
              color: AppColors.sgPrimary,
            ),
            const SizedBox(width: 4),
            Text(
              '$credits SG',
              style: const TextStyle(
                color: AppColors.sgPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidget(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.sgPrimary, AppColors.sgSecondary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.sgPrimary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const Spacer(),
                if (onTap != null)
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              AppStrings.myCredits,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  credits.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'SG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (showRenewInfo && renewDate != null) ...[
              const SizedBox(height: 8),
              _buildRenewInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRenewInfo() {
    final daysUntilRenew = _calculateDaysUntilRenew();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.refresh,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            _getRenewText(daysUntilRenew),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateDaysUntilRenew() {
    if (renewDate == null) return 0;
    
    final now = DateTime.now();
    final difference = renewDate!.difference(now);
    
    return difference.inDays > 0 ? difference.inDays : 0;
  }

  String _getRenewText(int days) {
    if (days == 0) {
      return 'Renovam hoje';
    } else if (days == 1) {
      return 'Renovam amanhã';
    } else if (days <= 7) {
      return 'Renovam em $days dias';
    } else {
      return '${AppStrings.creditsRenew} ${days}d';
    }
  }
}

class SgCostChip extends StatelessWidget {
  final int cost;
  final bool isAffordable;
  final double fontSize;

  const SgCostChip({
    Key? key,
    required this.cost,
    required this.isAffordable,
    this.fontSize = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAffordable ? AppColors.sgPrimary.withOpacity(0.1) : AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAffordable ? AppColors.sgPrimary : AppColors.mediumGrey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: fontSize + 2,
            color: isAffordable ? AppColors.sgPrimary : AppColors.mediumGrey,
          ),
          const SizedBox(width: 4),
          Text(
            '$cost SG',
            style: TextStyle(
              color: isAffordable ? AppColors.sgPrimary : AppColors.mediumGrey,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SgTransactionItem extends StatelessWidget {
  final String title;
  final String description;
  final int amount;
  final bool isPositive;
  final DateTime date;
  final IconData? icon;
  final VoidCallback? onTap;

  const SgTransactionItem({
    Key? key,
    required this.title,
    required this.description,
    required this.amount,
    required this.isPositive,
    required this.date,
    this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPositive 
              ? AppColors.success.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon ?? (isPositive ? Icons.add : Icons.remove),
          color: isPositive ? AppColors.success : AppColors.error,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.mediumGrey,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isPositive ? '+' : '-'}$amount SG',
            style: TextStyle(
              color: isPositive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            _formatDate(date),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.mediumGrey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}