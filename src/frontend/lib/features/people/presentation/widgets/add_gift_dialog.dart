import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../models/gift.dart';
import '../../../../models/gift_type.dart';
import '../../../../providers/gift_providers.dart';

class AddGiftDialog extends ConsumerStatefulWidget {
  final String personId;
  final Gift? existingGift;

  const AddGiftDialog({super.key, required this.personId, this.existingGift});

  @override
  ConsumerState<AddGiftDialog> createState() => _AddGiftDialogState();
}

class _AddGiftDialogState extends ConsumerState<AddGiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController valueController = TextEditingController();

  String selectedType = 'Given';
  String? _selectedEventType;
  DateTime selectedDate = DateTime.now();
  bool _isSaving = false;

  bool get _isEditing => widget.existingGift != null;

  static const List<int> quickValues = [10, 25, 50, 100, 200];

  @override
  void initState() {
    super.initState();
    final gift = widget.existingGift;
    if (gift != null) {
      descriptionController.text = gift.description;
      valueController.text = gift.value.toString();
      selectedType = gift.type == GiftType.given ? 'Given' : 'Received';
      _selectedEventType = gift.eventType;
      selectedDate = gift.date;
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    valueController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final service = ref.read(giftServiceProvider);
      final giftType = selectedType == 'Given'
          ? GiftType.given
          : GiftType.received;
      final value = double.tryParse(valueController.text) ?? 0;
      final description = descriptionController.text.trim();
      final eventType = _selectedEventType ?? 'Birthday';

      if (_isEditing) {
        final updated = widget.existingGift!.copyWith(
          type: giftType,
          value: value,
          description: description,
          eventType: eventType,
          date: selectedDate,
        );
        await service.updateGift(updated);
      } else {
        final gift = Gift(
          id: '',
          personId: widget.personId,
          type: giftType,
          value: value,
          description: description,
          eventType: eventType,
          date: selectedDate,
          createdAt: DateTime.now(),
        );
        await service.addGift(gift);
      }

      ref.read(refreshSignalProvider.notifier).state++;

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${_isEditing ? 'update' : 'save'} gift: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showAddLabelDialog() async {
    final controller = TextEditingController();
    final newLabel = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Event Label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 50,
          decoration: const InputDecoration(
            hintText: 'e.g., Graduation, Baby Shower',
            prefixIcon: Icon(Icons.label_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx, text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newLabel != null && newLabel.isNotEmpty) {
      try {
        final service = ref.read(giftServiceProvider);
        await service.addCustomLabel(newLabel);
        ref.read(refreshSignalProvider.notifier).state++;
        setState(() {
          _selectedEventType = newLabel;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to add label: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final eventLabels = ref.watch(eventLabelsProvider);

    final effectiveEventType =
        (_selectedEventType != null && eventLabels.contains(_selectedEventType))
        ? _selectedEventType!
        : (eventLabels.isNotEmpty ? eventLabels.first : 'Birthday');

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Gift' : 'Add Gift'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Direction toggle
                Row(
                  children: [
                    Expanded(
                      child: _DirectionCard(
                        label: 'Given',
                        icon: Icons.call_made,
                        color: colors.error,
                        isSelected: selectedType == 'Given',
                        onTap: () => setState(() => selectedType = 'Given'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DirectionCard(
                        label: 'Received',
                        icon: Icons.call_received,
                        color: colors.tertiary,
                        isSelected: selectedType == 'Received',
                        onTap: () => setState(() => selectedType = 'Received'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Event type chips
                Text(
                  'Event',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...eventLabels.map((label) {
                      final isSelected = effectiveEventType == label;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedEventType = label);
                          }
                        },
                        selectedColor: colors.secondaryContainer,
                        showCheckmark: false,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }),
                    ActionChip(
                      avatar: Icon(Icons.add, size: 16, color: colors.primary),
                      label: Text(
                        'New',
                        style: TextStyle(color: colors.primary),
                      ),
                      onPressed: _showAddLabelDialog,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Date picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      DateFormat.yMMMd().format(selectedDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g., Watch, Cash Gift',
                    prefixIcon: Icon(Icons.description_outlined),
                    counterText: '',
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Value
                TextFormField(
                  controller: valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Value',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a value';
                    }
                    final parsedValue = double.tryParse(value);
                    if (parsedValue == null || parsedValue <= 0) {
                      return 'Please enter a valid positive number';
                    }
                    if (parsedValue > 999999.99) {
                      return 'Value cannot exceed \$999,999.99';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Quick values
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickValues
                      .map(
                        (val) => ActionChip(
                          label: Text('\$$val'),
                          onPressed: () {
                            valueController.text = val.toString();
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _handleSave,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check, size: 18),
          label: const Text('Save'),
        ),
      ],
    );
  }
}

class _DirectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _DirectionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(20) : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : colors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : colors.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : colors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
