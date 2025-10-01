import 'package:flutter/material.dart';
import 'package:singleclin_mobile/features/clinic_discovery/models/clinic.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';

class ActionButtonsSection extends StatefulWidget {
  const ActionButtonsSection({Key? key, required this.clinic})
    : super(key: key);
  final Clinic clinic;

  @override
  State<ActionButtonsSection> createState() => _ActionButtonsSectionState();
}

class _ActionButtonsSectionState extends State<ActionButtonsSection> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Save Button
        Expanded(
          child: InkWell(
            onTap: _handleSaveToggle,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _isSaved
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSaved
                      ? AppColors.primary.withOpacity(0.3)
                      : Colors.grey[300]!,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? AppColors.primary : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isSaved ? 'Salvo' : 'Salvar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isSaved ? AppColors.primary : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Share Button
        Expanded(
          child: InkWell(
            onTap: _handleShare,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share_outlined, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Compartilhar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleSaveToggle() {
    setState(() {
      _isSaved = !_isSaved;
    });

    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSaved
              ? '${widget.clinic.name} foi salva nos seus favoritos'
              : '${widget.clinic.name} foi removida dos favoritos',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _isSaved ? Colors.green : Colors.grey[700],
        action: SnackBarAction(
          label: 'Desfazer',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _isSaved = !_isSaved;
            });
          },
        ),
      ),
    );

    // TODO: Implement actual save/unsave functionality
    // This would typically involve:
    // 1. Calling an API to save/unsave the clinic
    // 2. Updating local storage or user preferences
    // 3. Updating user's saved clinics list
  }

  void _handleShare() {
    // Show share options dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareOptionsBottomSheet(clinic: widget.clinic),
    );
  }
}

class _ShareOptionsBottomSheet extends StatelessWidget {
  const _ShareOptionsBottomSheet({required this.clinic});
  final Clinic clinic;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            'Compartilhar ${clinic.name}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 24),

          // Share Options
          Column(
            children: [
              _ShareOption(
                icon: Icons.message,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _shareViaWhatsApp(context),
              ),
              _ShareOption(
                icon: Icons.message,
                label: 'SMS',
                color: Colors.blue,
                onTap: () => _shareViaSMS(context),
              ),
              _ShareOption(
                icon: Icons.email,
                label: 'Email',
                color: Colors.red,
                onTap: () => _shareViaEmail(context),
              ),
              _ShareOption(
                icon: Icons.copy,
                label: 'Copiar link',
                color: Colors.grey[600]!,
                onTap: () => _copyLink(context),
              ),
              _ShareOption(
                icon: Icons.more_horiz,
                label: 'Mais opções',
                color: Colors.grey[600]!,
                onTap: () => _showMoreOptions(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Cancel Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareViaWhatsApp(BuildContext context) {
    Navigator.pop(context);
    // TODO: Implement WhatsApp sharing
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Abrindo WhatsApp...')));
  }

  void _shareViaSMS(BuildContext context) {
    Navigator.pop(context);
    // TODO: Implement SMS sharing
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Abrindo SMS...')));
  }

  void _shareViaEmail(BuildContext context) {
    Navigator.pop(context);
    // TODO: Implement email sharing
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Abrindo email...')));
  }

  void _copyLink(BuildContext context) {
    Navigator.pop(context);
    // TODO: Copy link to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado para a área de transferência'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    Navigator.pop(context);
    // TODO: Show system share dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abrindo opções de compartilhamento...')),
    );
  }
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
