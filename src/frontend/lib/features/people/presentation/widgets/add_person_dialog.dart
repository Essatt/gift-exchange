import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/person.dart';
import '../../../../models/relationship_type.dart';
import '../../../../providers/gift_providers.dart';

class AddPersonDialog extends ConsumerStatefulWidget {
  const AddPersonDialog({super.key});

  @override
  ConsumerState<AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends ConsumerState<AddPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  RelationshipType _selectedRelationship = RelationshipType.friend;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Person'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
                counterText: '',
              ),
              maxLength: 50,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Relationship',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<RelationshipType>(
              initialValue: _selectedRelationship,
              decoration: const InputDecoration(),
              items: const [
                DropdownMenuItem(
                  value: RelationshipType.family,
                  child: Text('Family'),
                ),
                DropdownMenuItem(
                  value: RelationshipType.friend,
                  child: Text('Friend'),
                ),
                DropdownMenuItem(
                  value: RelationshipType.colleague,
                  child: Text('Colleague'),
                ),
                DropdownMenuItem(
                  value: RelationshipType.other,
                  child: Text('Other'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRelationship = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isSaving = true);
                    final service = ref.read(giftServiceProvider);
                    final person = Person(
                      id: '',
                      name: _nameController.text.trim(),
                      relationship: _selectedRelationship,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    await service.addPerson(person);
                    ref.read(refreshSignalProvider.notifier).state++;
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}
