import 'package:get/get.dart';
import '../models/review.dart';
import '../../../core/services/api_service.dart';

/// Controller for managing user reviews and ratings
class ReviewsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;
  final RxList<Review> reviews = <Review>[].obs;
  final RxList<Review> pendingReviews = <Review>[].obs;
  final Rx<ReviewStats?> stats = Rx<ReviewStats?>(null);
  
  // Filter and sort options
  final RxString selectedFilter = 'all'.obs;
  final RxString selectedSort = 'newest'.obs;
  final RxString searchQuery = ''.obs;
  
  // Pagination
  int _currentPage = 1;
  bool _hasMoreData = true;

  @override
  void onInit() {
    super.onInit();
    loadReviews();
    loadReviewStats();
    loadPendingReviews();
  }

  /// Load user reviews with filtering and sorting
  Future<void> loadReviews({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      reviews.clear();
    }

    if (!_hasMoreData || isLoading.value) return;

    try {
      refresh ? isLoading.value = true : isLoadingMore.value = true;
      error.value = '';

      final response = await _apiService.get(
        '/user/reviews',
        queryParameters: {
          'page': _currentPage,
          'filter': selectedFilter.value,
          'sort': selectedSort.value,
          'search': searchQuery.value.isNotEmpty ? searchQuery.value : null,
        },
      );

      final List<Review> newReviews = (response.data['reviews'] as List)
          .map((json) => Review.fromJson(json))
          .toList();

      if (refresh) {
        reviews.assignAll(newReviews);
      } else {
        reviews.addAll(newReviews);
      }

      _currentPage++;
      _hasMoreData = newReviews.length >= 10;
    } catch (e) {
      error.value = 'Erro ao carregar avaliações: ${e.toString()}';
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Load pending reviews (waiting for user to write)
  Future<void> loadPendingReviews() async {
    try {
      final response = await _apiService.get('/user/reviews/pending');
      
      final List<Review> pending = (response.data['reviews'] as List)
          .map((json) => Review.fromJson(json))
          .toList();

      pendingReviews.assignAll(pending);
    } catch (e) {
      print('Error loading pending reviews: $e');
    }
  }

  /// Load review statistics
  Future<void> loadReviewStats() async {
    try {
      final response = await _apiService.get('/user/reviews/stats');
      stats.value = ReviewStats.fromJson(response.data);
    } catch (e) {
      print('Error loading review stats: $e');
    }
  }

  /// Vote on review helpfulness
  Future<void> voteOnReview(String reviewId, bool isHelpful) async {
    try {
      await _apiService.post('/reviews/$reviewId/vote', data: {
        'isHelpful': isHelpful,
      });

      // Update local review
      final reviewIndex = reviews.indexWhere((r) => r.id == reviewId);
      if (reviewIndex != -1) {
        final review = reviews[reviewIndex];
        final updatedReview = review.copyWith(
          helpfulCount: isHelpful 
              ? review.helpfulCount + 1 
              : review.helpfulCount,
          notHelpfulCount: !isHelpful 
              ? review.notHelpfulCount + 1 
              : review.notHelpfulCount,
        );
        reviews[reviewIndex] = updatedReview;
      }

      Get.snackbar(
        'Obrigado!', 
        'Sua avaliação foi registrada',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro', 
        'Não foi possível registrar sua avaliação',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Report inappropriate review
  Future<void> reportReview(String reviewId, String reason) async {
    try {
      await _apiService.post('/reviews/$reviewId/report', data: {
        'reason': reason,
      });

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

  /// Delete user's own review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _apiService.delete('/user/reviews/$reviewId');
      
      reviews.removeWhere((r) => r.id == reviewId);
      
      Get.snackbar(
        'Avaliação removida', 
        'Sua avaliação foi excluída com sucesso',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Reload stats
      loadReviewStats();
    } catch (e) {
      Get.snackbar(
        'Erro', 
        'Não foi possível remover a avaliação',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Update filter
  void updateFilter(String filter) {
    selectedFilter.value = filter;
    loadReviews(refresh: true);
  }

  /// Update sort order
  void updateSort(String sort) {
    selectedSort.value = sort;
    loadReviews(refresh: true);
  }

  /// Search reviews
  void searchReviews(String query) {
    searchQuery.value = query;
    loadReviews(refresh: true);
  }

  /// Load more reviews (for infinite scroll)
  Future<void> loadMore() async {
    if (_hasMoreData && !isLoadingMore.value) {
      await loadReviews();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      loadReviews(refresh: true),
      loadReviewStats(),
      loadPendingReviews(),
    ]);
  }

  /// Get reviews by rating filter
  List<Review> get reviewsByRating {
    switch (selectedFilter.value) {
      case '5stars':
        return reviews.where((r) => r.overallRating >= 4.5).toList();
      case '4stars':
        return reviews.where((r) => r.overallRating >= 3.5 && r.overallRating < 4.5).toList();
      case '3stars':
        return reviews.where((r) => r.overallRating >= 2.5 && r.overallRating < 3.5).toList();
      case 'low':
        return reviews.where((r) => r.overallRating < 2.5).toList();
      case 'photos':
        return reviews.where((r) => r.beforePhotos.isNotEmpty || r.afterPhotos.isNotEmpty).toList();
      case 'recommended':
        return reviews.where((r) => r.isRecommended).toList();
      default:
        return reviews;
    }
  }

  /// Get badge info for user
  String getBadgeText() {
    final totalReviews = stats.value?.totalReviews ?? 0;
    
    if (totalReviews >= 100) {
      return 'Especialista em Avaliações';
    } else if (totalReviews >= 50) {
      return 'Avaliador Expert';
    } else if (totalReviews >= 20) {
      return 'Contribuidor Ativo';
    } else if (totalReviews >= 5) {
      return 'Avaliador Iniciante';
    } else {
      return 'Novo Avaliador';
    }
  }

  /// Get available filter options
  List<Map<String, String>> get filterOptions => [
    {'key': 'all', 'label': 'Todas'},
    {'key': '5stars', 'label': '5 Estrelas'},
    {'key': '4stars', 'label': '4 Estrelas'},
    {'key': '3stars', 'label': '3 Estrelas'},
    {'key': 'low', 'label': 'Baixa Avaliação'},
    {'key': 'photos', 'label': 'Com Fotos'},
    {'key': 'recommended', 'label': 'Recomendadas'},
  ];

  /// Get available sort options
  List<Map<String, String>> get sortOptions => [
    {'key': 'newest', 'label': 'Mais Recentes'},
    {'key': 'oldest', 'label': 'Mais Antigas'},
    {'key': 'highest', 'label': 'Maior Avaliação'},
    {'key': 'lowest', 'label': 'Menor Avaliação'},
    {'key': 'helpful', 'label': 'Mais Úteis'},
  ];

  /// Check if user can write review for appointment
  bool canWriteReview(String appointmentId) {
    return !reviews.any((r) => r.appointmentId == appointmentId);
  }

  /// Get clinic average rating from user reviews
  double getClinicAverageRating(String clinicId) {
    final clinicReviews = reviews.where((r) => r.clinicId == clinicId).toList();
    if (clinicReviews.isEmpty) return 0.0;
    
    final total = clinicReviews.fold(0.0, (sum, review) => sum + review.overallRating);
    return total / clinicReviews.length;
  }

  /// Get service average rating from user reviews
  double getServiceAverageRating(String serviceId) {
    final serviceReviews = reviews.where((r) => r.serviceId == serviceId).toList();
    if (serviceReviews.isEmpty) return 0.0;
    
    final total = serviceReviews.fold(0.0, (sum, review) => sum + review.overallRating);
    return total / serviceReviews.length;
  }
}