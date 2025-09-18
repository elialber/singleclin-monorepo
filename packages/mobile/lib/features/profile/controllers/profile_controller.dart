import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../../../presentation/controllers/base_controller.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';

/// Profile Controller with offline-first capabilities
/// Manages user profile data, editing, and LGPD compliance features
class ProfileController extends BaseController {
  // Observable state (specialized for profile)
  final _profile = Rx<UserProfile?>(null);
  final _isSaving = false.obs;
  final _isUpdatingPhoto = false.obs;
  final _isEditing = false.obs;
  final _hasUnsavedChanges = false.obs;
  
  // Form controllers
  final _tempProfile = Rx<UserProfile?>(null);

  // Services
  final ImagePicker _imagePicker = ImagePicker();
  late final UserRepository _userRepository;

  // Getters
  UserProfile? get profile => _profile.value;
  bool get isSaving => _isSaving.value;
  bool get isUpdatingPhoto => _isUpdatingPhoto.value;
  bool get isEditing => _isEditing.value;
  bool get hasUnsavedChanges => _hasUnsavedChanges.value;
  UserProfile? get tempProfile => _tempProfile.value;
  
  @override
  void onInit() {
    super.onInit();
    _userRepository = Get.find<UserRepository>();
    loadProfile();
  }

  @override
  void _loadOfflineState() {
    super._loadOfflineState();
    // Check if we have cached profile data
    _checkCachedProfile();
  }

  Future<void> _checkCachedProfile() async {
    try {
      // Check if current user profile exists in cache
      final currentUserId = 'current_user'; // Get from auth service
      final cachedProfile = await _userRepository.getCurrentUser(offlineOnly: true);

      if (cachedProfile != null) {
        setCachedData(true);
        updateLastSyncTime(_userRepository.lastSyncTime);
      } else {
        setCachedData(false);
      }
    } catch (e) {
      print('⚠️ Error checking cached profile: $e');
      setCachedData(false);
    }
  }
  
  /// Load user profile with offline-first support
  Future<void> loadProfile({bool forceRefresh = false}) async {
    final result = await executeOfflineFirst<UserModel>(
      // Network operation
      () async {
        return await _userRepository.getCurrentUser(forceRefresh: true);
      },
      // Cache operation
      () async {
        return await _userRepository.getCurrentUser(offlineOnly: true);
      },
      forceRefresh: forceRefresh,
      onSuccess: (userModel) {
        if (userModel != null) {
          // Convert UserModel to UserProfile (if they're different types)
          _profile.value = _convertToUserProfile(userModel);
        }
      },
      onOfflineMode: () {
        showInfoSnackbar('Exibindo perfil em cache');
      },
    );

    // Update profile if we got a result
    if (result != null) {
      _profile.value = _convertToUserProfile(result);
    }
  }

  /// Convert UserModel to UserProfile (adapt as needed based on your models)
  UserProfile _convertToUserProfile(UserModel userModel) {
    // For now, generate mock profile - in production, convert from UserModel
    return _generateMockProfile();
  }
  
  /// Start editing profile
  void startEditing() {
    if (_profile.value == null) return;
    
    _tempProfile.value = _profile.value!.copyWith();
    _isEditing(true);
    _hasUnsavedChanges(false);
  }
  
  /// Cancel editing
  void cancelEditing() {
    if (_hasUnsavedChanges.value) {
      _showDiscardChangesDialog(() {
        _tempProfile.value = null;
        _isEditing(false);
        _hasUnsavedChanges(false);
      });
    } else {
      _tempProfile.value = null;
      _isEditing(false);
      _hasUnsavedChanges(false);
    }
  }
  
  /// Save profile changes with offline support
  Future<void> saveProfile() async {
    if (_tempProfile.value == null) return;

    // Validate required fields
    if (!_validateProfile(_tempProfile.value!)) return;

    _isSaving(true);

    try {
      // Convert UserProfile to UserModel for repository
      final userModel = _convertToUserModel(_tempProfile.value!);

      // Use network-only operation for saves (requires server confirmation)
      final result = await executeNetworkOnly<UserModel>(
        () async {
          return await _userRepository.updateUser(userModel);
        },
        requireGoodConnection: false, // Allow save on poor connection
        onSuccess: (savedUser) {
          // Update main profile
          _profile.value = _tempProfile.value!.copyWith(
            updatedAt: DateTime.now(),
          );

          _tempProfile.value = null;
          _isEditing(false);
          _hasUnsavedChanges(false);

          showSuccessSnackbar('Perfil atualizado com sucesso');
        },
        onNoConnection: () {
          showWarningSnackbar('Sem conexão - alterações serão salvas quando conectar');

          // Save optimistically in offline mode
          _profile.value = _tempProfile.value!.copyWith(
            updatedAt: DateTime.now(),
          );

          _tempProfile.value = null;
          _isEditing(false);
          _hasUnsavedChanges(false);
        },
      );

      // If online save failed but we want to save locally
      if (result == null && !isOnline) {
        // The onNoConnection callback already handled this
      }

    } catch (e) {
      showErrorSnackbar('Erro ao salvar perfil: $e');
    } finally {
      _isSaving(false);
    }
  }

