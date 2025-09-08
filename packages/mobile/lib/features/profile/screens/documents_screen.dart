import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/documents_controller.dart';
import '../widgets/document_viewer.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../core/constants/app_colors.dart';

/// Documents Screen
/// Secure document management with upload and LGPD compliance
class DocumentsScreen extends GetView<DocumentsController> {
  const DocumentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Meus Documentos',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'statistics',
                child: Row(
                  children: [
                    Icon(Icons.analytics, size: 20),
                    SizedBox(width: 12),
                    Text('Estatísticas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Ajuda'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsHeader(),
          _buildFilterTabs(),
          Expanded(
            child: _buildDocumentsList(),
          ),
        ],
      ),
      floatingActionButton: _buildUploadFAB(),
    );
  }

  /// Build statistics header
  Widget _buildStatsHeader() {
    return Obx(() {
      if (controller.isLoading) return const SizedBox.shrink();
      
      final stats = controller.statistics;
      
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(
              color: AppColors.divider,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildStatItem(
              'Total',
              stats['totalDocuments'].toString(),
              AppColors.primary,
              Icons.folder,
            ),
            _buildStatItem(
              'Recentes',
              stats['recentDocuments'].toString(),
              AppColors.success,
              Icons.schedule,
            ),
            _buildStatItem(
              'Compartilhados',
              stats['sharedDocuments'].toString(),
              AppColors.info,
              Icons.share,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build filter tabs
  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
          children: [
            _buildFilterChip('Todos', DocumentType.other),
            const SizedBox(width: 8),
            ...DocumentType.values.where((type) => type != DocumentType.other).map(
              (type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(type.label, type),
              ),
            ),
          ],
        )),
      ),
    );
  }

  Widget _buildFilterChip(String label, DocumentType type) {
    final isSelected = controller.selectedFilter == type;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        controller.updateFilter(type);
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  /// Build documents list
  Widget _buildDocumentsList() {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final documents = controller.filteredDocuments;
      
      if (documents.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: controller.refreshDocuments,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DocumentViewer(
                document: documents[index],
                onTap: () => controller.viewDocument(documents[index].id),
                onDownload: () => controller.downloadDocument(documents[index].id),
                onShare: () => controller.shareDocument(documents[index].id),
                onDelete: () => controller.deleteDocument(documents[index].id),
              ),
            );
          },
        ),
      );
    });
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_outlined,
                size: 48,
                color: AppColors.mediumGrey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum documento encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Seus documentos médicos aparecerão aqui. Mantenha tudo organizado e seguro.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showUploadOptions,
              icon: const Icon(Icons.upload),
              label: const Text('Adicionar Documento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build upload FAB
  Widget _buildUploadFAB() {
    return Obx(() {
      if (controller.isUploading) {
        return FloatingActionButton(
          onPressed: null,
          backgroundColor: AppColors.primary.withOpacity(0.7),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: controller.uploadProgress,
                strokeWidth: 3,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
              Text(
                '${(controller.uploadProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }

      return FloatingActionButton(
        onPressed: _showUploadOptions,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      );
    });
  }

  /// Show upload options
  void _showUploadOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adicionar Documento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildUploadOption(
              icon: Icons.camera_alt,
              title: 'Câmera',
              subtitle: 'Fotografar documento',
              onTap: () {
                Get.back();
                controller.uploadDocumentFromCamera();
              },
            ),
            _buildUploadOption(
              icon: Icons.photo_library,
              title: 'Galeria',
              subtitle: 'Selecionar da galeria',
              onTap: () {
                Get.back();
                controller.uploadDocumentFromGallery();
              },
            ),
            _buildUploadOption(
              icon: Icons.folder,
              title: 'Arquivos',
              subtitle: 'Selecionar arquivo (PDF, DOC, etc.)',
              onTap: () {
                Get.back();
                controller.uploadDocumentFromFile();
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.security,
                    color: AppColors.info,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Todos os documentos são criptografados e armazenados com segurança.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// Handle menu actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'statistics':
        _showStatisticsDialog();
        break;
      case 'help':
        _showHelpDialog();
        break;
    }
  }

  /// Show search dialog
  void _showSearchDialog() {
    final searchController = TextEditingController(text: controller.searchQuery);
    
    Get.dialog(
      AlertDialog(
        title: const Text('Pesquisar Documentos'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Digite o nome do documento...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: controller.updateSearchQuery,
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.updateSearchQuery('');
              Get.back();
            },
            child: const Text('Limpar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show statistics dialog
  void _showStatisticsDialog() {
    final stats = controller.statistics;
    
    Get.dialog(
      AlertDialog(
        title: const Text('Estatísticas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total de documentos', stats['totalDocuments'].toString()),
            _buildStatRow('Documentos recentes', stats['recentDocuments'].toString()),
            _buildStatRow('Documentos compartilhados', stats['sharedDocuments'].toString()),
            _buildStatRow('Espaço utilizado', _formatBytes(stats['totalSize'])),
            const SizedBox(height: 16),
            const Text(
              'Tipos de documento:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...stats['documentsByType'].entries.map((entry) => 
              _buildStatRow('  ${entry.key}', entry.value.toString())
            ),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Show help dialog
  void _showHelpDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Ajuda - Documentos'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Como usar seus documentos:'),
              SizedBox(height: 12),
              Text('📁 Upload: Adicione documentos usando câmera, galeria ou arquivos'),
              SizedBox(height: 8),
              Text('🔒 Segurança: Todos os arquivos são criptografados'),
              SizedBox(height: 8),
              Text('📤 Compartilhar: Compartilhe com clínicas de forma segura'),
              SizedBox(height: 8),
              Text('🗂️ Organização: Use filtros para encontrar documentos'),
              SizedBox(height: 8),
              Text('📱 Acesso: Visualize e baixe quando necessário'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  /// Format bytes to human readable
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}