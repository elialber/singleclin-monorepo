import 'dart:io';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:singleclin_mobile/features/profile/models/medical_document.dart';

/// Documents Controller
/// Manages medical documents with secure file handling and LGPD compliance
class DocumentsController extends GetxController {
  // Observable state
  final _documents = <MedicalDocument>[].obs;
  final _isLoading = false.obs;
  final _isUploading = false.obs;
  final _isRefreshing = false.obs;
  final _errorMessage = ''.obs;
  final _selectedFilter = DocumentType.other.obs;
  final _searchQuery = ''.obs;
  final _uploadProgress = 0.0.obs;

  // Services
  final ImagePicker _imagePicker = ImagePicker();

  // Getters
  List<MedicalDocument> get documents => _documents;
  bool get isLoading => _isLoading.value;
  bool get isUploading => _isUploading.value;
  bool get isRefreshing => _isRefreshing.value;
  String get errorMessage => _errorMessage.value;
  DocumentType get selectedFilter => _selectedFilter.value;
  String get searchQuery => _searchQuery.value;
  double get uploadProgress => _uploadProgress.value;

  // Filtered documents
  List<MedicalDocument> get filteredDocuments {
    final filtered = _documents.where((doc) {
      // Filter by status
      if (!doc.isAvailable) return false;

      // Filter by type
      if (_selectedFilter.value != DocumentType.other) {
        if (doc.type != _selectedFilter.value) return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!doc.name.toLowerCase().contains(query) &&
            !(doc.description?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by upload date (newest first)
    filtered.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    return filtered;
  }

  // Documents grouped by type
  Map<DocumentType, List<MedicalDocument>> get documentsByType {
    final grouped = <DocumentType, List<MedicalDocument>>{};

    for (final doc in filteredDocuments) {
      grouped[doc.type] = (grouped[doc.type] ?? [])..add(doc);
    }

    return grouped;
  }

  @override
  void onInit() {
    super.onInit();
    loadDocuments();
  }

  /// Load documents from API
  Future<void> loadDocuments() async {
    try {
      _isLoading(true);
      _errorMessage('');

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 1500));

      // Load mock documents
      final mockDocuments = _generateMockDocuments();
      _documents.assignAll(mockDocuments);
    } catch (e) {
      _errorMessage('Erro ao carregar documentos: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível carregar os documentos',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }

  /// Refresh documents
  Future<void> refreshDocuments() async {
    try {
      _isRefreshing(true);
      await loadDocuments();
    } finally {
      _isRefreshing(false);
    }
  }

  /// Update filter
  void updateFilter(DocumentType filter) {
    _selectedFilter(filter);
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery(query);
  }

  /// Upload document from file picker
  Future<void> uploadDocumentFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false);

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      await _processFileUpload(file);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao selecionar arquivo: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Upload document from camera
  Future<void> uploadDocumentFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final platformFile = PlatformFile(
        name: '${DateTime.now().millisecondsSinceEpoch}.jpg',
        size: await file.length(),
        path: file.path,
      );

      await _processFileUpload(platformFile);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao capturar foto: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Upload document from gallery
  Future<void> uploadDocumentFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final platformFile = PlatformFile(
        name: pickedFile.name,
        size: await file.length(),
        path: file.path,
      );

      await _processFileUpload(platformFile);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao selecionar imagem: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Process file upload with encryption and metadata
  Future<void> _processFileUpload(PlatformFile file) async {
    if (file.path == null) return;

    try {
      _isUploading(true);
      _uploadProgress(0.0);

      // Show document type selection dialog
      final documentType = await _showDocumentTypeDialog();
      if (documentType == null) return;

      final description = await _showDescriptionDialog();

      // Simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        _uploadProgress(i / 100);
      }

      // Create document record
      final document = MedicalDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'user123',
        name: _generateDocumentName(documentType, file.name),
        originalName: file.name,
        type: documentType,
        mimeType: _getMimeType(file.name),
        fileSize: file.size,
        fileUrl:
            'https://secure.singleclin.com/docs/${DateTime.now().millisecondsSinceEpoch}',
        localPath: file.path,
        description: description.isNotEmpty ? description : null,
        encryptionKey: _generateEncryptionKey(),
        uploadedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _documents.insert(0, document);

      Get.snackbar(
        'Sucesso',
        'Documento enviado com segurança',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao enviar documento: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isUploading(false);
      _uploadProgress(0.0);
    }
  }

  /// View document
  Future<void> viewDocument(String documentId) async {
    try {
      final document = _documents.firstWhere((d) => d.id == documentId);

      if (!document.isAvailable) {
        Get.snackbar(
          'Indisponível',
          'Este documento não está disponível',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Navigate to document viewer
      Get.toNamed('/documents/view', arguments: document);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Documento não encontrado',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Download document
  Future<void> downloadDocument(String documentId) async {
    try {
      final document = _documents.firstWhere((d) => d.id == documentId);

      _isLoading(true);

      // Simulate download with decryption
      await Future.delayed(const Duration(milliseconds: 2000));

      Get.snackbar(
        'Download Concluído',
        '${document.name} salvo na galeria',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao baixar documento: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }

  /// Share document
  Future<void> shareDocument(String documentId) async {
    try {
      final document = _documents.firstWhere((d) => d.id == documentId);

      // Show sharing options
      final shareWith = await _showShareDialog();
      if (shareWith == null) return;

      // Create share permission
      final permission = DocumentSharePermission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        documentId: documentId,
        sharedWithId: shareWith['id'],
        sharedWithType: shareWith['type'],
        sharedWithName: shareWith['name'],
        permissions: DocumentPermission.standardPermissions,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );

      // Update document
      final index = _documents.indexWhere((d) => d.id == documentId);
      _documents[index] = document.copyWith(
        isShared: true,
        sharedWith: [...document.sharedWith, shareWith['id']],
        updatedAt: DateTime.now(),
      );

      Get.snackbar(
        'Sucesso',
        'Documento compartilhado com ${shareWith['name']}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao compartilhar documento: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Delete document (LGPD compliant)
  Future<void> deleteDocument(String documentId) async {
    final confirmed =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Excluir Documento'),
            content: const Text(
              'Tem certeza que deseja excluir este documento?\n\n'
              'Esta ação é irreversível e o arquivo será permanentemente removido de nossos servidores.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      _isLoading(true);

      // Simulate secure deletion
      await Future.delayed(const Duration(milliseconds: 1500));

      _documents.removeWhere((d) => d.id == documentId);

      Get.snackbar(
        'Sucesso',
        'Documento excluído com segurança',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao excluir documento: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }

  /// Show document type selection dialog
  Future<DocumentType?> _showDocumentTypeDialog() async {
    return Get.dialog<DocumentType>(
      AlertDialog(
        title: const Text('Tipo de Documento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: DocumentType.values
                .map(
                  (type) => ListTile(
                    leading: Icon(
                      _getIconData(type.icon),
                      color: Color(
                        int.parse(type.color.substring(1), radix: 16) +
                            0xFF000000,
                      ),
                    ),
                    title: Text(type.label),
                    onTap: () => Get.back(result: type),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  /// Show description input dialog
  Future<String> _showDescriptionDialog() async {
    final controller = TextEditingController();

    final result = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Descrição (Opcional)'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Digite uma descrição para o documento...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: ''),
            child: const Text('Pular'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    return result ?? '';
  }

  /// Show share dialog
  Future<Map<String, String>?> _showShareDialog() async {
    final options = [
      {'id': 'clinic1', 'type': 'clinic', 'name': 'Clínica Bella Vita'},
      {'id': 'doctor1', 'type': 'professional', 'name': 'Dr. Carlos Silva'},
      {'id': 'lab1', 'type': 'clinic', 'name': 'Laboratório Saúde+'},
    ];

    return Get.dialog<Map<String, String>>(
      AlertDialog(
        title: const Text('Compartilhar Com'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map(
                  (option) => ListTile(
                    leading: Icon(
                      option['type'] == 'clinic'
                          ? Icons.local_hospital
                          : Icons.person,
                    ),
                    title: Text(option['name']!),
                    subtitle: Text(
                      option['type'] == 'clinic' ? 'Clínica' : 'Profissional',
                    ),
                    onTap: () => Get.back(result: option),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  /// Get statistics
  Map<String, dynamic> get statistics {
    final totalDocs = _documents.length;
    final docsByType = <String, int>{};
    final recentDocs = _documents
        .where(
          (d) => d.uploadedAt.isAfter(
            DateTime.now().subtract(const Duration(days: 30)),
          ),
        )
        .length;

    for (final doc in _documents) {
      docsByType[doc.type.label] = (docsByType[doc.type.label] ?? 0) + 1;
    }

    final totalSize = _documents.fold<int>(0, (sum, doc) => sum + doc.fileSize);
    final sharedDocs = _documents.where((d) => d.isShared).length;

    return {
      'totalDocuments': totalDocs,
      'recentDocuments': recentDocs,
      'documentsByType': docsByType,
      'totalSize': totalSize,
      'sharedDocuments': sharedDocs,
    };
  }

  /// Helper methods
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  String _generateDocumentName(DocumentType type, String originalName) {
    final timestamp = DateTime.now();
    final dateStr =
        '${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year}';
    return '${type.label} - $dateStr';
  }

  String _generateEncryptionKey() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'biotech':
        return Icons.biotech;
      case 'medication':
        return Icons.medication;
      case 'description':
        return Icons.description;
      case 'medical_services':
        return Icons.medical_services;
      case 'camera_alt':
        return Icons.camera_alt;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Generate mock documents
  List<MedicalDocument> _generateMockDocuments() {
    final now = DateTime.now();

    return [
      MedicalDocument(
        id: '1',
        userId: 'user123',
        name: 'Resultado de Exame - Hemograma',
        originalName: 'hemograma_janeiro_2024.pdf',
        type: DocumentType.examResult,
        mimeType: 'application/pdf',
        fileSize: 245760,
        fileUrl: 'https://secure.singleclin.com/docs/1',
        description: 'Exame de sangue completo realizado em janeiro',
        uploadedAt: now.subtract(const Duration(days: 30)),
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),

      MedicalDocument(
        id: '2',
        userId: 'user123',
        name: 'Receita Médica - Vitaminas',
        originalName: 'receita_vitaminas.jpg',
        type: DocumentType.prescription,
        mimeType: 'image/jpeg',
        fileSize: 1024000,
        fileUrl: 'https://secure.singleclin.com/docs/2',
        description: 'Prescrição de suplementos vitamínicos',
        uploadedAt: now.subtract(const Duration(days: 15)),
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),

      MedicalDocument(
        id: '3',
        userId: 'user123',
        name: 'Foto Antes - Limpeza Facial',
        originalName: 'before_facial_cleaning.jpg',
        type: DocumentType.beforePhoto,
        mimeType: 'image/jpeg',
        fileSize: 2048000,
        fileUrl: 'https://secure.singleclin.com/docs/3',
        associatedAppointmentId: 'appt1',
        description: 'Foto do rosto antes do procedimento de limpeza',
        uploadedAt: now.subtract(const Duration(days: 16)),
        createdAt: now.subtract(const Duration(days: 16)),
        updatedAt: now.subtract(const Duration(days: 16)),
      ),

      MedicalDocument(
        id: '4',
        userId: 'user123',
        name: 'Cartão de Vacinação',
        originalName: 'cartao_vacina.pdf',
        type: DocumentType.vaccinationCard,
        mimeType: 'application/pdf',
        fileSize: 512000,
        fileUrl: 'https://secure.singleclin.com/docs/4',
        description: 'Cartão de vacinação atualizado',
        isShared: true,
        sharedWith: const ['clinic1'],
        uploadedAt: now.subtract(const Duration(days: 90)),
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }
}
