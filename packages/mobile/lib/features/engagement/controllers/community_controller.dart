import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:singleclin_mobile/core/services/api_service.dart';
import 'package:singleclin_mobile/features/credits/controllers/credits_controller.dart';
import 'package:singleclin_mobile/features/engagement/models/community_post.dart';

/// Controller for community interactions and social features
class CommunityController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final CreditsController _creditsController = Get.find<CreditsController>();

  // Form controllers
  final postTitleController = TextEditingController();
  final postContentController = TextEditingController();
  final commentController = TextEditingController();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isPosting = false.obs;
  final RxString error = ''.obs;

  final RxList<CommunityPost> posts = <CommunityPost>[].obs;
  final RxList<CommunityEvent> events = <CommunityEvent>[].obs;
  final Rx<CommunityStats?> stats = Rx<CommunityStats?>(null);

  // Filters and sorting
  final Rx<CommunityGroup> selectedGroup = CommunityGroup.general.obs;
  final Rx<PostType> selectedPostType = PostType.experience.obs;
  final RxString selectedSort = 'recent'.obs;

  // Post creation
  final RxList<File> selectedImages = <File>[].obs;
  final RxList<String> selectedTags = <String>[].obs;
  final RxBool isAnonymous = false.obs;
  final Rx<PostVisibility> postVisibility = PostVisibility.public.obs;

  // Pagination
  int _currentPage = 1;
  bool _hasMoreData = true;

  @override
  void onInit() {
    super.onInit();
    loadPosts();
    loadCommunityStats();
    loadUpcomingEvents();
  }

  @override
  void onClose() {
    postTitleController.dispose();
    postContentController.dispose();
    commentController.dispose();
    super.onClose();
  }

  /// Load community posts
  Future<void> loadPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      posts.clear();
    }

    if (!_hasMoreData || isLoading.value) return;

    try {
      refresh ? isLoading.value = true : isLoadingMore.value = true;
      error.value = '';

      final response = await _apiService.get(
        '/community/posts',
        queryParameters: {
          'page': _currentPage,
          'group': selectedGroup.value.name,
          'sort': selectedSort.value,
          'limit': 20,
        },
      );

      final List<CommunityPost> newPosts = (response.data['posts'] as List)
          .map((json) => CommunityPost.fromJson(json))
          .toList();

      if (refresh) {
        posts.assignAll(newPosts);
      } else {
        posts.addAll(newPosts);
      }

      _currentPage++;
      _hasMoreData = newPosts.length >= 20;
    } catch (e) {
      error.value = 'Erro ao carregar posts: ${e.toString()}';
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Load community statistics
  Future<void> loadCommunityStats() async {
    try {
      final response = await _apiService.get('/community/stats');
      stats.value = CommunityStats.fromJson(response.data);
    } catch (e) {
      print('Error loading community stats: $e');
    }
  }

  /// Load upcoming events
  Future<void> loadUpcomingEvents() async {
    try {
      final response = await _apiService.get(
        '/community/events',
        queryParameters: {'upcoming': true, 'limit': 10},
      );

      final List<CommunityEvent> upcomingEvents =
          (response.data['events'] as List)
              .map((json) => CommunityEvent.fromJson(json))
              .toList();

      events.assignAll(upcomingEvents);
    } catch (e) {
      print('Error loading events: $e');
    }
  }

  /// Create new post
  Future<void> createPost() async {
    if (!validatePostForm()) return;

    try {
      isPosting.value = true;
      error.value = '';

      // Upload images if any
      final List<String> imageUrls = await uploadImages();

      final postData = {
        'title': postTitleController.text.trim(),
        'content': postContentController.text.trim(),
        'type': selectedPostType.value.name,
        'group': selectedGroup.value.name,
        'tags': selectedTags.toList(),
        'images': imageUrls,
        'isAnonymous': isAnonymous.value,
        'visibility': postVisibility.value.name,
      };

      final response = await _apiService.post(
        '/community/posts',
        data: postData,
      );

      final newPost = CommunityPost.fromJson(response.data['post']);
      posts.insert(0, newPost);

      // Award SG credits for community participation
      await _creditsController.awardCreditsForCommunityPost(newPost.id);

      // Clear form
      clearPostForm();

      Get.snackbar(
        'Post publicado!',
        'Sua publicação foi compartilhada com a comunidade. +2 SG!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.back();
    } catch (e) {
      error.value = 'Erro ao publicar: ${e.toString()}';
      Get.snackbar(
        'Erro',
        error.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isPosting.value = false;
    }
  }

  /// Like/unlike a post
  Future<void> togglePostLike(String postId) async {
    try {
      final postIndex = posts.indexWhere((p) => p.id == postId);
      if (postIndex == -1) return;

      final post = posts[postIndex];
      final isCurrentlyLiked = post.isLikedByMe;

      // Optimistic update
      final updatedPost = post.copyWith(
        isLikedByMe: !isCurrentlyLiked,
        likesCount: isCurrentlyLiked
            ? post.likesCount - 1
            : post.likesCount + 1,
      );
      posts[postIndex] = updatedPost;

      // API call
      await _apiService.post('/community/posts/$postId/like');
    } catch (e) {
      // Revert on error
      loadPosts(refresh: true);
      Get.snackbar(
        'Erro',
        'Não foi possível curtir o post',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Toggle bookmark on post
  Future<void> togglePostBookmark(String postId) async {
    try {
      final postIndex = posts.indexWhere((p) => p.id == postId);
      if (postIndex == -1) return;

      final post = posts[postIndex];
      final isCurrentlyBookmarked = post.isBookmarked;

      // Optimistic update
      final updatedPost = post.copyWith(isBookmarked: !isCurrentlyBookmarked);
      posts[postIndex] = updatedPost;

      // API call
      await _apiService.post('/community/posts/$postId/bookmark');

      Get.snackbar(
        isCurrentlyBookmarked
            ? 'Removido dos favoritos'
            : 'Salvo nos favoritos',
        isCurrentlyBookmarked
            ? 'Post removido da sua lista de favoritos'
            : 'Post salvo na sua lista de favoritos',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // Revert on error
      loadPosts(refresh: true);
      Get.snackbar(
        'Erro',
        'Não foi possível salvar o post',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Add comment to post
  Future<void> addComment(String postId) async {
    if (commentController.text.trim().isEmpty) return;

    try {
      final commentData = {
        'content': commentController.text.trim(),
        'isAnonymous': isAnonymous.value,
      };

      final response = await _apiService.post(
        '/community/posts/$postId/comments',
        data: commentData,
      );

      final newComment = PostComment.fromJson(response.data['comment']);

      // Update post with new comment
      final postIndex = posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = posts[postIndex];
        final updatedPost = post.copyWith(
          comments: [...post.comments, newComment],
          commentsCount: post.commentsCount + 1,
        );
        posts[postIndex] = updatedPost;
      }

      commentController.clear();

      Get.snackbar(
        'Comentário adicionado!',
        'Seu comentário foi publicado',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível adicionar o comentário',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Share post
  Future<void> sharePost(String postId) async {
    try {
      await _apiService.post('/community/posts/$postId/share');

      // Update share count locally
      final postIndex = posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = posts[postIndex];
        final updatedPost = post.copyWith(sharesCount: post.sharesCount + 1);
        posts[postIndex] = updatedPost;
      }

      // Show sharing options (would integrate with native sharing)
      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copiar link'),
                onTap: () => _copyPostLink(postId),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Compartilhar externamente'),
                onTap: () => _shareExternal(postId),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível compartilhar o post',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Report post
  Future<void> reportPost(String postId, String reason) async {
    try {
      await _apiService.post(
        '/community/posts/$postId/report',
        data: {'reason': reason},
      );

      Get.snackbar(
        'Denúncia enviada',
        'Obrigado por nos ajudar a manter a comunidade segura',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível enviar a denúncia',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Join community event
  Future<void> joinEvent(String eventId) async {
    try {
      await _apiService.post('/community/events/$eventId/join');

      final eventIndex = events.indexWhere((e) => e.id == eventId);
      if (eventIndex != -1) {
        final event = events[eventIndex];
        final updatedEvent = event.copyWith(
          isAttending: true,
          attendeesCount: event.attendeesCount + 1,
        );
        events[eventIndex] = updatedEvent;
      }

      Get.snackbar(
        'Inscrição confirmada!',
        'Você se inscreveu no evento com sucesso',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível se inscrever no evento',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Leave community event
  Future<void> leaveEvent(String eventId) async {
    try {
      await _apiService.post('/community/events/$eventId/leave');

      final eventIndex = events.indexWhere((e) => e.id == eventId);
      if (eventIndex != -1) {
        final event = events[eventIndex];
        final updatedEvent = event.copyWith(
          isAttending: false,
          attendeesCount: event.attendeesCount - 1,
        );
        events[eventIndex] = updatedEvent;
      }

      Get.snackbar(
        'Inscrição cancelada',
        'Sua inscrição foi cancelada',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível cancelar a inscrição',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Pick images for post
  Future<void> pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isNotEmpty && selectedImages.length + images.length <= 5) {
        for (final image in images) {
          selectedImages.add(File(image.path));
        }
      } else if (selectedImages.length + images.length > 5) {
        Get.snackbar(
          'Limite de imagens',
          'Você pode adicionar no máximo 5 imagens por post',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível adicionar as imagens',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Remove selected image
  void removeImage(int index) {
    if (index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  /// Toggle tag selection
  void toggleTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
  }

  /// Upload images to server
  Future<List<String>> uploadImages() async {
    if (selectedImages.isEmpty) return [];

    try {
      final List<String> uploadedUrls = [];

      for (final image in selectedImages) {
        final response = await _apiService.uploadFile(
          '/upload/community-image',
          image.path,
          fileName: image.path.split('/').last,
        );

        uploadedUrls.add(response.data['url']);
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Erro ao fazer upload das imagens: $e');
    }
  }

  /// Validate post form
  bool validatePostForm() {
    if (postTitleController.text.trim().isEmpty) {
      error.value = 'Por favor, adicione um título';
      return false;
    }

    if (postContentController.text.trim().length < 10) {
      error.value = 'O conteúdo deve ter pelo menos 10 caracteres';
      return false;
    }

    return true;
  }

  /// Clear post form
  void clearPostForm() {
    postTitleController.clear();
    postContentController.clear();
    selectedImages.clear();
    selectedTags.clear();
    selectedPostType.value = PostType.experience;
    isAnonymous.value = false;
    postVisibility.value = PostVisibility.public;
  }

  /// Filter posts by group
  void filterByGroup(CommunityGroup group) {
    selectedGroup.value = group;
    loadPosts(refresh: true);
  }

  /// Sort posts
  void sortPosts(String sortBy) {
    selectedSort.value = sortBy;
    loadPosts(refresh: true);
  }

  /// Load more posts
  Future<void> loadMore() async {
    if (_hasMoreData && !isLoadingMore.value) {
      await loadPosts();
    }
  }

  /// Refresh all data
  @override
  Future<void> refresh() async {
    await Future.wait([
      loadPosts(refresh: true),
      loadCommunityStats(),
      loadUpcomingEvents(),
    ]);
  }

  /// Copy post link
  void _copyPostLink(String postId) {
    // Implementation would copy link to clipboard
    Get.back();
    Get.snackbar(
      'Link copiado!',
      'O link do post foi copiado para a área de transferência',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Share externally
  void _shareExternal(String postId) {
    // Implementation would use native sharing
    Get.back();
  }

  /// Get group display name
  String getGroupDisplayName(CommunityGroup group) {
    switch (group) {
      case CommunityGroup.general:
        return 'Geral';
      case CommunityGroup.aestheticFacial:
        return 'Estética Facial';
      case CommunityGroup.injectableTherapies:
        return 'Terapias Injetáveis';
      case CommunityGroup.diagnostics:
        return 'Diagnósticos';
      case CommunityGroup.performanceHealth:
        return 'Performance & Saúde';
      case CommunityGroup.weightLoss:
        return 'Emagrecimento';
      case CommunityGroup.skincare:
        return 'Cuidados com a Pele';
      case CommunityGroup.antiAging:
        return 'Anti-idade';
      case CommunityGroup.wellness:
        return 'Bem-estar';
    }
  }

  /// Get post type display name
  String getPostTypeDisplayName(PostType type) {
    switch (type) {
      case PostType.experience:
        return 'Experiência';
      case PostType.question:
        return 'Pergunta';
      case PostType.tip:
        return 'Dica';
      case PostType.beforeAfter:
        return 'Antes e Depois';
      case PostType.recommendation:
        return 'Recomendação';
      case PostType.story:
        return 'História';
      case PostType.review:
        return 'Avaliação';
    }
  }

  /// Get available tags
  List<String> get availableTags => [
    'experiencia',
    'resultado',
    'recomendo',
    'primeira-vez',
    'transformacao',
    'autoestima',
    'profissional',
    'clinica',
    'valor',
    'atendimento',
    'procedimento',
    'recuperacao',
  ];

  /// Get sort options
  List<Map<String, String>> get sortOptions => [
    {'key': 'recent', 'label': 'Mais Recentes'},
    {'key': 'popular', 'label': 'Mais Populares'},
    {'key': 'trending', 'label': 'Em Alta'},
    {'key': 'most_liked', 'label': 'Mais Curtidos'},
    {'key': 'most_commented', 'label': 'Mais Comentados'},
  ];

  /// Get engagement level for user
  String get userEngagementLevel {
    final score = stats.value?.engagementScore ?? 0;

    if (score >= 1000) {
      return 'Influenciador da Comunidade';
    } else if (score >= 500) {
      return 'Membro Ativo';
    } else if (score >= 200) {
      return 'Contribuidor Regular';
    } else if (score >= 50) {
      return 'Participante';
    } else {
      return 'Novo na Comunidade';
    }
  }
}
