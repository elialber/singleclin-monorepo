import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:singleclin_mobile/core/routes/app_routes.dart';
import 'package:singleclin_mobile/presentation/widgets/manual_code_dialog.dart';
import 'package:singleclin_mobile/presentation/widgets/patient_data_bottom_sheet.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Screen for clinic staff to scan patient QR codes
///
/// This screen allows clinic staff to:
/// - Scan QR codes from patients using camera
/// - Validate QR codes in real-time
/// - View patient information after successful scan
/// - Access manual code entry as alternative
/// - View scan history for the day
class ClinicScannerScreen extends StatefulWidget {
  const ClinicScannerScreen({super.key});

  @override
  State<ClinicScannerScreen> createState() => _ClinicScannerScreenState();
}

class _ClinicScannerScreenState extends State<ClinicScannerScreen>
    with TickerProviderStateMixin {
  // Scanner controller
  MobileScannerController? _controller;

  // Animation controllers
  AnimationController? _scanAnimationController;
  AnimationController? _borderAnimationController;
  Animation<Color?>? _borderColorAnimation;

  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Scanner state
  bool _isProcessing = false;
  bool _isValid = false;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanAnimationController?.dispose();
    _borderAnimationController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Initialize the mobile scanner controller
  void _initializeController() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  /// Initialize animation controllers
  void _initializeAnimations() {
    // Scanning line animation
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Border color animation
    _borderAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _borderColorAnimation = ColorTween(begin: Colors.white, end: Colors.green)
        .animate(
          CurvedAnimation(
            parent: _borderAnimationController!,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Build app bar with title and actions
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Scanner QR Code'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        // Flash/torch toggle
        IconButton(
          icon: Icon(
            (_controller?.torchEnabled ?? false)
                ? Icons.flash_on
                : Icons.flash_off,
          ),
          onPressed: _toggleFlash,
          tooltip: 'Lanterna',
        ),
        // Camera flip
        IconButton(
          icon: const Icon(Icons.flip_camera_ios),
          onPressed: _flipCamera,
          tooltip: 'Inverter câmera',
        ),
        // Scan history
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: _openScanHistory,
          tooltip: 'Histórico do dia',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Build main body content
  Widget _buildBody() {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Camera scanner view
        _buildScannerView(),

        // Overlay with scan area and instructions
        _buildScannerOverlay(),

        // Processing indicator
        if (_isProcessing) _buildProcessingOverlay(),
      ],
    );
  }

  /// Build the mobile scanner view
  Widget _buildScannerView() {
    return MobileScanner(
      controller: _controller,
      onDetect: _onQRCodeDetected,
      errorBuilder: (context, error, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Erro ao acessar a câmera',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error.errorDetails?.message ??
                    'Verifique as permissões da câmera',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _reinitializeController,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build scanner overlay with scan area and instructions
  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        // Background overlay with cutout
        ShaderMask(
          shaderCallback: (rect) {
            return RadialGradient(
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
              stops: const [0.3, 1.0],
              radius: 0.8,
            ).createShader(rect);
          },
          blendMode: BlendMode.dstOut,
          child: Container(color: Colors.black.withValues(alpha: 0.5)),
        ),
        // Foreground content
        Column(
          children: [
            const Spacer(flex: 2),

            // Scan area indicator with animated border
            AnimatedBuilder(
              animation: _borderColorAnimation!,
              builder: (context, child) {
                Color borderColor = Colors.white;
                if (_isProcessing) {
                  borderColor = Colors.orange;
                } else if (_isValid) {
                  borderColor = _borderColorAnimation!.value ?? Colors.green;
                }

                return Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Scanning line animation
                      if (!_isProcessing && !_isValid)
                        AnimatedBuilder(
                          animation: _scanAnimationController!,
                          builder: (context, child) {
                            return Positioned(
                              left: 0,
                              right: 0,
                              top: _scanAnimationController!.value * (250 - 4),
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.blue.withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Instructions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isProcessing
                        ? 'Processando código...'
                        : 'Aponte a câmera para o QR Code do paciente',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_lastScannedCode != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Último código: ${_lastScannedCode!.substring(0, 8)}...',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ],
    );
  }

  /// Build processing overlay
  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Validando código QR...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build floating action button for manual entry
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _openManualEntry,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      tooltip: 'Entrada manual',
      child: const Icon(Icons.keyboard),
    );
  }

  /// Handle QR code detection
  void _onQRCodeDetected(BarcodeCapture capture) {
    if (_isProcessing) {
      return;
    }

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      return;
    }

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    if (code == null || code.isEmpty) {
      return;
    }

    // Avoid processing the same code multiple times
    if (_lastScannedCode == code) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
    });

    _processQRCode(code);
  }

  /// Process the scanned QR code
  Future<void> _processQRCode(String code) async {
    try {
      // Simulate API validation delay
      await Future.delayed(const Duration(seconds: 1));

      // TODO(scanner): Implement actual QR code validation
      // - Validate format (UUID)
      // - Check if code is active/not expired
      // - Fetch patient data from API

      // For now, simulate success for demo
      final isValid = _validateQRCodeFormat(code);

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isValid = isValid;
        });

        if (isValid) {
          // Play success sound and show green border
          unawaited(_playSuccessSound());
          unawaited(_borderAnimationController?.forward());

          // Wait a moment for feedback then show patient data
          await Future.delayed(const Duration(milliseconds: 500));
          _showPatientData(code);

          // Reset states after showing data
          setState(() {
            _isValid = false;
          });
          _borderAnimationController?.reset();
        } else {
          // Play error sound and show red border briefly
          unawaited(_playErrorSound());
          _showErrorFeedback();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isValid = false;
        });
        unawaited(_playErrorSound());
        _showErrorMessage('Erro ao validar código: ${e.toString()}');
      }
    }
  }

  /// Play success sound
  Future<void> _playSuccessSound() async {
    try {
      // For now, we'll simulate success sound with haptic feedback
      // TODO(audio): Add custom success sound file to assets/sounds/success.mp3
      debugPrint('Reproduzindo som de sucesso - QR válido');
      // Alternative: Use HapticFeedback.lightImpact() for tactile feedback
    } catch (e) {
      debugPrint('Erro ao reproduzir som de sucesso: $e');
    }
  }

  /// Play error sound
  Future<void> _playErrorSound() async {
    try {
      // For now, we'll simulate error sound with haptic feedback
      // TODO(audio): Add custom error sound file to assets/sounds/error.mp3
      debugPrint('Reproduzindo som de erro - QR inválido');
      // Alternative: Use HapticFeedback.heavyImpact() for tactile feedback
    } catch (e) {
      debugPrint('Erro ao reproduzir som de erro: $e');
    }
  }

  /// Show error feedback with red border animation
  void _showErrorFeedback() {
    // Temporarily change border color to red
    final originalAnimation = _borderColorAnimation;
    _borderColorAnimation = ColorTween(begin: Colors.white, end: Colors.red)
        .animate(
          CurvedAnimation(
            parent: _borderAnimationController!,
            curve: Curves.easeInOut,
          ),
        );

    _borderAnimationController?.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _borderColorAnimation = originalAnimation;
          });
          _borderAnimationController?.reset();
          _showErrorMessage('Código QR inválido ou expirado');
        }
      });
    });
  }

  /// Validate QR code format (basic UUID check)
  bool _validateQRCodeFormat(String code) {
    // Check if it matches the format: USR-{userId}-{timestamp}
    final pattern = RegExp(r'^USR-.+-\d+$');
    return pattern.hasMatch(code);
  }

  /// Show patient data modal
  void _showPatientData(String code) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PatientDataBottomSheet(
        qrCode: code,
        onConfirm: (serviceId) async {
          // Handle service confirmation
          await _processServiceConfirmation(code, serviceId);
        },
      ),
    ).then((result) {
      // Reset scanner state after modal is closed
      if (mounted) {
        setState(() {
          _lastScannedCode = null; // Allow scanning the same code again
        });
      }
    });
  }

  /// Process service confirmation after user selects a service
  Future<void> _processServiceConfirmation(
    String qrCode,
    String serviceId,
  ) async {
    try {
      // TODO(api): Implement actual API call to register the attendance
      // POST /attendances with { qrCode, serviceId, clinicId }

      // For now, simulate success
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Atendimento registrado com sucesso!')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Close the modal and return to scanner
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Erro ao registrar atendimento: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show error message
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Toggle camera flash/torch
  void _toggleFlash() {
    _controller?.toggleTorch();
    setState(() {}); // Rebuild to update icon
  }

  /// Flip camera (front/back)
  void _flipCamera() {
    _controller?.switchCamera();
  }

  /// Reinitialize controller after error
  void _reinitializeController() {
    _controller?.dispose();
    _initializeController();
    setState(() {});
  }

  /// Open manual entry dialog
  void _openManualEntry() {
    // Pause scanner while dialog is open
    _controller?.stop();

    showDialog(
      context: context,
      builder: (context) => ManualCodeDialog(
        onCodeSubmit: (code) async {
          // Process the manually entered code using the same flow as scanner
          Navigator.of(context).pop(); // Close dialog first
          await _processQRCode(code);
        },
      ),
    ).then((_) {
      // Resume scanner when dialog closes
      _controller?.start();
    });
  }

  /// Open scan history screen
  void _openScanHistory() {
    context.push(AppRoutes.clinicScanHistory);
  }
}
