import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:singleclin_mobile/features/engagement/models/support_ticket.dart';
import 'package:singleclin_mobile/core/services/api_service.dart';

/// Controller for customer support system
class SupportController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final messageController = TextEditingController();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isSendingMessage = false.obs;
  final RxString error = ''.obs;

  final RxList<SupportTicket> tickets = <SupportTicket>[].obs;
  final Rx<SupportTicket?> selectedTicket = Rx<SupportTicket?>(null);
  final RxList<File> attachments = <File>[].obs;

  // Chat functionality
  final Rx<ChatSession?> currentChatSession = Rx<ChatSession?>(null);
  final RxBool isChatLoading = false.obs;
  final RxBool isChatConnected = false.obs;

  // Ticket creation
  final Rx<TicketCategory> selectedCategory = TicketCategory.general.obs;
  final Rx<TicketPriority> selectedPriority = TicketPriority.medium.obs;

  @override
  void onInit() {
    super.onInit();
    loadTickets();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    messageController.dispose();
    super.onClose();
  }

  /// Load user support tickets
  Future<void> loadTickets({bool refresh = false}) async {
    try {
      refresh ? isLoading.value = true : null;
      error.value = '';

      final response = await _apiService.get('/user/support/tickets');

      final List<SupportTicket> loadedTickets =
          (response.data['tickets'] as List)
              .map((json) => SupportTicket.fromJson(json))
              .toList();

      tickets.assignAll(loadedTickets);
    } catch (e) {
      error.value = 'Erro ao carregar tickets: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// Create new support ticket
  Future<void> createTicket() async {
    if (!validateTicketForm()) return;

    try {
      isSubmitting.value = true;
      error.value = '';

      // Upload attachments if any
      final List<String> attachmentUrls = await uploadAttachments();

      final ticketData = {
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'category': selectedCategory.value.name,
        'priority': selectedPriority.value.name,
        'attachments': attachmentUrls,
      };

      final response = await _apiService.post(
        '/user/support/tickets',
        data: ticketData,
      );

      final newTicket = SupportTicket.fromJson(response.data['ticket']);
      tickets.insert(0, newTicket);

      // Clear form
      clearTicketForm();

      Get.snackbar(
        'Ticket criado!',
        'Seu ticket foi criado com sucesso. Em breve entraremos em contato.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.back();
    } catch (e) {
      error.value = 'Erro ao criar ticket: ${e.toString()}';
      Get.snackbar(
        'Erro',
        error.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Send message to existing ticket
  Future<void> sendMessage(String ticketId) async {
    if (messageController.text.trim().isEmpty) return;

    try {
      isSendingMessage.value = true;

      // Upload attachments if any
      final List<String> attachmentUrls = await uploadAttachments();

      final messageData = {
        'message': messageController.text.trim(),
        'attachments': attachmentUrls,
      };

      final response = await _apiService.post(
        '/user/support/tickets/$ticketId/messages',
        data: messageData,
      );

      final newMessage = TicketMessage.fromJson(response.data['message']);

      // Update ticket with new message
      final ticketIndex = tickets.indexWhere((t) => t.id == ticketId);
      if (ticketIndex != -1) {
        final updatedTicket = tickets[ticketIndex].copyWith(
          messages: [...tickets[ticketIndex].messages, newMessage],
          updatedAt: DateTime.now(),
        );
        tickets[ticketIndex] = updatedTicket;

        if (selectedTicket.value?.id == ticketId) {
          selectedTicket.value = updatedTicket;
        }
      }

      messageController.clear();
      attachments.clear();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível enviar a mensagem',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Start live chat session
  Future<void> startChatSession() async {
    try {
      isChatLoading.value = true;

      final response = await _apiService.post(
        '/user/support/chat/start',
        data: {'topic': 'Suporte Geral'},
      );

      final chatSession = ChatSession.fromJson(response.data['session']);
      currentChatSession.value = chatSession;
      isChatConnected.value = true;

      // Connect to WebSocket for real-time chat
      _connectToChatWebSocket(chatSession.id);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível iniciar o chat',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isChatLoading.value = false;
    }
  }

  /// Send chat message
  Future<void> sendChatMessage(String message) async {
    if (currentChatSession.value == null || message.trim().isEmpty) return;

    try {
      final response = await _apiService.post(
        '/user/support/chat/${currentChatSession.value!.id}/message',
        data: {'message': message.trim()},
      );

      final chatMessage = ChatMessage.fromJson(response.data['message']);

      // Update current session with new message
      final updatedSession = currentChatSession.value!.copyWith(
        messages: [...currentChatSession.value!.messages, chatMessage],
      );
      currentChatSession.value = updatedSession;
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível enviar a mensagem',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// End chat session
  Future<void> endChatSession() async {
    if (currentChatSession.value == null) return;

    try {
      await _apiService.post(
        '/user/support/chat/${currentChatSession.value!.id}/end',
      );

      currentChatSession.value = null;
      isChatConnected.value = false;
    } catch (e) {
      print('Error ending chat session: $e');
    }
  }

  /// Rate support experience
  Future<void> rateSupportExperience(
    String ticketId,
    double rating,
    String? comment,
  ) async {
    try {
      await _apiService.post(
        '/user/support/tickets/$ticketId/rate',
        data: {'rating': rating, 'comment': comment},
      );

      // Update ticket with rating
      final ticketIndex = tickets.indexWhere((t) => t.id == ticketId);
      if (ticketIndex != -1) {
        final updatedTicket = tickets[ticketIndex].copyWith(
          satisfactionRating: rating,
          satisfactionComment: comment,
        );
        tickets[ticketIndex] = updatedTicket;
      }

      Get.snackbar(
        'Obrigado!',
        'Sua avaliação foi registrada',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível enviar a avaliação',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Add attachment
  Future<void> addAttachment() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        attachments.add(File(image.path));
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível adicionar o anexo',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Remove attachment
  void removeAttachment(int index) {
    if (index < attachments.length) {
      attachments.removeAt(index);
    }
  }

  /// Upload attachments
  Future<List<String>> uploadAttachments() async {
    if (attachments.isEmpty) return [];

    try {
      final List<String> uploadedUrls = [];

      for (final attachment in attachments) {
        final response = await _apiService.uploadFile(
          '/upload/support-attachment',
          attachment,
          fileField: 'attachment',
        );

        uploadedUrls.add(response.data['url']);
      }

      attachments.clear();
      return uploadedUrls;
    } catch (e) {
      throw Exception('Erro ao fazer upload dos anexos: $e');
    }
  }

  /// Select ticket for detailed view
  void selectTicket(SupportTicket ticket) {
    selectedTicket.value = ticket;
    markTicketAsRead(ticket.id);
  }

  /// Mark ticket messages as read
  Future<void> markTicketAsRead(String ticketId) async {
    try {
      await _apiService.post('/user/support/tickets/$ticketId/mark-read');
    } catch (e) {
      print('Error marking ticket as read: $e');
    }
  }

  /// Close ticket
  Future<void> closeTicket(String ticketId) async {
    try {
      await _apiService.post('/user/support/tickets/$ticketId/close');

      final ticketIndex = tickets.indexWhere((t) => t.id == ticketId);
      if (ticketIndex != -1) {
        final updatedTicket = tickets[ticketIndex].copyWith(
          status: TicketStatus.closed,
        );
        tickets[ticketIndex] = updatedTicket;
      }

      Get.snackbar(
        'Ticket fechado',
        'O ticket foi fechado com sucesso',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível fechar o ticket',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Validate ticket form
  bool validateTicketForm() {
    if (titleController.text.trim().isEmpty) {
      error.value = 'Por favor, adicione um título';
      return false;
    }

    if (descriptionController.text.trim().length < 10) {
      error.value = 'A descrição deve ter pelo menos 10 caracteres';
      return false;
    }

    return true;
  }

  /// Clear ticket form
  void clearTicketForm() {
    titleController.clear();
    descriptionController.clear();
    attachments.clear();
    selectedCategory.value = TicketCategory.general;
    selectedPriority.value = TicketPriority.medium;
  }

  /// Connect to chat WebSocket
  void _connectToChatWebSocket(String sessionId) {
    // Implementation would depend on WebSocket package
    // This is a placeholder for real-time chat functionality
    print('Connecting to chat WebSocket for session: $sessionId');
  }

  /// Get category display name
  String getCategoryDisplayName(TicketCategory category) {
    switch (category) {
      case TicketCategory.general:
        return 'Geral';
      case TicketCategory.technical:
        return 'Técnico';
      case TicketCategory.billing:
        return 'Cobrança';
      case TicketCategory.appointment:
        return 'Agendamento';
      case TicketCategory.credits:
        return 'Créditos SG';
      case TicketCategory.account:
        return 'Conta';
      case TicketCategory.clinic:
        return 'Clínica';
      case TicketCategory.emergency:
        return 'Emergência';
    }
  }

  /// Get priority display name
  String getPriorityDisplayName(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return 'Baixa';
      case TicketPriority.medium:
        return 'Média';
      case TicketPriority.high:
        return 'Alta';
      case TicketPriority.urgent:
        return 'Urgente';
    }
  }

  /// Get status display name
  String getStatusDisplayName(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return 'Aberto';
      case TicketStatus.inProgress:
        return 'Em Andamento';
      case TicketStatus.waitingForCustomer:
        return 'Aguardando Resposta';
      case TicketStatus.resolved:
        return 'Resolvido';
      case TicketStatus.closed:
        return 'Fechado';
      case TicketStatus.escalated:
        return 'Escalado';
    }
  }

  /// Get available categories
  List<TicketCategory> get availableCategories => TicketCategory.values;

  /// Get available priorities
  List<TicketPriority> get availablePriorities => TicketPriority.values;

  /// Check if live chat is available
  bool get isChatAvailable {
    // This would check business hours, agent availability, etc.
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 8 && hour <= 20; // Available 8AM to 8PM
  }

  /// Get estimated wait time for chat
  String get estimatedChatWaitTime {
    if (!isChatAvailable) return 'Indisponível';

    // This would be calculated based on current queue
    return '< 5 minutos';
  }
}
