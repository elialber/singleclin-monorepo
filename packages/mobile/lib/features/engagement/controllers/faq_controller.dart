import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/core/services/api_service.dart';
import 'package:singleclin_mobile/features/engagement/models/faq_item.dart';

/// Controller for FAQ and knowledge base
class FaqController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Form controllers
  final searchController = TextEditingController();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxString error = ''.obs;

  final RxList<FaqItem> faqItems = <FaqItem>[].obs;
  final RxList<FaqItem> searchResults = <FaqItem>[].obs;
  final RxList<String> searchSuggestions = <String>[].obs;
  final Rx<FaqStats?> stats = Rx<FaqStats?>(null);

  // Filters and search
  final Rx<FaqCategory?> selectedCategory = Rx<FaqCategory?>(null);
  final RxString searchQuery = ''.obs;
  final RxList<String> searchHistory = <String>[].obs;

  // Chatbot functionality
  final RxBool isChatbotActive = false.obs;
  final RxList<ChatbotResponse> chatbotResponses = <ChatbotResponse>[].obs;
  final messageController = TextEditingController();

  // Expandable items state
  final RxSet<String> expandedItems = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadFaqItems();
    loadFaqStats();
    loadSearchHistory();

    // Setup search debouncing
    searchController.addListener(_onSearchChanged);
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    messageController.dispose();
    super.onClose();
  }

  /// Load FAQ items
  Future<void> loadFaqItems({bool refresh = false}) async {
    try {
      refresh ? isLoading.value = true : null;
      error.value = '';

      final response = await _apiService.get(
        '/faq/items',
        queryParameters: {
          'category': selectedCategory.value?.name,
          'published': true,
        },
      );

      final List<FaqItem> items = (response.data['items'] as List)
          .map((json) => FaqItem.fromJson(json))
          .toList();

      faqItems.assignAll(items);
    } catch (e) {
      error.value = 'Erro ao carregar FAQ: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load FAQ statistics
  Future<void> loadFaqStats() async {
    try {
      final response = await _apiService.get('/faq/stats');
      stats.value = FaqStats.fromJson(response.data);
    } catch (e) {
      print('Error loading FAQ stats: $e');
    }
  }

  /// Search FAQ items
  Future<void> searchFaq(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      searchSuggestions.clear();
      return;
    }

    try {
      isSearching.value = true;
      searchQuery.value = query.trim();

      final response = await _apiService.get(
        '/faq/search',
        queryParameters: {'q': query.trim(), 'limit': 20},
      );

      final searchResult = FaqSearchResult.fromJson(response.data);
      searchResults.assignAll(searchResult.items);
      searchSuggestions.assignAll(searchResult.suggestions);

      // Add to search history
      _addToSearchHistory(query.trim());
    } catch (e) {
      error.value = 'Erro ao buscar: ${e.toString()}';
    } finally {
      isSearching.value = false;
    }
  }

  /// Get chatbot response
  Future<void> getChatbotResponse(String message) async {
    if (message.trim().isEmpty) return;

    try {
      final response = await _apiService.post(
        '/faq/chatbot',
        data: {
          'message': message.trim(),
          'context': chatbotResponses.map((r) => r.message).toList(),
        },
      );

      final chatbotResponse = ChatbotResponse.fromJson(response.data);
      chatbotResponses.add(chatbotResponse);

      messageController.clear();

      // If chatbot suggests human support
      if (chatbotResponse.needsHumanSupport) {
        Get.snackbar(
          'Falar com atendente?',
          'Posso conectar você com nosso suporte humano',
          snackPosition: SnackPosition.BOTTOM,
          mainButton: TextButton(
            onPressed: _startHumanSupport,
            child: const Text('Sim', style: TextStyle(color: Colors.white)),
          ),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível obter resposta do assistente',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Toggle FAQ item expansion
  void toggleItemExpansion(String itemId) {
    if (expandedItems.contains(itemId)) {
      expandedItems.remove(itemId);
    } else {
      expandedItems.add(itemId);
      _incrementViewCount(itemId);
    }
  }

  /// Vote on FAQ helpfulness
  Future<void> voteOnFaq(String faqId, bool isHelpful) async {
    try {
      await _apiService.post(
        '/faq/$faqId/vote',
        data: {'isHelpful': isHelpful},
      );

      // Update local item
      _updateFaqVotes(faqId, isHelpful);

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

  /// Filter by category
  void filterByCategory(FaqCategory? category) {
    selectedCategory.value = category;
    loadFaqItems(refresh: true);
  }

  /// Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    searchResults.clear();
    searchSuggestions.clear();
  }

  /// Apply search suggestion
  void applySearchSuggestion(String suggestion) {
    searchController.text = suggestion;
    searchFaq(suggestion);
  }

  /// Start human support
  void _startHumanSupport() {
    Get.toNamed('/support');
  }

  /// Add to search history
  void _addToSearchHistory(String query) {
    if (!searchHistory.contains(query)) {
      searchHistory.insert(0, query);
      if (searchHistory.length > 10) {
        searchHistory.removeRange(10, searchHistory.length);
      }
      _saveSearchHistory();
    }
  }

  /// Load search history from storage
  void loadSearchHistory() {
    // Implementation would load from local storage
    // This is a placeholder
  }

  /// Save search history to storage
  void _saveSearchHistory() {
    // Implementation would save to local storage
    // This is a placeholder
  }

  /// Increment view count for FAQ item
  Future<void> _incrementViewCount(String itemId) async {
    try {
      await _apiService.post('/faq/$itemId/view');

      // Update local item view count
      final itemIndex = faqItems.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        final updatedItem = faqItems[itemIndex].copyWith(
          viewCount: faqItems[itemIndex].viewCount + 1,
        );
        faqItems[itemIndex] = updatedItem;
      }
    } catch (e) {
      // Silent fail for analytics
      print('Error incrementing view count: $e');
    }
  }

  /// Update FAQ votes locally
  void _updateFaqVotes(String faqId, bool isHelpful) {
    final itemIndex = faqItems.indexWhere((item) => item.id == faqId);
    if (itemIndex != -1) {
      final item = faqItems[itemIndex];
      final updatedItem = item.copyWith(
        helpfulCount: isHelpful ? item.helpfulCount + 1 : item.helpfulCount,
        notHelpfulCount: !isHelpful
            ? item.notHelpfulCount + 1
            : item.notHelpfulCount,
      );
      faqItems[itemIndex] = updatedItem;
    }

    // Also update in search results if present
    final searchIndex = searchResults.indexWhere((item) => item.id == faqId);
    if (searchIndex != -1) {
      final item = searchResults[searchIndex];
      final updatedItem = item.copyWith(
        helpfulCount: isHelpful ? item.helpfulCount + 1 : item.helpfulCount,
        notHelpfulCount: !isHelpful
            ? item.notHelpfulCount + 1
            : item.notHelpfulCount,
      );
      searchResults[searchIndex] = updatedItem;
    }
  }

  /// Handle search input changes (debounced)
  void _onSearchChanged() {
    // Implement debouncing logic here
    if (searchController.text.isEmpty) {
      clearSearch();
    } else if (searchController.text.length >= 3) {
      searchFaq(searchController.text);
    }
  }

  /// Get category display name
  String getCategoryDisplayName(FaqCategory category) {
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

  /// Get FAQ items by category
  List<FaqItem> getFaqByCategory(FaqCategory category) {
    return faqItems.where((item) => item.category == category).toList();
  }

  /// Get most viewed FAQ items
  List<FaqItem> get mostViewedFaqs {
    final sorted = List<FaqItem>.from(faqItems);
    sorted.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return sorted.take(5).toList();
  }

  /// Get most helpful FAQ items
  List<FaqItem> get mostHelpfulFaqs {
    final sorted = List<FaqItem>.from(faqItems);
    sorted.sort((a, b) {
      final aRatio = a.helpfulCount / (a.helpfulCount + a.notHelpfulCount + 1);
      final bRatio = b.helpfulCount / (b.helpfulCount + b.notHelpfulCount + 1);
      return bRatio.compareTo(aRatio);
    });
    return sorted.take(5).toList();
  }

  /// Get categories with FAQ counts
  Map<FaqCategory, int> get categoryCounts {
    final Map<FaqCategory, int> counts = {};
    for (final item in faqItems) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  /// Check if FAQ item is expanded
  bool isItemExpanded(String itemId) {
    return expandedItems.contains(itemId);
  }

  /// Toggle chatbot
  void toggleChatbot() {
    isChatbotActive.value = !isChatbotActive.value;
    if (!isChatbotActive.value) {
      chatbotResponses.clear();
      messageController.clear();
    }
  }

  /// Get related FAQ items
  List<FaqItem> getRelatedFaqs(FaqItem item) {
    return faqItems
        .where(
          (faq) =>
              faq.id != item.id &&
              (faq.category == item.category ||
                  faq.tags.any((tag) => item.tags.contains(tag))),
        )
        .take(3)
        .toList();
  }

  /// Submit FAQ feedback
  Future<void> submitFeedback(String faqId, String feedback) async {
    try {
      await _apiService.post(
        '/faq/$faqId/feedback',
        data: {'feedback': feedback},
      );

      Get.snackbar(
        'Feedback enviado!',
        'Obrigado por nos ajudar a melhorar',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível enviar o feedback',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Get emergency contact info
  Map<String, String> get emergencyContacts => {
    'Suporte Técnico': '(11) 9999-0000',
    'Emergência Médica': '192',
    'WhatsApp': '(11) 9999-0000',
    'Email': 'suporte@singleclin.com.br',
  };

  /// Quick search suggestions based on popular topics
  List<String> get quickSearchSuggestions => [
    'Como usar créditos SG',
    'Cancelar agendamento',
    'Alterar dados pessoais',
    'Problemas no app',
    'Política de reembolso',
    'Encontrar clínicas',
    'Avaliações e reviews',
    'Privacidade dos dados',
  ];

  /// Get current display items (search results or all items)
  List<FaqItem> get currentDisplayItems {
    if (searchResults.isNotEmpty) {
      return searchResults;
    }

    if (selectedCategory.value != null) {
      return getFaqByCategory(selectedCategory.value!);
    }

    return faqItems;
  }
}
