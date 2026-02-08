import 'package:flutter/material.dart';
import '../../../models/relationship_type.dart';
import '../../../models/person.dart';
import '../../../providers/gift_providers.dart';

class AddPersonDialog extends ConsumerStatefulWidget {
  const AddPersonDialog({super.key});

  @override
  ConsumerState<AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends ConsumerState<AddPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  RelationshipType _selectedRelationship = RelationshipType.friend;

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
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value!.trim().isEmpty) {
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
              value: _selectedRelationship,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
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
                    _selectedRelationship = value!;
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final service = ref.read(giftServiceProvider);
              final person = Person(
                id: '',
                name: _nameController.text.trim(),
                relationship: _selectedRelationship,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              service.addPerson(person);
              ref.invalidate(peopleProvider);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
