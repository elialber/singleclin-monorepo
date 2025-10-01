import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/features/engagement/controllers/faq_controller.dart';
import 'package:singleclin_mobile/features/engagement/widgets/faq_expandable_item.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FaqController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Perguntas Frequentes'),
            backgroundColor: const Color(0xFF005156),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.smart_toy),
                onPressed: () => _showChatbotDialog(context, controller),
                tooltip: 'Assistente Virtual',
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFF8F9FA),
                child: Column(
                  children: [
                    TextField(
                      controller: controller.searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar perguntas...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: controller.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: controller.clearSearch,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: controller.search,
                    ),
                    if (controller.searchSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: controller.searchSuggestions.take(3).map((
                          suggestion,
                        ) {
                          return ActionChip(
                            label: Text(suggestion),
                            onPressed: () =>
                                controller.selectSuggestion(suggestion),
                            backgroundColor: const Color(
                              0xFF005156,
                            ).withOpacity(0.1),
                            labelStyle: const TextStyle(
                              color: Color(0xFF005156),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Category filters
              if (controller.searchQuery.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Todas'),
                          selected: controller.selectedCategory == 'Todas',
                          onSelected: (_) =>
                              controller.filterByCategory('Todas'),
                          backgroundColor: Colors.grey[200],
                          selectedColor: const Color(0xFF005156),
                          labelStyle: TextStyle(
                            color: controller.selectedCategory == 'Todas'
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...controller.categories
                            .where((cat) => cat != 'Todas')
                            .map((category) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(category),
                                  selected:
                                      controller.selectedCategory == category,
                                  onSelected: (_) =>
                                      controller.filterByCategory(category),
                                  backgroundColor: Colors.grey[200],
                                  selectedColor: const Color(0xFF005156),
                                  labelStyle: TextStyle(
                                    color:
                                        controller.selectedCategory == category
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              );
                            }),
                      ],
                    ),
                  ),
                ),

              // FAQ List
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.filteredFaqs.isEmpty
                    ? _buildEmptyState(controller)
                    : RefreshIndicator(
                        onRefresh: controller.loadFaqs,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: controller.filteredFaqs.length,
                          itemBuilder: (context, index) {
                            final faq = controller.filteredFaqs[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: FaqExpandableItem(
                                faq: faq,
                                onExpanded: (expanded) {
                                  if (expanded) {
                                    controller.trackView(faq.id);
                                  }
                                },
                                onVote: (helpful) =>
                                    controller.voteFaq(faq.id, helpful),
                              ),
                            );
                          },
                        ),
                      ),
              ),

              // Popular questions banner
              if (controller.searchQuery.isEmpty &&
                  controller.popularFaqs.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF005156),
                        const Color(0xFF005156).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Perguntas Populares',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...controller.popularFaqs.take(3).map((faq) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: GestureDetector(
                            onTap: () => controller.selectPopularFaq(faq),
                            child: Text(
                              '• ${faq.question}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showChatbotDialog(context, controller),
            backgroundColor: const Color(0xFFFFB000),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.smart_toy),
            label: const Text('Assistente'),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(FaqController controller) {
    if (controller.searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma pergunta encontrada',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente buscar por "${controller.searchQuery}"',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showChatbotDialog(Get.context!, controller),
              icon: const Icon(Icons.smart_toy),
              label: const Text('Perguntar ao Assistente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005156),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma pergunta disponível',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }

  void _showChatbotDialog(BuildContext context, FaqController controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFB000),
                    child: Icon(Icons.smart_toy, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assistente Virtual',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Como posso ajudar você?',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: Get.back,
                  ),
                ],
              ),
              const Divider(),

              // Chat messages
              Expanded(
                child: ListView.builder(
                  itemCount: controller.chatbotMessages.length,
                  itemBuilder: (context, index) {
                    final message = controller.chatbotMessages[index];
                    final isUser = message['sender'] == 'user';

                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? const Color(0xFF005156)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          message['text'],
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Message input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.chatbotController,
                      decoration: const InputDecoration(
                        hintText: 'Digite sua pergunta...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (text) {
                        controller.sendToChatbot(text);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      controller.sendToChatbot(
                        controller.chatbotController.text,
                      );
                    },
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
}