  /// Convert UserProfile to UserModel (adapt based on your models)
  UserModel _convertToUserModel(UserProfile profile) {
    // For now, create basic UserModel - in production, convert from UserProfile
    return UserModel(
      id: profile.id,
      email: profile.email,
      role: 'patient', // Default role
      isActive: true,
      createdAt: profile.createdAt,
      updatedAt: DateTime.now(),
      displayName: profile.personalInfo.fullName,
      phoneNumber: profile.contactInfo.phone,
      photoUrl: profile.photoUrl,
      isLocalOnly: !isOnline, // Mark as local-only if offline
    );
  }
  
  /// Update personal info
  void updatePersonalInfo(PersonalInfo personalInfo) {
    if (_tempProfile.value == null) return;
    
    _tempProfile.value = _tempProfile.value!.copyWith(
      personalInfo: personalInfo,
    );
    _hasUnsavedChanges(true);
  }
  
  /// Update health info
  void updateHealthInfo(HealthInfo healthInfo) {
    if (_tempProfile.value == null) return;
    
    _tempProfile.value = _tempProfile.value!.copyWith(
      healthInfo: healthInfo,
    );
    _hasUnsavedChanges(true);
  }
  
  /// Update contact info
  void updateContactInfo(ContactInfo contactInfo) {
    if (_tempProfile.value == null) return;
    
    _tempProfile.value = _tempProfile.value!.copyWith(
      contactInfo: contactInfo,
    );
    _hasUnsavedChanges(true);
  }
  
  /// Update privacy settings
  void updatePrivacySettings(PrivacySettings privacySettings) {
    if (_tempProfile.value == null) return;
    
    _tempProfile.value = _tempProfile.value!.copyWith(
      privacySettings: privacySettings,
    );
    _hasUnsavedChanges(true);
  }
  
  /// Update notification settings
  void updateNotificationSettings(NotificationSettings notificationSettings) {
    if (_tempProfile.value == null) return;
    
    _tempProfile.value = _tempProfile.value!.copyWith(
      notificationSettings: notificationSettings,
    );
    _hasUnsavedChanges(true);
  }
  
  /// Add allergy
  void addAllergy(String allergy) {
    if (_tempProfile.value == null || allergy.isEmpty) return;
    
    final allergies = List<String>.from(_tempProfile.value!.allergies);
    if (!allergies.contains(allergy)) {
      allergies.add(allergy);
      _tempProfile.value = _tempProfile.value!.copyWith(allergies: allergies);
      _hasUnsavedChanges(true);
    }
  }
  
  /// Remove allergy
  void removeAllergy(String allergy) {
    if (_tempProfile.value == null) return;
    
    final allergies = List<String>.from(_tempProfile.value!.allergies);
    allergies.remove(allergy);
    _tempProfile.value = _tempProfile.value!.copyWith(allergies: allergies);
    _hasUnsavedChanges(true);
  }
  
  /// Add medication
  void addMedication(String medication) {
    if (_tempProfile.value == null || medication.isEmpty) return;
    
    final medications = List<String>.from(_tempProfile.value!.medications);
    if (!medications.contains(medication)) {
      medications.add(medication);
      _tempProfile.value = _tempProfile.value!.copyWith(medications: medications);
      _hasUnsavedChanges(true);
    }
  }
  
  /// Remove medication
  void removeMedication(String medication) {
    if (_tempProfile.value == null) return;
    
    final medications = List<String>.from(_tempProfile.value!.medications);
    medications.remove(medication);
    _tempProfile.value = _tempProfile.value!.copyWith(medications: medications);
    _hasUnsavedChanges(true);
  }
  
  /// Add health condition
  void addHealthCondition(String condition) {
    if (_tempProfile.value == null || condition.isEmpty) return;
    
    final conditions = List<String>.from(_tempProfile.value!.healthConditions);
    if (!conditions.contains(condition)) {
      conditions.add(condition);
      _tempProfile.value = _tempProfile.value!.copyWith(healthConditions: conditions);
      _hasUnsavedChanges(true);
    }
  }
  
  /// Remove health condition
  void removeHealthCondition(String condition) {
    if (_tempProfile.value == null) return;
    
    final conditions = List<String>.from(_tempProfile.value!.healthConditions);
    conditions.remove(condition);
    _tempProfile.value = _tempProfile.value!.copyWith(healthConditions: conditions);
    _hasUnsavedChanges(true);
  }
  
