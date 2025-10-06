import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:singleclin_mobile/data/services/firebase_initialization_service.dart';

/// Displays the current Firebase availability status with retry and diagnostics.
class FirebaseUnavailableView extends StatelessWidget {
  const FirebaseUnavailableView({
    super.key,
    this.compact = false,
    this.showRetryButton = true,
  });

  final bool compact;
  final bool showRetryButton;

  @override
  Widget build(BuildContext context) {
    final firebaseService = Get.find<FirebaseInitializationService>();

    final spacing = compact ? 16.0 : 24.0;
    final iconSize = compact ? 56.0 : 80.0;
    final headlineStyle = Theme.of(context).textTheme.headlineSmall;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;

    return Obx(() {
      final isInitializing = firebaseService.isInitializing;
      final failureCount = firebaseService.consecutiveFailures;
      final lastError = firebaseService.lastErrorMessage;
      final lastAttemptAt = firebaseService.lastAttemptAt;
      final lastSuccessAt = firebaseService.lastSuccessAt;

      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 24,
            vertical: compact ? 24 : 48,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: iconSize,
                  color: Theme.of(context).colorScheme.error,
                ),
                SizedBox(height: spacing),
                Text(
                  'Serviço de autenticação indisponível',
                  textAlign: TextAlign.center,
                  style: headlineStyle?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  'Não conseguimos conectar ao Firebase. Sem essa conexão o login e o cadastro ficam indisponíveis.',
                  textAlign: TextAlign.center,
                  style: bodyStyle?.copyWith(color: Colors.grey.shade700),
                ),
                SizedBox(height: spacing),
                if (showRetryButton)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isInitializing ? null : firebaseService.retry,
                      icon: isInitializing
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(
                        isInitializing
                            ? 'Tentando novamente...'
                            : 'Tentar novamente',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: spacing / 2),
                TextButton.icon(
                  onPressed: () => _showRecoveryTips(context),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Como resolver?'),
                ),
                SizedBox(height: spacing),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diagnóstico rápido',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _DiagnosticRow(
                          label: 'Tentativas consecutivas falhas',
                          value: failureCount.toString(),
                        ),
                        _DiagnosticRow(
                          label: 'Última tentativa',
                          value: _formatTimestamp(lastAttemptAt),
                        ),
                        _DiagnosticRow(
                          label: 'Último sucesso',
                          value: _formatTimestamp(lastSuccessAt),
                        ),
                        if (lastError != null && lastError.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Detalhes técnicos',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            lastError,
                            style: bodyStyle?.copyWith(
                              color: Colors.grey.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  static String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) {
      return 'Nunca';
    }
    final local = timestamp.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date às $time';
  }

  void _showRecoveryTips(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Como reestabelecer a conexão',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              _TipItem(
                icon: Icons.wifi_tethering_off,
                text: 'Verifique se o dispositivo está conectado à internet.',
              ),
              _TipItem(
                icon: Icons.shield_moon,
                text:
                    'Confirme se VPN ou firewall não estão bloqueando o Firebase.',
              ),
              _TipItem(
                icon: Icons.update,
                text:
                    'Tente fechar e abrir o app novamente após alguns segundos.',
              ),
              _TipItem(
                icon: Icons.support_agent,
                text:
                    'Se o problema persistir, contate o suporte informando o horário e a mensagem de erro.',
              ),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
