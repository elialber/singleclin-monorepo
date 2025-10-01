import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:singleclin_mobile/features/engagement/models/feedback_report.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';

/// Feedback form widget for collecting user feedback
class FeedbackForm extends StatefulWidget {
  const FeedbackForm({
    Key? key,
    required this.onSubmit,
    this.isSubmitting = false,
    this.error,
    this.templates,
  }) : super(key: key);
  final Function(Map<String, dynamic>) onSubmit;
  final bool isSubmitting;
  final String? error;
  final List<Map<String, String>>? templates;

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  FeedbackType _selectedType = FeedbackType.suggestion;
  FeedbackCategory _selectedCategory = FeedbackCategory.general;
  FeedbackPriority _selectedPriority = FeedbackPriority.medium;
  final List<File> _screenshots = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeSelector(),
          const SizedBox(height: 16),
          _buildCategorySelector(),
          const SizedBox(height: 16),
          _buildTitleField(),
          const SizedBox(height: 16),
          _buildDescriptionField(),
          if (widget.templates != null && widget.templates!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTemplates(),
          ],
          const SizedBox(height: 16),
          _buildPrioritySelector(),
          const SizedBox(height: 16),
          _buildScreenshotSection(),
          if (widget.error != null) ...[
            const SizedBox(height: 16),
            _buildErrorMessage(),
          ],
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Feedback',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FeedbackType.values.map((type) {
            final isSelected = _selectedType == type;
            return FilterChip(
              label: Text(_getTypeLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedType = type;
                  });
                }
              },
              backgroundColor: Colors.transparent,
              selectedColor: AppColors.primary.withOpacity(0.1),
              checkmarkColor: AppColors.primary,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.lightGrey,
              ),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.mediumGrey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoria',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<FeedbackCategory>(
          initialValue: _selectedCategory,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: FeedbackCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(_getCategoryLabel(category)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Título',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Descreva brevemente o problema ou sugestão',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, adicione um título';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descrição',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            hintText:
                'Descreva em detalhes sua experiência, problema ou sugestão',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          validator: (value) {
            if (value == null || value.trim().length < 10) {
              return 'A descrição deve ter pelo menos 10 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Templates',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.templates!.length,
            itemBuilder: (context, index) {
              final template = widget.templates![index];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: () {
                    _titleController.text = template['title'] ?? '';
                    _descriptionController.text = template['description'] ?? '';
                  },
                  child: Text(
                    template['title'] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prioridade',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: FeedbackPriority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_getPriorityLabel(priority)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPriority = priority;
                      });
                    }
                  },
                  backgroundColor: Colors.transparent,
                  selectedColor: _getPriorityColor(priority).withOpacity(0.1),
                  checkmarkColor: _getPriorityColor(priority),
                  side: BorderSide(
                    color: isSelected
                        ? _getPriorityColor(priority)
                        : AppColors.lightGrey,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? _getPriorityColor(priority)
                        : AppColors.mediumGrey,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScreenshotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Capturas de Tela',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              '(Opcional)',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_screenshots.isEmpty)
          _buildAddScreenshotButton()
        else
          _buildScreenshotGrid(),
      ],
    );
  }

  Widget _buildAddScreenshotButton() {
    return OutlinedButton.icon(
      onPressed: _addScreenshot,
      icon: const Icon(Icons.camera_alt),
      label: const Text('Adicionar Captura de Tela'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: AppColors.lightGrey),
      ),
    );
  }

  Widget _buildScreenshotGrid() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _screenshots.length + (_screenshots.length < 5 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _screenshots.length) {
              // Add button
              return InkWell(
                onTap: _addScreenshot,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lightGrey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_a_photo,
                        color: AppColors.mediumGrey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adicionar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Screenshot
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _screenshots[index],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () => _removeScreenshot(index),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Máximo de 5 capturas de tela',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.error!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.isSubmitting ? null : _submitForm,
        child: widget.isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Enviar Feedback'),
      ),
    );
  }

  Future<void> _addScreenshot() async {
    if (_screenshots.length >= 5) return;

    // This would integrate with image picker
    // For now, just show a placeholder
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(context);
                // Take photo
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Selecionar da galeria'),
              onTap: () {
                Navigator.pop(context);
                // Pick from gallery
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeScreenshot(int index) {
    setState(() {
      _screenshots.removeAt(index);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'type': _selectedType,
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'screenshots': _screenshots,
      };

      widget.onSubmit(data);
    }
  }

  String _getTypeLabel(FeedbackType type) {
    switch (type) {
      case FeedbackType.bugReport:
        return 'Bug';
      case FeedbackType.featureRequest:
        return 'Funcionalidade';
      case FeedbackType.improvement:
        return 'Melhoria';
      case FeedbackType.suggestion:
        return 'Sugestão';
      case FeedbackType.compliment:
        return 'Elogio';
      case FeedbackType.complaint:
        return 'Reclamação';
    }
  }

  String _getCategoryLabel(FeedbackCategory category) {
    switch (category) {
      case FeedbackCategory.general:
        return 'Geral';
      case FeedbackCategory.ui:
        return 'Interface';
      case FeedbackCategory.performance:
        return 'Performance';
      case FeedbackCategory.functionality:
        return 'Funcionalidade';
      case FeedbackCategory.accessibility:
        return 'Acessibilidade';
      case FeedbackCategory.security:
        return 'Segurança';
      case FeedbackCategory.content:
        return 'Conteúdo';
      case FeedbackCategory.integration:
        return 'Integração';
    }
  }

  String _getPriorityLabel(FeedbackPriority priority) {
    switch (priority) {
      case FeedbackPriority.low:
        return 'Baixa';
      case FeedbackPriority.medium:
        return 'Média';
      case FeedbackPriority.high:
        return 'Alta';
      case FeedbackPriority.critical:
        return 'Crítica';
    }
  }

  Color _getPriorityColor(FeedbackPriority priority) {
    switch (priority) {
      case FeedbackPriority.low:
        return AppColors.success;
      case FeedbackPriority.medium:
        return AppColors.warning;
      case FeedbackPriority.high:
        return AppColors.error;
      case FeedbackPriority.critical:
        return Colors.red.shade800;
    }
  }
}

/// Feature request voting card
class FeatureRequestCard extends StatelessWidget {
  const FeatureRequestCard({
    Key? key,
    required this.request,
    this.onVote,
    this.onComment,
  }) : super(key: key);
  final FeatureRequest request;
  final VoidCallback? onVote;
  final VoidCallback? onComment;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVoteButton(context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkGrey,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      _buildStatusChip(context),
                    ],
                  ),
                ),
              ],
            ),
            if (request.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: request.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: AppColors.lightGrey.withOpacity(0.5),
                    labelStyle: const TextStyle(fontSize: 12),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.category,
                  size: 16,
                  color: AppColors.mediumGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  request.category,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
                ),
                const Spacer(),
                if (onComment != null)
                  TextButton.icon(
                    onPressed: onComment,
                    icon: const Icon(Icons.comment, size: 16),
                    label: Text('${request.comments.length}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteButton(BuildContext context) {
    return InkWell(
      onTap: onVote,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: request.hasVoted
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: request.hasVoted ? AppColors.primary : AppColors.lightGrey,
          ),
        ),
        child: Column(
          children: [
            Icon(
              request.hasVoted
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_up,
              color: request.hasVoted
                  ? AppColors.primary
                  : AppColors.mediumGrey,
            ),
            Text(
              '${request.votesCount}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: request.hasVoted
                    ? AppColors.primary
                    : AppColors.mediumGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (request.status) {
      case RequestStatus.submitted:
        statusColor = AppColors.warning;
        statusText = 'Enviado';
        break;
      case RequestStatus.underReview:
        statusColor = AppColors.info;
        statusText = 'Em Análise';
        break;
      case RequestStatus.approved:
        statusColor = AppColors.success;
        statusText = 'Aprovado';
        break;
      case RequestStatus.inDevelopment:
        statusColor = AppColors.primary;
        statusText = 'Em Desenvolvimento';
        break;
      case RequestStatus.testing:
        statusColor = AppColors.categoryInjectable;
        statusText = 'Em Teste';
        break;
      case RequestStatus.released:
        statusColor = AppColors.success;
        statusText = 'Lançado';
        break;
      case RequestStatus.rejected:
        statusColor = AppColors.error;
        statusText = 'Rejeitado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