  /// Update profile photo
  Future<void> updateProfilePhoto() async {
    try {
      final source = await _showImageSourceDialog();
      if (source == null) return;
      
      _isUpdatingPhoto(true);
      
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile == null) return;
      
      // Simulate image upload
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // Update profile with new photo URL
      final newPhotoUrl = 'https://example.com/photos/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      if (_isEditing.value && _tempProfile.value != null) {
        _tempProfile.value = _tempProfile.value!.copyWith(photoUrl: newPhotoUrl);
        _hasUnsavedChanges(true);
      } else {
        _profile.value = _profile.value!.copyWith(
          photoUrl: newPhotoUrl,
          updatedAt: DateTime.now(),
        );
      }
      
      Get.snackbar(
        'Sucesso',
        'Foto atualizada com sucesso',
        snackPosition: SnackPosition.BOTTOM,
      );
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao atualizar foto: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isUpdatingPhoto(false);
    }
  }
  
  /// Remove profile photo
  Future<void> removeProfilePhoto() async {
    try {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Remover Foto'),
          content: const Text('Tem certeza que deseja remover sua foto de perfil?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remover'),
            ),
          ],
        ),
      ) ?? false;
      
      if (!confirmed) return;
      
      if (_isEditing.value && _tempProfile.value != null) {
        _tempProfile.value = _tempProfile.value!.copyWith(photoUrl: null);
        _hasUnsavedChanges(true);
      } else {
        _profile.value = _profile.value!.copyWith(
          photoUrl: null,
          updatedAt: DateTime.now(),
        );
      }
      
      Get.snackbar(
        'Sucesso',
        'Foto removida com sucesso',
        snackPosition: SnackPosition.BOTTOM,
      );
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao remover foto: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  /// LGPD: Export user data
  Future<void> exportUserData() async {
    try {
      _isLoading(true);
      
      // Simulate data export generation
      await Future.delayed(const Duration(milliseconds: 2500));
      
      // In real app, this would generate a comprehensive data export
      // including all user data, appointments, health records, documents, etc.
      
      Get.snackbar(
        'Exportação Iniciada',
        'Seus dados serão enviados por email em até 24h',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao exportar dados: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }
  
  /// LGPD: Delete user account
  Future<void> deleteAccount() async {
    final confirmed = await _showAccountDeletionDialog();
    if (!confirmed) return;
    
    try {
      _isLoading(true);
      
      // Simulate account deletion
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // In real app, this would:
      // 1. Cancel all active appointments
      // 2. Delete all user data
      // 3. Keep audit logs as required by law
      // 4. Send confirmation email
      // 5. Sign out user
      
      Get.snackbar(
        'Conta Excluída',
        'Sua conta foi excluída permanentemente',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      
      // Navigate to login screen
      Get.offAllNamed('/auth/login');
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao excluir conta: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading(false);
    }
  }
  
  /// Update LGPD consent
  Future<void> updateConsent(String consentType, bool granted) async {
    if (_profile.value == null) return;
    
    try {
      PrivacySettings newSettings;
      
      switch (consentType) {
        case 'data_processing':
          newSettings = _profile.value!.privacySettings.copyWith(
            dataProcessingConsent: granted,
            consentDate: granted ? DateTime.now() : _profile.value!.privacySettings.consentDate,
          );
          break;
        case 'marketing':
          newSettings = _profile.value!.privacySettings.copyWith(
            marketingConsent: granted,
          );
          break;
        case 'analytics':
          newSettings = _profile.value!.privacySettings.copyWith(
            analyticsConsent: granted,
          );
          break;
        case 'sharing':
          newSettings = _profile.value!.privacySettings.copyWith(
            sharingConsent: granted,
          );
          break;
        default:
          return;
      }
      
      if (_isEditing.value && _tempProfile.value != null) {
        _tempProfile.value = _tempProfile.value!.copyWith(privacySettings: newSettings);
        _hasUnsavedChanges(true);
      } else {
        // Immediately save privacy settings
        _profile.value = _profile.value!.copyWith(
          privacySettings: newSettings,
          updatedAt: DateTime.now(),
        );
        
        // Simulate API call
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao atualizar consentimento: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  /// Show image source selection dialog
  Future<ImageSource?> _showImageSourceDialog() async {
    return await Get.dialog<ImageSource>(
      AlertDialog(
        title: const Text('Selecionar Origem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Show discard changes dialog
  void _showDiscardChangesDialog(VoidCallback onConfirm) {
    Get.dialog(
      AlertDialog(
        title: const Text('Descartar Alterações'),
        content: const Text('Você possui alterações não salvas. Deseja descartá-las?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Continuar Editando'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
  }
  
  /// Show account deletion confirmation dialog
  Future<bool> _showAccountDeletionDialog() async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Excluir Conta'),
        content: const Text(
          'ATENÇÃO: Esta ação é irreversível.\n\n'
          'Todos os seus dados serão permanentemente excluídos:\n'
          '• Perfil e informações pessoais\n'
          '• Histórico de agendamentos\n'
          '• Documentos e fotos\n'
          '• Créditos SG restantes\n\n'
          'Tem certeza que deseja continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir Permanentemente'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// Validate profile data
  bool _validateProfile(UserProfile profile) {
    // Basic validation
    if (profile.personalInfo.fullName.isEmpty) {
      Get.snackbar('Erro', 'Nome completo é obrigatório');
      return false;
    }
    
    if (profile.contactInfo.phone.isEmpty) {
      Get.snackbar('Erro', 'Telefone é obrigatório');
      return false;
    }
    
    // CPF validation (basic)
    if (profile.personalInfo.cpf.isNotEmpty) {
      final cpf = profile.personalInfo.cpf.replaceAll(RegExp(r'[^0-9]'), '');
      if (cpf.length != 11) {
        Get.snackbar('Erro', 'CPF deve ter 11 dígitos');
        return false;
      }
    }
    
    return true;
  }
  
  /// Generate mock profile for demonstration
  UserProfile _generateMockProfile() {
    final now = DateTime.now();
    
    return UserProfile(
      id: 'user123',
      email: 'usuario@email.com',
      photoUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=200&h=200&fit=crop&crop=face',
      personalInfo: PersonalInfo(
        fullName: 'Maria da Silva Santos',
        birthDate: DateTime(1990, 5, 15),
        gender: 'Feminino',
        cpf: '123.456.789-00',
        rg: '12.345.678-9',
        occupation: 'Engenheira de Software',
        maritalStatus: 'Solteira',
      ),
      healthInfo: HealthInfo(
        bloodType: 'O+',
        weight: 65.5,
        height: 165.0,
        insuranceProvider: 'Unimed',
        insuranceNumber: '123456789',
        primaryDoctor: 'Dr. Carlos Lima',
        primaryDoctorPhone: '(11) 99999-8888',
      ),
      contactInfo: ContactInfo(
        phone: '(11) 99999-9999',
        whatsapp: '(11) 99999-9999',
        address: Address(
          street: 'Rua das Flores',
          number: '123',
          complement: 'Apto 45',
          neighborhood: 'Centro',
          city: 'São Paulo',
          state: 'SP',
          zipCode: '01234-567',
        ),
      ),
      privacySettings: PrivacySettings(
        dataProcessingConsent: true,
        marketingConsent: false,
        analyticsConsent: true,
        sharingConsent: false,
        consentDate: now.subtract(const Duration(days: 30)),
        dataProcessingPurposes: [
          'Agendamento de consultas',
          'Histórico médico',
          'Comunicação sobre procedimentos',
        ],
      ),
      notificationSettings: NotificationSettings(
        pushNotifications: true,
        emailNotifications: true,
        smsNotifications: false,
        appointmentReminders: true,
        promotionalNotifications: false,
        healthTips: true,
        reminderHoursBefore: 24,
      ),
      allergies: ['Penicilina', 'Frutos do mar'],
      medications: ['Vitamina D', 'Ômega 3'],
      healthConditions: ['Hipertensão leve'],
      emergencyContacts: [
        'João Santos - (11) 88888-7777 - Irmão',
        'Ana Santos - (11) 77777-6666 - Mãe',
      ],
      createdAt: now.subtract(const Duration(days: 365)),
      updatedAt: now.subtract(const Duration(days: 7)),
      lastLoginAt: now.subtract(const Duration(hours: 2)),
      isActive: true,
      isVerified: true,
      hasCompletedOnboarding: true,
    );
  }
}

/// Privacy Settings Extension for easier updates
extension PrivacySettingsExtension on PrivacySettings {
  PrivacySettings copyWith({
    bool? dataProcessingConsent,
    bool? marketingConsent,
    bool? analyticsConsent,
    bool? sharingConsent,
    DateTime? consentDate,
    bool? allowDataExport,
    bool? allowDataDeletion,
    List<String>? dataProcessingPurposes,
  }) {
    return PrivacySettings(
      dataProcessingConsent: dataProcessingConsent ?? this.dataProcessingConsent,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      analyticsConsent: analyticsConsent ?? this.analyticsConsent,
      sharingConsent: sharingConsent ?? this.sharingConsent,
      consentDate: consentDate ?? this.consentDate,
      allowDataExport: allowDataExport ?? this.allowDataExport,
      allowDataDeletion: allowDataDeletion ?? this.allowDataDeletion,
      dataProcessingPurposes: dataProcessingPurposes ?? this.dataProcessingPurposes,
    );
  }
}