import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/gift.dart';
import '../../../../models/gift_type.dart';
import '../../../../providers/gift_providers.dart';

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
  String selectedEventType = 'Birthday';
  DateTime selectedDate = DateTime.now();
  bool _isSaving = false;
  static const List<String> eventTypes = [
    'Birthday',
    'Wedding',
    'Housewarming',
    'Holiday',
    'Anniversary',
    'Custom',
  ];

  static const List<int> quickValues = [10, 25, 50, 100, 200];

  @override
  void dispose() {
    descriptionController.dispose();
    valueController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final gift = Gift(
        id: '',
        personId: widget.personId,
        type: selectedType == 'Given' ? GiftType.given : GiftType.received,
        value: double.parse(valueController.text),
        description: descriptionController.text.trim(),
        eventType: selectedEventType,
        date: selectedDate,
        createdAt: DateTime.now(),
      );

      final service = ref.read(giftServiceProvider);
      await service.addGift(gift);
      ref.read(refreshSignalProvider.notifier).state++;

      if (mounted) {
        Navigator.of(context).pop(gift);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  initialValue: selectedEventType,
                  decoration: const InputDecoration(
                    labelText: 'Event Type',
                    border: OutlineInputBorder(),
                  ),
                  items: eventTypes
                      .map(
                        (String type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedEventType = newValue;
                      });
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Please select an event type' : null,
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
                      border: OutlineInputBorder(),
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
                    border: OutlineInputBorder(),
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
                    border: OutlineInputBorder(),
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
