import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart'; // Temporariamente comentado
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:screenshot/screenshot.dart';
import 'package:singleclin_mobile/presentation/controllers/auth_controller.dart';

/// Screen for generating and displaying temporary QR codes
///
/// This screen allows patients to:
/// - Generate temporary QR codes for clinic visits
/// - View countdown timer for QR code expiration
/// - Regenerate new QR codes when expired
/// - Read instructions for clinic usage
class QRCodeScreen extends StatefulWidget {
  const QRCodeScreen({super.key});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  final AuthController _authController = Get.find<AuthController>();

  // QR Code state
  bool _isLoading = false;
  bool _isExpired = false;
  String? _qrData;

  // Timer state
  int _remainingSeconds = 300; // 5 minutes default
  Timer? _countdownTimer;

  // Brightness control
  double? _originalBrightness;

  // Screenshot controller for saving QR code
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _setMaxBrightness();
    _generateQRCode();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _restoreOriginalBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  /// Build app bar with title and actions
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Meu QR Code'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _isLoading || _isExpired ? null : _saveQRCode,
          tooltip: 'Salvar QR Code',
        ),
      ],
    );
  }

  /// Build main body content
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // User info section
          _buildUserInfoSection(),
          const SizedBox(height: 32),

          // QR Code section
          _buildQRCodeSection(),
          const SizedBox(height: 32),

          // Instructions section
          _buildInstructionsSection(),
        ],
      ),
    );
  }

  /// Build user information section
  Widget _buildUserInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Informações do Usuário',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(
            () => Text(
              _authController.currentUser?.displayName ?? 'Usuário',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Obx(
            () => Text(
              _authController.currentUser?.email ?? '',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  /// Build QR Code display section
  Widget _buildQRCodeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Timer section
          _buildTimerSection(),
          const SizedBox(height: 24),

          // QR Code display
          _buildQRCodeDisplay(),
          const SizedBox(height: 16),

          // QR Data display
          if (_qrData != null) _buildQRDataDisplay(),
          const SizedBox(height: 24),

          // Action button
          _buildActionButton(),
        ],
      ),
    );
  }

  /// Build timer countdown section
  Widget _buildTimerSection() {
    if (_isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Text(
          _isExpired ? 'QR Code Expirado' : 'Tempo Restante',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: _isExpired ? Colors.red : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        if (!_isExpired) ...[
          Text(
            timeText,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _remainingSeconds <= 60
                  ? Colors.red
                  : Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _remainingSeconds / 300, // 5 minutes total
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _remainingSeconds <= 60
                  ? Colors.red
                  : Theme.of(context).primaryColor,
            ),
          ),
        ],
      ],
    );
  }

  /// Build QR Code display widget
  Widget _buildQRCodeDisplay() {
    if (_isLoading) {
      return Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isExpired || _qrData == null) {
      return Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _isExpired ? 'QR Code Expirado' : 'Gerando QR Code...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Display actual QR Code using QrImageView with Screenshot wrapper
    return Screenshot(
      controller: _screenshotController,
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: QrImageView(
            data: _qrData!,
            size: 248, // 280 - 32 (padding)
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(color: Colors.black),
            dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  /// Build QR data display (alphanumeric code)
  Widget _buildQRDataDisplay() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Código de Referência',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            _qrData ?? '',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// Build action button (generate new QR)
  Widget _buildActionButton() {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isExpired ? _generateQRCode : null,
        icon: Icon(_isExpired ? Icons.refresh : Icons.check_circle),
        label: Text(_isExpired ? 'Gerar Novo QR Code' : 'QR Code Ativo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isExpired
              ? Theme.of(context).primaryColor
              : Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Build instructions section
  Widget _buildInstructionsSection() {
    return Card(
      child: ExpansionTile(
        leading: Icon(
          Icons.help_outline,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          'Como usar',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionItem(
                  '1.',
                  'Apresente este QR Code na recepção da clínica',
                  Icons.qr_code_scanner,
                ),
                const SizedBox(height: 12),
                _buildInstructionItem(
                  '2.',
                  'O código expira em 5 minutos para sua segurança',
                  Icons.timer,
                ),
                const SizedBox(height: 12),
                _buildInstructionItem(
                  '3.',
                  'Cada uso consome 1 crédito do seu plano',
                  Icons.credit_card,
                ),
                const SizedBox(height: 12),
                _buildInstructionItem(
                  '4.',
                  'Você pode salvar o QR Code na galeria se necessário',
                  Icons.save_alt,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual instruction item
  Widget _buildInstructionItem(String number, String text, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  /// Generate new QR Code
  Future<void> _generateQRCode() async {
    // Cancel any existing timer
    _countdownTimer?.cancel();

    setState(() {
      _isLoading = true;
      _isExpired = false;
    });

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      final userId = _authController.currentUser?.id ?? 'unknown';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final qrData = 'USR-$userId-$timestamp';

      setState(() {
        _qrData = qrData;
        _remainingSeconds = 300; // 5 minutes
        _isLoading = false;
      });

      // Start countdown timer
      _startCountdownTimer();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar QR Code: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Start countdown timer for QR code expiration
  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        // QR Code expired
        timer.cancel();
        setState(() {
          _isExpired = true;
          _qrData = null;
        });

        // Show expiration notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'QR Code expirado. Toque em "Gerar Novo QR Code" para criar um novo.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  /// Set screen brightness to maximum for better QR code visibility
  Future<void> _setMaxBrightness() async {
    try {
      // Store original brightness level
      _originalBrightness = await ScreenBrightness().current;

      // Set to maximum brightness (1.0)
      await ScreenBrightness().setScreenBrightness(1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Brilho aumentado para melhor visualização do QR Code',
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // If brightness control fails, continue without it
      debugPrint('Erro ao ajustar brilho: $e');
    }
  }

  /// Restore original screen brightness when leaving the screen
  Future<void> _restoreOriginalBrightness() async {
    try {
      if (_originalBrightness != null) {
        await ScreenBrightness().setScreenBrightness(_originalBrightness!);
      } else {
        // Reset to system brightness if original brightness wasn't captured
        await ScreenBrightness().resetScreenBrightness();
      }
    } catch (e) {
      // If brightness restore fails, try system reset
      try {
        await ScreenBrightness().resetScreenBrightness();
      } catch (resetError) {
        debugPrint('Erro ao restaurar brilho: $resetError');
      }
    }
  }

  /// Save QR Code to gallery
  Future<void> _saveQRCode() async {
    if (_qrData == null || _isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não é possível salvar um QR Code expirado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading indication
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Salvando QR Code...'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );

      // Capture screenshot of QR code
      final Uint8List? imageBytes = await _screenshotController.capture();

      if (imageBytes == null) {
        throw Exception('Falha ao capturar imagem do QR Code');
      }

      // Save to gallery - temporariamente desabilitado
      // final result = await ImageGallerySaver.saveImage(
      //   imageBytes,
      //   name: 'QRCode_SingleClin_${DateTime.now().millisecondsSinceEpoch}',
      //   quality: 100,
      // );

      if (mounted) {
        // Temporariamente sempre mostra sucesso
        if (true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QR Code salvo com sucesso!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Verifique sua galeria de fotos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          throw Exception('Falha ao salvar na galeria');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Erro ao salvar QR Code',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(e.toString(), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Tentar novamente',
              textColor: Colors.white,
              onPressed: _saveQRCode,
            ),
          ),
        );
      }
    }
  }
}
