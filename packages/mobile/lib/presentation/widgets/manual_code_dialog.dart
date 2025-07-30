import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dialog for manual QR code entry
class ManualCodeDialog extends StatefulWidget {
  const ManualCodeDialog({required this.onCodeSubmit, super.key});
  final Function(String code) onCodeSubmit;

  @override
  State<ManualCodeDialog> createState() => _ManualCodeDialogState();
}

class _ManualCodeDialogState extends State<ManualCodeDialog> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isValidating = false;
  String? _errorMessage;
  List<String> _recentCodes = [];

  // Constants for SharedPreferences
  static const String _recentCodesKey = 'recent_manual_codes';
  static const int _maxRecentCodes = 5;

  @override
  void initState() {
    super.initState();
    _loadRecentCodes();
    // Auto-focus on text field when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Load recent codes from SharedPreferences
  Future<void> _loadRecentCodes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final codes = prefs.getStringList(_recentCodesKey) ?? [];
      if (mounted) {
        setState(() {
          _recentCodes = codes;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent codes: $e');
    }
  }

  /// Save code to recent codes list
  Future<void> _saveToRecentCodes(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove if already exists to avoid duplicates
      _recentCodes.remove(code);

      // Add to beginning of list
      _recentCodes.insert(0, code);

      // Keep only the most recent codes
      if (_recentCodes.length > _maxRecentCodes) {
        _recentCodes = _recentCodes.take(_maxRecentCodes).toList();
      }

      // Save to SharedPreferences
      await prefs.setStringList(_recentCodesKey, _recentCodes);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error saving recent code: $e');
    }
  }

  /// Validate QR code format
  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira um código';
    }

    // Remove any whitespace
    final cleanedValue = value.trim();

    // Check if it matches the expected format: USR-{userId}-{timestamp}
    final pattern = RegExp(r'^USR-[A-Za-z0-9]+-\d+$');
    if (!pattern.hasMatch(cleanedValue)) {
      return 'Formato inválido. Exemplo: USR-ABC123-1234567890';
    }

    // Validate parts
    final parts = cleanedValue.split('-');
    if (parts.length != 3) {
      return 'Código deve ter 3 partes separadas por hífen';
    }

    if (parts[1].isEmpty) {
      return 'ID do usuário não pode estar vazio';
    }

    // Validate timestamp is a number
    final timestamp = int.tryParse(parts[2]);
    if (timestamp == null) {
      return 'Timestamp inválido';
    }

    return null;
  }

  /// Format input text with automatic hyphens
  void _formatInput(String value) {
    // Remove all non-alphanumeric characters except hyphens
    String cleaned = value.replaceAll(RegExp('[^A-Za-z0-9-]'), '');

    // Auto-add USR- prefix if not present
    if (!cleaned.startsWith('USR-') && cleaned.isNotEmpty) {
      if (cleaned.startsWith('USR')) {
        cleaned = 'USR-${cleaned.substring(3)}';
      } else {
        cleaned = 'USR-$cleaned';
      }
    }

    // Update controller if format changed
    if (cleaned != value) {
      _codeController.value = TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      );
    }
  }

  /// Handle paste from clipboard
  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null && clipboardData.text != null) {
        final pastedText = clipboardData.text!.trim();
        _codeController.text = pastedText;
        _formatInput(pastedText);

        // Validate immediately after paste
        _formKey.currentState?.validate();
      }
    } catch (e) {
      debugPrint('Error pasting from clipboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao colar da área de transferência'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle code submission
  Future<void> _submitCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    final code = _codeController.text.trim();

    try {
      // Save to recent codes
      await _saveToRecentCodes(code);

      // Call the callback to process the code
      widget.onCodeSubmit(code);

      if (mounted) {
        Navigator.of(context).pop(code);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
          _errorMessage = 'Erro ao processar código: ${e.toString()}';
        });
      }
    }
  }

  /// Select a recent code
  void _selectRecentCode(String code) {
    _codeController.text = code;
    _formatInput(code);
    _formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.keyboard, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          const Text('Entrada Manual de Código'),
        ],
      ),
      content: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Digite o código QR do paciente',
                        style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Code input form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _codeController,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Código QR',
                        hintText: 'USR-XXXXX-1234567890',
                        prefixIcon: const Icon(Icons.qr_code),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste),
                          onPressed: _pasteFromClipboard,
                          tooltip: 'Colar da área de transferência',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorText: _errorMessage,
                        errorMaxLines: 2,
                      ),
                      validator: _validateCode,
                      onChanged: _formatInput,
                      onFieldSubmitted: (_) => _submitCode(),
                      enabled: !_isValidating,
                    ),

                    // Example format
                    const SizedBox(height: 8),
                    Text(
                      'Formato: USR-[ID]-[TIMESTAMP]',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Recent codes section
              if (_recentCodes.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Códigos Recentes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _recentCodes.length,
                    itemBuilder: (context, index) {
                      final code = _recentCodes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: InkWell(
                          onTap: () => _selectRecentCode(code),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    code,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: _isValidating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),

        // Submit button
        ElevatedButton.icon(
          onPressed: _isValidating ? null : _submitCode,
          icon: _isValidating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.check),
          label: Text(_isValidating ? 'Verificando...' : 'Verificar'),
        ),
      ],
    );
  }
}
