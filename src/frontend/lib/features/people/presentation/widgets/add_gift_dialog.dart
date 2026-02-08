import 'package:flutter/material.dart';
import '../../../../models/gift.dart';
import '../../../../models/gift_type.dart';

class AddGiftDialog extends StatefulWidget {
  final String personId;

  const AddGiftDialog({super.key, required this.personId});

  @override
  State<AddGiftDialog> createState() => _AddGiftDialogState();
}

class _AddGiftDialogState extends State<AddGiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();

  GiftType _selectedType = GiftType.given;
  String _selectedEventType = 'Birthday';
  final _eventTypes = [
    'Birthday',
    'Wedding',
    'Housewarming',
    'Holiday',
    'Anniversary',
    'Custom',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Gift'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gift Type (Given/Received)
              SegmentedButton<GiftType>(
                segments: const [
                  ButtonSegment<GiftType>(
                    value: GiftType.given,
                    label: 'Given',
                    icon: Icon(Icons.call_made),
                  ),
                  ButtonSegment<GiftType>(
                    value: GiftType.received,
                    label: 'Received',
                    icon: Icon(Icons.call_received),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<GiftType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Watch, Cash Gift',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value!.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Value
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Value (\$)',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value!.trim().isEmpty) {
                    return 'Please enter a value';
                  }
                  final numValue = double.tryParse(value!);
                  if (numValue == null || numValue! <= 0) {
                    return 'Please enter a positive value';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Event Type
              const Text(
                'Event Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _eventTypes.map((type) {
                  final isSelected = _selectedEventType == type;
                  return ChoiceChip(
                    label: type,
                    selected: isSelected,
                    onSelected: () {
                      setState(() {
                        _selectedEventType = type;
                      });
                    },
                  );
                }).toList(),
              ),

              // Quick Value Buttons
              const SizedBox(height: 16),
              const Text(
                'Quick Values',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [10, 25, 50, 100, 200].map((value) {
                  return OutlinedButton(
                    onPressed: () {
                      _valueController.text = value.toString();
                    },
                    child: Text('\$$value'),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'personId': widget.personId,
                'type': _selectedType,
                'description': _descriptionController.text.trim(),
                'value': double.parse(_valueController.text),
                'eventType': _selectedEventType,
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
