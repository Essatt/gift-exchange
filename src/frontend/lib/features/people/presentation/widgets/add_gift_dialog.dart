import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/gift.dart';
import '../../../../models/gift_type.dart';
import '../../../../providers/gift_providers.dart';

const String _addNewLabelSentinel = '__add_new_label__';

class AddGiftDialog extends ConsumerStatefulWidget {
  final String personId;

  const AddGiftDialog({super.key, required this.personId});

  @override
  ConsumerState<AddGiftDialog> createState() => _AddGiftDialogState();
}

class _AddGiftDialogState extends ConsumerState<AddGiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController valueController = TextEditingController();

  static const Map<String, IconData> typeSegments = {
    'Given': Icons.call_made,
    'Received': Icons.call_received,
  };

  String selectedType = 'Given';
  String? _selectedEventType;
  DateTime selectedDate = DateTime.now();
  bool _isSaving = false;

  static const List<int> quickValues = [10, 25, 50, 100, 200];

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
      final gift = Gift(
        id: '',
        personId: widget.personId,
        type: selectedType == 'Given' ? GiftType.given : GiftType.received,
        value: double.tryParse(valueController.text) ?? 0,
        description: descriptionController.text.trim(),
        eventType: _selectedEventType ?? 'Birthday',
        date: selectedDate,
        createdAt: DateTime.now(),
      );

      final service = ref.read(giftServiceProvider);
      await service.addGift(gift);
      ref.read(refreshSignalProvider.notifier).state++;

      if (mounted) {
        Navigator.of(context).pop(gift);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save gift: $e')));
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
    final eventLabels = ref.watch(eventLabelsProvider);

    // Ensure _selectedEventType is valid without mutating state in build
    final effectiveEventType =
        (_selectedEventType != null && eventLabels.contains(_selectedEventType))
        ? _selectedEventType
        : (eventLabels.isNotEmpty ? eventLabels.first : 'Birthday');

    return AlertDialog(
      title: const Text('Add Gift'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: typeSegments.entries
                      .map(
                        (entry) => ButtonSegment<String>(
                          value: entry.key,
                          label: Text(entry.key),
                          icon: Icon(entry.value),
                        ),
                      )
                      .toList(),
                  selected: {selectedType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      selectedType = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: effectiveEventType,
                  decoration: const InputDecoration(labelText: 'Event Type'),
                  items: [
                    ...eventLabels.map(
                      (String type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: _addNewLabelSentinel,
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add new label...',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue == _addNewLabelSentinel) {
                      _showAddLabelDialog();
                      return;
                    }
                    if (newValue != null) {
                      setState(() {
                        _selectedEventType = newValue;
                      });
                    }
                  },
                  validator: (value) =>
                      value == null || value == _addNewLabelSentinel
                      ? 'Please select an event type'
                      : null,
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g., Watch, Cash Gift',
                  ),
                  maxLength: 100,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required maxLength,
                        required isFocused,
                      }) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('$currentLength/$maxLength'),
                        );
                      },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Value',
                    prefixText: r'$',
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
                const Text(
                  'Quick Values',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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
                          visualDensity: VisualDensity.adaptivePlatformDensity,
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
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
