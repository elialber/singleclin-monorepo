import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:singleclin_mobile/features/credits/models/credit_transaction_model.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';

class TransactionItem extends StatelessWidget {
  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.showDate = true,
    this.compact = false,
  });
  final CreditTransactionModel transaction;
  final VoidCallback? onTap;
  final bool showDate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Row(
            children: [
              // Transaction type icon
              _buildTransactionIcon(),

              SizedBox(width: compact ? 12 : 16),

              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      transaction.description,
                      style: TextStyle(
                        fontSize: compact ? 14 : 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: compact ? 2 : 4),

                    // Source and date
                    Row(
                      children: [
                        Text(
                          transaction.sourceDisplayName,
                          style: TextStyle(
                            fontSize: compact ? 11 : 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        if (showDate) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: compact ? 11 : 12,
                              color: Colors.grey[400],
                            ),
                          ),
                          Text(
                            _formatDate(transaction.createdAt),
                            style: TextStyle(
                              fontSize: compact ? 11 : 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: compact ? 8 : 12),

              // Amount and status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Amount
                  Text(
                    transaction.amountDisplay,
                    style: TextStyle(
                      fontSize: compact ? 15 : 16,
                      fontWeight: FontWeight.bold,
                      color: _getAmountColor(),
                    ),
                  ),

                  SizedBox(height: compact ? 2 : 4),

                  // Status badge or balance after
                  if (!compact && transaction.balanceAfter > 0)
                    Text(
                      'Saldo: ${transaction.balanceAfter} SG',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionIcon() {
    IconData iconData;
    Color backgroundColor;
    Color iconColor;

    switch (transaction.type) {
      case TransactionType.earned:
      case TransactionType.subscription:
        iconData = Icons.add_circle;
        backgroundColor = Colors.green.withOpacity(0.1);
        iconColor = Colors.green.shade600;
        break;
      case TransactionType.spent:
        iconData = Icons.remove_circle;
        backgroundColor = Colors.red.withOpacity(0.1);
        iconColor = Colors.red.shade600;
        break;
      case TransactionType.refunded:
        iconData = Icons.refresh;
        backgroundColor = Colors.blue.withOpacity(0.1);
        iconColor = Colors.blue.shade600;
        break;
      case TransactionType.bonus:
        iconData = Icons.stars;
        backgroundColor = AppColors.sgPrimary.withOpacity(0.1);
        iconColor = AppColors.sgPrimary;
        break;
      case TransactionType.purchase:
        iconData = Icons.shopping_cart;
        backgroundColor = Colors.purple.withOpacity(0.1);
        iconColor = Colors.purple.shade600;
        break;
    }

    // Special handling for specific sources
    switch (transaction.source) {
      case TransactionSource.referral:
        iconData = Icons.person_add;
        backgroundColor = Colors.orange.withOpacity(0.1);
        iconColor = Colors.orange.shade600;
        break;
      case TransactionSource.appointmentBooking:
        iconData = Icons.calendar_today;
        backgroundColor = Colors.blue.withOpacity(0.1);
        iconColor = Colors.blue.shade600;
        break;
      case TransactionSource.appointmentCancel:
        iconData = Icons.cancel;
        backgroundColor = Colors.grey.withOpacity(0.1);
        iconColor = Colors.grey.shade600;
        break;
      default:
        break; // Keep the type-based icon
    }

    return Container(
      width: compact ? 40 : 48,
      height: compact ? 40 : 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Icon(iconData, color: iconColor, size: compact ? 20 : 24),
    );
  }

  Color _getAmountColor() {
    if (transaction.isPositive) {
      return transaction.type == TransactionType.bonus
          ? AppColors.sgPrimary
          : Colors.green.shade600;
    } else {
      return Colors.red.shade600;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoje ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Ontem ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }
}

class TransactionItemShimmer extends StatelessWidget {
  const TransactionItemShimmer({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Row(
          children: [
            // Icon shimmer
            Container(
              width: compact ? 40 : 48,
              height: compact ? 40 : 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),

            SizedBox(width: compact ? 12 : 16),

            // Content shimmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: compact ? 14 : 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  SizedBox(height: compact ? 4 : 8),

                  Container(
                    height: compact ? 10 : 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: compact ? 8 : 12),

            // Amount shimmer
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  height: compact ? 15 : 16,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                SizedBox(height: compact ? 2 : 4),

                if (!compact)
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
