import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/features/engagement/controllers/community_controller.dart';
import 'package:singleclin_mobile/features/engagement/widgets/community_post_card.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CommunityController>(
      builder: (controller) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Comunidade'),
              backgroundColor: const Color(0xFF005156),
              foregroundColor: Colors.white,
              bottom: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Color(0xFFFFB000),
                tabs: [
                  Tab(icon: Icon(Icons.home), text: 'Feed'),
                  Tab(icon: Icon(Icons.group), text: 'Grupos'),
                  Tab(icon: Icon(Icons.event), text: 'Eventos'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showCreatePostDialog(context, controller),
                ),
              ],
            ),
            body: TabBarView(
              children: [
                _buildFeedTab(controller),
                _buildGroupsTab(controller),
                _buildEventsTab(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedTab(CommunityController controller) {
    return Column(
      children: [
        // Create post prompt
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF005156),
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCreatePostDialog(Get.context!, controller),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Compartilhe sua experiência...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.photo_camera, color: Color(0xFF005156)),
                onPressed: () =>
                    _showCreatePostDialog(Get.context!, controller),
              ),
            ],
          ),
        ),

        // Filter options
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Recentes'),
                  selected: controller.selectedFilter == 'recent',
                  onSelected: (_) => controller.filterPosts('recent'),
                  backgroundColor: Colors.grey[200],
                  selectedColor: const Color(0xFF005156),
                  labelStyle: TextStyle(
                    color: controller.selectedFilter == 'recent'
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Populares'),
                  selected: controller.selectedFilter == 'popular',
                  onSelected: (_) => controller.filterPosts('popular'),
                  backgroundColor: Colors.grey[200],
                  selectedColor: const Color(0xFF005156),
                  labelStyle: TextStyle(
                    color: controller.selectedFilter == 'popular'
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Seguindo'),
                  selected: controller.selectedFilter == 'following',
                  onSelected: (_) => controller.filterPosts('following'),
                  backgroundColor: Colors.grey[200],
                  selectedColor: const Color(0xFF005156),
                  labelStyle: TextStyle(
                    color: controller.selectedFilter == 'following'
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Posts list
        Expanded(
          child: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : controller.filteredPosts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.forum, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum post encontrado',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Seja o primeiro a compartilhar!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: controller.loadPosts,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post = controller.filteredPosts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CommunityPostCard(
                          post: post,
                          onLike: () => controller.likePost(post.id),
                          onComment: () => _showCommentsDialog(
                            Get.context!,
                            post.id,
                            controller,
                          ),
                          onShare: () => controller.sharePost(post.id),
                          onReport: () => controller.reportPost(post.id),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildGroupsTab(CommunityController controller) {
    return Column(
      children: [
        // My groups section
        if (controller.joinedGroups.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meus Grupos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005156),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.joinedGroups.length,
                    itemBuilder: (context, index) {
                      final group = controller.joinedGroups[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => controller.selectGroup(group.id),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: const Color(0xFF005156),
                                child: Text(
                                  group.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  group.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
        ],

        // Discover groups
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Descobrir Grupos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005156),
                  ),
                ),
              ),
              Expanded(
                child: controller.availableGroups.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum grupo disponível',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: controller.availableGroups.length,
                        itemBuilder: (context, index) {
                          final group = controller.availableGroups[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF005156),
                                child: Text(
                                  group.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                group.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(group.description),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${group.memberCount} membros',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => controller.joinGroup(group.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF005156),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(80, 32),
                                ),
                                child: const Text('Participar'),
                              ),
                              onTap: () => _showGroupDetails(group, controller),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventsTab(CommunityController controller) {
    return Column(
      children: [
        // Upcoming events
        if (controller.upcomingEvents.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Próximos Eventos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005156),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.upcomingEvents.length,
                    itemBuilder: (context, index) {
                      final event = controller.upcomingEvents[index];
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatEventDate(event.date),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${event.attendeeCount} participantes',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: () =>
                                      controller.joinEvent(event.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF005156),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(
                                      double.infinity,
                                      28,
                                    ),
                                  ),
                                  child: const Text(
                                    'Participar',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
        ],

        // All events
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Todos os Eventos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005156),
                  ),
                ),
              ),
              Expanded(
                child: controller.allEvents.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum evento encontrado',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: controller.allEvents.length,
                        itemBuilder: (context, index) {
                          final event = controller.allEvents[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF005156),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      event.date.day.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _getMonthAbbreviation(event.date.month),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(
                                event.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.description),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.people,
                                        size: 12,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${event.attendeeCount} participantes',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: event.isJoined
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : ElevatedButton(
                                      onPressed: () =>
                                          controller.joinEvent(event.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF005156,
                                        ),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(80, 32),
                                      ),
                                      child: const Text('Participar'),
                                    ),
                              onTap: () => _showEventDetails(event, controller),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCreatePostDialog(
    BuildContext context,
    CommunityController controller,
  ) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Criar Post',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.postContentController,
                decoration: const InputDecoration(
                  hintText: 'Compartilhe sua experiência...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 500,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_camera),
                    onPressed: controller.pickPostImage,
                    color: const Color(0xFF005156),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library),
                    onPressed: controller.pickPostImage,
                    color: const Color(0xFF005156),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: Get.back,
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      controller.createPost();
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005156),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Publicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommentsDialog(
    BuildContext context,
    String postId,
    CommunityController controller,
  ) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comentários',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.getCommentsForPost(postId).length,
                  itemBuilder: (context, index) {
                    final comment = controller.getCommentsForPost(
                      postId,
                    )[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(comment.authorName),
                      subtitle: Text(comment.content),
                      trailing: Text(_formatCommentDate(comment.createdAt)),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.commentController,
                      decoration: const InputDecoration(
                        hintText: 'Escreva um comentário...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => controller.addComment(postId),
                    color: const Color(0xFF005156),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGroupDetails(dynamic group, CommunityController controller) {
    Get.dialog(
      AlertDialog(
        title: Text(group.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.description),
            const SizedBox(height: 12),
            Text('${group.memberCount} membros'),
            Text('Criado em: ${_formatDate(group.createdAt)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Fechar')),
          ElevatedButton(
            onPressed: () {
              controller.joinGroup(group.id);
              Get.back();
            },
            child: const Text('Participar'),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(dynamic event, CommunityController controller) {
    Get.dialog(
      AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.description),
            const SizedBox(height: 12),
            Text('Data: ${_formatEventDate(event.date)}'),
            Text('${event.attendeeCount} participantes'),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Fechar')),
          if (!event.isJoined)
            ElevatedButton(
              onPressed: () {
                controller.joinEvent(event.id);
                Get.back();
              },
              child: const Text('Participar'),
            ),
        ],
      ),
    );
  }

  String _formatEventDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatCommentDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}min';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      '',
      'JAN',
      'FEV',
      'MAR',
      'ABR',
      'MAI',
      'JUN',
      'JUL',
      'AGO',
      'SET',
      'OUT',
      'NOV',
      'DEZ',
    ];
    return months[month];
  }
}
