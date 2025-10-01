import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:singleclin_mobile/features/engagement/models/community_post.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';

/// Community post card widget
class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    Key? key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onBookmark,
    this.onReport,
    this.isCompact = false,
  }) : super(key: key);
  final CommunityPost post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;
  final VoidCallback? onReport;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildContent(context),
              if (post.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildImages(context),
              ],
              if (post.tags.isNotEmpty && !isCompact) ...[
                const SizedBox(height: 12),
                _buildTags(context),
              ],
              const SizedBox(height: 12),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    post.isAnonymous ? 'Usuário Anônimo' : post.userName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (post.clinicName != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Paciente',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy • HH:mm').format(post.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildGroupBadge(context),
                  const SizedBox(width: 8),
                  _buildPostTypeBadge(context),
                ],
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'report' && onReport != null) {
              onReport!();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Denunciar'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    if (post.isAnonymous) {
      return Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.lightGrey,
        ),
        child: const Icon(Icons.person, color: AppColors.mediumGrey, size: 24),
      );
    }

    if (post.userAvatar.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: CachedNetworkImageProvider(post.userAvatar),
        backgroundColor: AppColors.lightGrey,
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: Text(
        post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGroupBadge(BuildContext context) {
    Color badgeColor;
    String groupName;

    switch (post.group) {
      case CommunityGroup.aestheticFacial:
        badgeColor = AppColors.categoryAesthetic;
        groupName = 'Estética';
        break;
      case CommunityGroup.injectableTherapies:
        badgeColor = AppColors.categoryInjectable;
        groupName = 'Injetáveis';
        break;
      case CommunityGroup.diagnostics:
        badgeColor = AppColors.categoryDiagnostic;
        groupName = 'Diagnósticos';
        break;
      case CommunityGroup.performanceHealth:
        badgeColor = AppColors.categoryPerformance;
        groupName = 'Performance';
        break;
      default:
        badgeColor = AppColors.mediumGrey;
        groupName = 'Geral';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        groupName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPostTypeBadge(BuildContext context) {
    IconData icon;
    String label;

    switch (post.type) {
      case PostType.beforeAfter:
        icon = Icons.compare;
        label = 'Antes/Depois';
        break;
      case PostType.question:
        icon = Icons.help_outline;
        label = 'Pergunta';
        break;
      case PostType.tip:
        icon = Icons.lightbulb_outline;
        label = 'Dica';
        break;
      case PostType.recommendation:
        icon = Icons.recommend;
        label = 'Recomendação';
        break;
      case PostType.review:
        icon = Icons.star_outline;
        label = 'Avaliação';
        break;
      default:
        icon = Icons.chat_bubble_outline;
        label = 'Experiência';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.primary),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.title.isNotEmpty) ...[
          Text(
            post.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          post.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.darkGrey,
            height: 1.4,
          ),
          maxLines: isCompact ? 3 : null,
          overflow: isCompact ? TextOverflow.ellipsis : null,
        ),
        if (post.clinicName != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 14,
                color: AppColors.mediumGrey,
              ),
              const SizedBox(width: 4),
              Text(
                post.clinicName!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImages(BuildContext context) {
    if (post.images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: post.images.first,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 200,
            color: AppColors.lightGrey,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: AppColors.lightGrey,
            child: const Icon(Icons.error),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: post.images.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: post.images[index],
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 120,
                  height: 120,
                  color: AppColors.lightGrey,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 120,
                  height: 120,
                  color: AppColors.lightGrey,
                  child: const Icon(Icons.error),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTags(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: post.tags.take(4).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '#$tag',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        // Like button
        InkWell(
          onTap: onLike,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: post.isLikedByMe ? Colors.red : AppColors.mediumGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.likesCount}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
                ),
              ],
            ),
          ),
        ),

        // Comment button
        InkWell(
          onTap: onComment,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: AppColors.mediumGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentsCount}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
                ),
              ],
            ),
          ),
        ),

        // Share button
        InkWell(
          onTap: onShare,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: AppColors.mediumGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.sharesCount}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Bookmark button
        InkWell(
          onTap: onBookmark,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              size: 20,
              color: post.isBookmarked
                  ? AppColors.primary
                  : AppColors.mediumGrey,
            ),
          ),
        ),
      ],
    );
  }
}

