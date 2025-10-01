import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:singleclin_mobile/features/engagement/controllers/support_controller.dart';
import 'package:singleclin_mobile/features/engagement/widgets/support_chat_bubble.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SupportController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Suporte'),
            backgroundColor: const Color(0xFF005156),
            foregroundColor: Colors.white,
            actions: [
              if (controller.activeTickets.isNotEmpty)
                IconButton(
                  icon: Badge(
                    label: Text('${controller.activeTickets.length}'),
                    child: const Icon(Icons.support_agent),
                  ),
                  onPressed: () => _showTicketsBottomSheet(context, controller),
                ),
            ],
          ),
          body: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFF8F9FA),
                  child: const TabBar(
                    labelColor: Color(0xFF005156),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF005156),
                    tabs: [
                      Tab(icon: Icon(Icons.chat), text: 'Chat'),
                      Tab(
                        icon: Icon(Icons.confirmation_number),
                        text: 'Tickets',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildChatTab(controller),
                      _buildTicketsTab(controller),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatTab(SupportController controller) {
    return Column(
      children: [
        // Quick help buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Como podemos ajudar?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF005156),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.quickHelpOptions.map((option) {
                  return ActionChip(
                    label: Text(option),
                    onPressed: () => controller.sendQuickHelp(option),
                    backgroundColor: const Color(0xFF005156).withOpacity(0.1),
                    labelStyle: const TextStyle(color: Color(0xFF005156)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Chat messages
        Expanded(
          child: controller.chatMessages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.support_agent, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nosso suporte está aqui para ajudar!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005156),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Envie uma mensagem ou escolha uma opção acima',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = controller.chatMessages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SupportChatBubble(
                        message: message,
                        onFileDownload: controller.downloadFile,
                      ),
                    );
                  },
                ),
        ),

        // Typing indicator
        if (controller.isAgentTyping)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Suporte digitando...'),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Message input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                offset: const Offset(0, -1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: controller.attachFile,
                color: const Color(0xFF005156),
              ),
              Expanded(
                child: TextField(
                  controller: controller.messageController,
                  decoration: const InputDecoration(
                    hintText: 'Digite sua mensagem...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => controller.sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: controller.canSendMessage
                    ? controller.sendMessage
                    : null,
                color: const Color(0xFF005156),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicketsTab(SupportController controller) {
    return Column(
      children: [
        // Create ticket button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateTicketDialog(controller),
              icon: const Icon(Icons.add),
              label: const Text('Criar Novo Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005156),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // Tickets list
        Expanded(
          child: controller.tickets.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.confirmation_number,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum ticket encontrado',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Crie um ticket para questões específicas',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: controller.loadTickets,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = controller.tickets[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(ticket.status),
                            child: Icon(
                              _getStatusIcon(ticket.status),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            ticket.title,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Categoria: ${ticket.category}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Criado em: ${_formatDate(ticket.createdAt)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(ticket.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(ticket.status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              if (ticket.priority == 'high')
                                const Icon(
                                  Icons.priority_high,
                                  color: Colors.red,
                                  size: 16,
                                ),
                            ],
                          ),
                          onTap: () =>
                              Get.toNamed('/support/ticket/${ticket.id}'),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showTicketsBottomSheet(
    BuildContext context,
    SupportController controller,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tickets Ativos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...controller.activeTickets.map((ticket) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF005156),
                  child: Text(
                    ticket.id.substring(0, 2).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(ticket.title),
                subtitle: Text(ticket.category),
                onTap: () {
                  Get.back();
                  Get.toNamed('/support/ticket/${ticket.id}');
                },
              );
            }),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showCreateTicketDialog(SupportController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Criar Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller.ticketTitleController,
              decoration: const InputDecoration(
                labelText: 'Título do Ticket',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: controller.selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              items: controller.ticketCategories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: controller.setSelectedCategory,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.ticketDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              controller.createTicket();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005156),
            ),
            child: const Text('Criar Ticket'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Icons.fiber_new;
      case 'in_progress':
        return Icons.hourglass_empty;
      case 'resolved':
        return Icons.check_circle;
      case 'closed':
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'ABERTO';
      case 'in_progress':
        return 'EM ANDAMENTO';
      case 'resolved':
        return 'RESOLVIDO';
      case 'closed':
        return 'FECHADO';
      default:
        return 'DESCONHECIDO';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
