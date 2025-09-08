import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/feedback_controller.dart';
import '../widgets/feedback_form.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FeedbackController>(
      builder: (controller) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Feedback'),
              backgroundColor: const Color(0xFF005156),
              foregroundColor: Colors.white,
              bottom: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Color(0xFFFFB000),
                tabs: [
                  Tab(icon: Icon(Icons.feedback), text: 'Sugestões'),
                  Tab(icon: Icon(Icons.bug_report), text: 'Problemas'),
                  Tab(icon: Icon(Icons.route), text: 'Roadmap'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildSuggestionsTab(controller),
                _buildBugReportsTab(controller),
                _buildRoadmapTab(controller),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showFeedbackForm(context, controller),
              backgroundColor: const Color(0xFFFFB000),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nova Sugestão'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsTab(FeedbackController controller) {
    return Column(
      children: [
        // Filter and sort options
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFF8F9FA),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Todas'),
                        selected: controller.selectedFilter == 'all',
                        onSelected: (_) => controller.filterSuggestions('all'),
                        backgroundColor: Colors.grey[200],
                        selectedColor: const Color(0xFF005156),
                        labelStyle: TextStyle(
                          color: controller.selectedFilter == 'all' 
                              ? Colors.white 
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Populares'),
                        selected: controller.selectedFilter == 'popular',
                        onSelected: (_) => controller.filterSuggestions('popular'),
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
                        label: const Text('Em Análise'),
                        selected: controller.selectedFilter == 'reviewing',
                        onSelected: (_) => controller.filterSuggestions('reviewing'),
                        backgroundColor: Colors.grey[200],
                        selectedColor: const Color(0xFF005156),
                        labelStyle: TextStyle(
                          color: controller.selectedFilter == 'reviewing' 
                              ? Colors.white 
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Implementadas'),
                        selected: controller.selectedFilter == 'implemented',
                        onSelected: (_) => controller.filterSuggestions('implemented'),
                        backgroundColor: Colors.grey[200],
                        selectedColor: const Color(0xFF005156),
                        labelStyle: TextStyle(
                          color: controller.selectedFilter == 'implemented' 
                              ? Colors.white 
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  controller.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: const Color(0xFF005156),
                ),
                onPressed: controller.toggleSort,
              ),
            ],
          ),
        ),

        // Suggestions list
        Expanded(
          child: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : controller.filteredSuggestions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Nenhuma sugestão encontrada',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Compartilhe suas ideias para melhorar o app!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: controller.loadSuggestions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.filteredSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = controller.filteredSuggestions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          suggestion.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(suggestion.status),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getStatusText(suggestion.status),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    suggestion.description,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(suggestion.category),
                                        backgroundColor: const Color(0xFF005156).withOpacity(0.1),
                                        labelStyle: const TextStyle(
                                          color: Color(0xFF005156),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              suggestion.userVote == 1 
                                                  ? Icons.thumb_up 
                                                  : Icons.thumb_up_outlined,
                                              color: suggestion.userVote == 1 
                                                  ? const Color(0xFF005156) 
                                                  : Colors.grey,
                                              size: 18,
                                            ),
                                            onPressed: () => controller.voteSuggestion(
                                              suggestion.id, 
                                              suggestion.userVote == 1 ? 0 : 1,
                                            ),
                                          ),
                                          Text(
                                            '${suggestion.upvotes}',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(
                                              suggestion.userVote == -1 
                                                  ? Icons.thumb_down 
                                                  : Icons.thumb_down_outlined,
                                              color: suggestion.userVote == -1 
                                                  ? Colors.red 
                                                  : Colors.grey,
                                              size: 18,
                                            ),
                                            onPressed: () => controller.voteSuggestion(
                                              suggestion.id, 
                                              suggestion.userVote == -1 ? 0 : -1,
                                            ),
                                          ),
                                          Text(
                                            '${suggestion.downvotes}',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (suggestion.adminResponse != null) ...[
                                    const Divider(),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.admin_panel_settings, 
                                                   size: 16, color: Colors.blue),
                                              SizedBox(width: 4),
                                              Text(
                                                'Resposta da Equipe',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            suggestion.adminResponse!,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enviado em ${_formatDate(suggestion.createdAt)}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildBugReportsTab(FeedbackController controller) {
    return Column(
      children: [
        // Bug reports header
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFF8F9FA),
          child: Row(
            children: [
              const Icon(Icons.bug_report, color: Color(0xFF005156)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Relate problemas técnicos ou bugs encontrados no app',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showBugReportForm(context, controller),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Reportar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),

        // Bug reports list
        Expanded(
          child: controller.bugReports.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bug_report, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum problema reportado',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ótimo! O app está funcionando bem para você',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.bugReports.length,
                  itemBuilder: (context, index) {
                    final bug = controller.bugReports[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getBugPriorityColor(bug.priority),
                          child: Icon(
                            Icons.bug_report,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          bug.title,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bug.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(bug.status),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getStatusText(bug.status),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Prioridade: ${bug.priority}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Text(
                          _formatDate(bug.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => _showBugDetails(bug, controller),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRoadmapTab(FeedbackController controller) {
    return RefreshIndicator(
      onRefresh: controller.loadRoadmap,
      child: controller.roadmapItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Roadmap em breve',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Estamos preparando nossos próximos passos',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.roadmapItems.length,
              itemBuilder: (context, index) {
                final item = controller.roadmapItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoadmapStatusColor(item.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        if (item.estimatedDate != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Previsão: ${_formatDate(item.estimatedDate!)}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (item.progress > 0) ...[
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Progresso',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '${(item.progress * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF005156),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: item.progress,
                                backgroundColor: Colors.grey[300],
                                color: const Color(0xFF005156),
                              ),
                            ],
                          ),
                        ],
                        if (item.votes > 0) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.how_to_vote, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '${item.votes} votos da comunidade',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showFeedbackForm(BuildContext context, FeedbackController controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: FeedbackForm(
            onSubmit: (feedback) {
              controller.submitFeedback(feedback);
              Get.back();
            },
          ),
        ),
      ),
    );
  }

  void _showBugReportForm(BuildContext context, FeedbackController controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: FeedbackForm(
            feedbackType: 'bug',
            onSubmit: (feedback) {
              controller.submitBugReport(feedback);
              Get.back();
            },
          ),
        ),
      ),
    );
  }

  void _showBugDetails(dynamic bug, FeedbackController controller) {
    Get.dialog(
      AlertDialog(
        title: Text(bug.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(bug.description),
            const SizedBox(height: 12),
            Text('Prioridade: ${bug.priority}'),
            Text('Status: ${_getStatusText(bug.status)}'),
            Text('Reportado em: ${_formatDate(bug.createdAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'reviewing':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'implemented':
        return const Color(0xFF005156);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDENTE';
      case 'reviewing':
        return 'ANALISANDO';
      case 'approved':
        return 'APROVADA';
      case 'rejected':
        return 'REJEITADA';
      case 'implemented':
        return 'IMPLEMENTADA';
      default:
        return 'DESCONHECIDO';
    }
  }

  Color _getBugPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  Color _getRoadmapStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'planned':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}