/// Post comment widget
class PostCommentCard extends StatelessWidget {
  const PostCommentCard({
    Key? key,
    required this.comment,
    this.onLike,
    this.onReply,
    this.onReport,
  }) : super(key: key);
  final PostComment comment;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  comment.isAnonymous
                      ? '?'
                      : comment.userName.isNotEmpty
                      ? comment.userName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.isAnonymous
                          ? 'Usuário Anônimo'
                          : comment.userName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'dd/MM/yyyy • HH:mm',
                      ).format(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'report' && onReport != null) {
                    onReport!();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag, size: 16),
                        SizedBox(width: 8),
                        Text('Denunciar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          if (comment.images.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: comment.images.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: comment.images[index],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: onLike,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        comment.isLikedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 14,
                        color: comment.isLikedByMe
                            ? Colors.red
                            : AppColors.mediumGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.likesCount}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mediumGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: onReply,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Text(
                    'Responder',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(left: 24),
              child: Column(
                children: comment.replies.take(2).map((reply) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: PostCommentCard(comment: reply),
                  );
                }).toList(),
              ),
            ),
            if (comment.replies.length > 2)
              Container(
                margin: const EdgeInsets.only(left: 24),
                child: TextButton(
                  onPressed: () {
                    // Show all replies
                  },
                  child: Text(
                    'Ver mais ${comment.replies.length - 2} respostas',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Community event card
class CommunityEventCard extends StatelessWidget {
  const CommunityEventCard({
    Key? key,
    required this.event,
    this.onJoin,
    this.onLeave,
    this.onTap,
  }) : super(key: key);
  final CommunityEvent event;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildEventTypeIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy • HH:mm',
                          ).format(event.startTime),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGrey,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (event.speakers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: event.speakers.map((speaker) {
                    return Chip(
                      label: Text(
                        speaker,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppColors.lightGrey.withOpacity(0.5),
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.people,
                    size: 16,
                    color: AppColors.mediumGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${event.attendeesCount}/${event.maxAttendees} participantes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                  ),
                  const Spacer(),
                  if (event.isAttending && onLeave != null)
                    OutlinedButton(
                      onPressed: onLeave,
                      child: const Text('Cancelar'),
                    )
                  else if (!event.isAttending && onJoin != null)
                    ElevatedButton(
                      onPressed: onJoin,
                      child: const Text('Participar'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventTypeIcon() {
    IconData icon;
    Color color;

    switch (event.type) {
      case EventType.webinar:
        icon = Icons.video_call;
        color = AppColors.primary;
        break;
      case EventType.live:
        icon = Icons.live_tv;
        color = Colors.red;
        break;
      case EventType.workshop:
        icon = Icons.work;
        color = AppColors.categoryPerformance;
        break;
      case EventType.meetup:
        icon = Icons.group;
        color = AppColors.categoryAesthetic;
        break;
      case EventType.consultation:
        icon = Icons.medical_services;
        color = AppColors.categoryDiagnostic;
        break;
      case EventType.qa:
        icon = Icons.question_answer;
        color = AppColors.categoryInjectable;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (event.status) {
      case EventStatus.upcoming:
        statusColor = AppColors.warning;
        statusText = 'Em breve';
        break;
      case EventStatus.live:
        statusColor = Colors.red;
        statusText = 'Ao vivo';
        break;
      case EventStatus.ended:
        statusColor = AppColors.mediumGrey;
        statusText = 'Encerrado';
        break;
      case EventStatus.cancelled:
        statusColor = AppColors.error;
        statusText = 'Cancelado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
