import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/faq_item.dart';
import '../../../core/constants/app_colors.dart';

/// Expandable FAQ item widget with smooth animations
class FaqExpandableItem extends StatefulWidget {
  final FaqItem item;
  final bool isExpanded;
  final VoidCallback onTap;
  final Function(bool)? onHelpfulVote;
  final VoidCallback? onFeedback;
  final List<FaqItem>? relatedItems;

  const FaqExpandableItem({
    Key? key,
    required this.item,
    required this.isExpanded,
    required this.onTap,
    this.onHelpfulVote,
    this.onFeedback,
    this.relatedItems,
  }) : super(key: key);

  @override
  State<FaqExpandableItem> createState() => _FaqExpandableItemState();
}

class _FaqExpandableItemState extends State<FaqExpandableItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(FaqExpandableItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: widget.isExpanded ? 4 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildCategoryIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.question,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGrey,
                          ),
                        ),
                        if (widget.item.tags.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _buildTags(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 3.141592653589793,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildExpandedContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon() {
    IconData icon;
    Color color;

    switch (widget.item.category) {
      case FaqCategory.sgCredits:
        icon = Icons.monetization_on;
        color = AppColors.sgPrimary;
        break;
      case FaqCategory.appointments:
        icon = Icons.calendar_today;
        color = AppColors.primary;
        break;
      case FaqCategory.payments:
        icon = Icons.payment;
        color = AppColors.success;
        break;
      case FaqCategory.account:
        icon = Icons.account_circle;
        color = AppColors.info;
        break;
      case FaqCategory.technical:
        icon = Icons.build;
        color = AppColors.warning;
        break;
      case FaqCategory.privacy:
        icon = Icons.privacy_tip;
        color = AppColors.error;
        break;
      default:
        icon = Icons.help_outline;
        color = AppColors.mediumGrey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: widget.item.tags.take(2).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tag,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mediumGrey,
              fontSize: 10,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildAnswer(),
          if (widget.item.videoUrl != null) ...[
            const SizedBox(height: 16),
            _buildVideoPlayer(),
          ],
          if (widget.item.attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildAttachments(),
          ],
          const SizedBox(height: 16),
          _buildFooterActions(),
          if (widget.relatedItems != null && widget.relatedItems!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildRelatedItems(),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswer() {
    return SelectableText(
      widget.item.answer,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.darkGrey,
        height: 1.5,
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: AssetImage('assets/images/video_thumbnail.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.7),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anexos:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.item.attachments.map((attachment) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attachment.split('/').last,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Icon(
                  Icons.download,
                  color: AppColors.mediumGrey,
                  size: 16,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFooterActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Esta resposta foi útil?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mediumGrey,
              ),
            ),
            const Spacer(),
            _buildHelpfulButtons(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.visibility,
              size: 14,
              color: AppColors.mediumGrey,
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.item.viewCount} visualizações',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mediumGrey,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.schedule,
              size: 14,
              color: AppColors.mediumGrey,
            ),
            const SizedBox(width: 4),
            Text(
              _getLastUpdatedText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mediumGrey,
              ),
            ),
            const Spacer(),
            if (widget.onFeedback != null)
              TextButton(
                onPressed: widget.onFeedback,
                child: const Text('Sugerir melhoria'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHelpfulButtons() {
    final totalVotes = widget.item.helpfulCount + widget.item.notHelpfulCount;
    final helpfulPercentage = totalVotes > 0 
        ? (widget.item.helpfulCount / totalVotes * 100).round() 
        : 0;

    return Row(
      children: [
        InkWell(
          onTap: widget.onHelpfulVote != null ? () => widget.onHelpfulVote!(true) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.thumb_up_outlined,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.item.helpfulCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: widget.onHelpfulVote != null ? () => widget.onHelpfulVote!(false) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.thumb_down_outlined,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.item.notHelpfulCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (totalVotes > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$helpfulPercentage% útil',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRelatedItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perguntas relacionadas:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.relatedItems!.take(3).map((relatedItem) {
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              onTap: () {
                // Handle related item tap
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        relatedItem.question,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _getLastUpdatedText() {
    final updatedAt = widget.item.updatedAt ?? widget.item.createdAt;
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inDays > 365) {
      return 'há mais de 1 ano';
    } else if (difference.inDays > 30) {
      return 'há ${(difference.inDays / 30).floor()} meses';
    } else if (difference.inDays > 0) {
      return 'há ${difference.inDays} dias';
    } else if (difference.inHours > 0) {
      return 'há ${difference.inHours} horas';
    } else {
      return 'há poucos minutos';
    }
  }
}

/// Compact FAQ item for search results
class CompactFaqItem extends StatelessWidget {
  final FaqItem item;
  final VoidCallback onTap;
  final String? highlightText;

  const CompactFaqItem({
    Key? key,
    required this.item,
    required this.onTap,
    this.highlightText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildCategoryIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHighlightedText(
                      item.question,
                      Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ) ?? const TextStyle(),
                    ),
                    const SizedBox(height: 4),
                    _buildHighlightedText(
                      item.answer.length > 100 
                          ? '${item.answer.substring(0, 100)}...'
                          : item.answer,
                      Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mediumGrey,
                      ) ?? const TextStyle(),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.mediumGrey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    IconData icon;
    Color color;

    switch (item.category) {
      case FaqCategory.sgCredits:
        icon = Icons.monetization_on;
        color = AppColors.sgPrimary;
        break;
      case FaqCategory.appointments:
        icon = Icons.calendar_today;
        color = AppColors.primary;
        break;
      case FaqCategory.payments:
        icon = Icons.payment;
        color = AppColors.success;
        break;
      default:
        icon = Icons.help_outline;
        color = AppColors.mediumGrey;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        color: color,
        size: 16,
      ),
    );
  }

  Widget _buildHighlightedText(String text, TextStyle style) {
    if (highlightText == null || highlightText!.isEmpty) {
      return Text(text, style: style);
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerHighlight = highlightText!.toLowerCase();
    
    int start = 0;
    int index = lowerText.indexOf(lowerHighlight);
    
    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: style,
        ));
      }
      
      spans.add(TextSpan(
        text: text.substring(index, index + highlightText!.length),
        style: style.copyWith(
          backgroundColor: AppColors.sgPrimary.withOpacity(0.3),
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + highlightText!.length;
      index = lowerText.indexOf(lowerHighlight, start);
    }
    
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: style,
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// FAQ category filter chips
class FaqCategoryChips extends StatelessWidget {
  final FaqCategory? selectedCategory;
  final Map<FaqCategory, int> categoryCounts;
  final Function(FaqCategory?) onCategorySelected;

  const FaqCategoryChips({
    Key? key,
    this.selectedCategory,
    required this.categoryCounts,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'category': null, 'label': 'Todas', 'count': categoryCounts.values.fold(0, (a, b) => a + b)},
      ...FaqCategory.values.map((category) => {
        'category': category,
        'label': _getCategoryLabel(category),
        'count': categoryCounts[category] ?? 0,
      }),
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final categoryData = categories[index];
          final category = categoryData['category'] as FaqCategory?;
          final label = categoryData['label'] as String;
          final count = categoryData['count'] as int;
          final isSelected = selectedCategory == category;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('$label ($count)'),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(category),
              backgroundColor: Colors.transparent,
              selectedColor: AppColors.primary.withOpacity(0.1),
              checkmarkColor: AppColors.primary,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.lightGrey,
              ),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.mediumGrey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  String _getCategoryLabel(FaqCategory category) {
    switch (category) {
      case FaqCategory.general:
        return 'Geral';
      case FaqCategory.sgCredits:
        return 'Créditos SG';
      case FaqCategory.appointments:
        return 'Agendamentos';
      case FaqCategory.payments:
        return 'Pagamentos';
      case FaqCategory.account:
        return 'Conta';
      case FaqCategory.clinics:
        return 'Clínicas';
      case FaqCategory.services:
        return 'Serviços';
      case FaqCategory.technical:
        return 'Técnico';
      case FaqCategory.privacy:
        return 'Privacidade';
      case FaqCategory.policies:
        return 'Políticas';
    }
  }
}