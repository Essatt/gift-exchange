import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/person.dart';
import '../../../../models/relationship_type.dart';
import '../../../../providers/gift_providers.dart';

class AddPersonDialog extends ConsumerStatefulWidget {
  final Person? existingPerson;

  const AddPersonDialog({super.key, this.existingPerson});

  @override
  ConsumerState<AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends ConsumerState<AddPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _customRelController = TextEditingController();
  RelationshipType _selectedRelationship = RelationshipType.friend;
  bool _isSaving = false;

  bool get _isEditing => widget.existingPerson != null;

  static const _relationshipOptions = [
    (type: RelationshipType.family, label: 'Family', icon: Icons.home_rounded),
    (type: RelationshipType.friend, label: 'Friend', icon: Icons.group_rounded),
    (
      type: RelationshipType.romanticPartner,
      label: 'Partner',
      icon: Icons.favorite_rounded,
    ),
    (
      type: RelationshipType.colleague,
      label: 'Colleague',
      icon: Icons.work_rounded,
    ),
    (type: RelationshipType.other, label: 'Other', icon: Icons.edit_rounded),
  ];

  @override
  void initState() {
    super.initState();
    final person = widget.existingPerson;
    if (person != null) {
      _nameController.text = person.name;
      _selectedRelationship = person.relationship;
      _customRelController.text = person.customRelationship;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customRelController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final service = ref.read(giftServiceProvider);
      final customRel = _selectedRelationship == RelationshipType.other
          ? _customRelController.text.trim()
          : '';

      if (_isEditing) {
        final updated = widget.existingPerson!.copyWith(
          name: _nameController.text.trim(),
          relationship: _selectedRelationship,
          customRelationship: customRel,
        );
        await service.updatePerson(updated);
      } else {
        final person = Person(
          id: '',
          name: _nameController.text.trim(),
          relationship: _selectedRelationship,
          customRelationship: customRel,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await service.addPerson(person);
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
              'Failed to ${_isEditing ? 'update' : 'add'} person: $e',
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Person' : 'Add Person'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                    counterText: '',
                  ),
                  maxLength: 50,
                  textCapitalization: TextCapitalization.words,
                  autofocus: !_isEditing,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Relationship',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _relationshipOptions.map((option) {
                    final isSelected = _selectedRelationship == option.type;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            option.icon,
                            size: 16,
                            color: isSelected
                                ? colors.onSecondaryContainer
                                : colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(option.label),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedRelationship = option.type;
                          });
                        }
                      },
                      selectedColor: colors.secondaryContainer,
                      showCheckmark: false,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                if (_selectedRelationship == RelationshipType.other) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customRelController,
                    decoration: const InputDecoration(
                      labelText: 'Custom relationship',
                      hintText: 'e.g., Neighbor, Coach, Mentor',
                      prefixIcon: Icon(Icons.label_outline),
                      counterText: '',
                    ),
                    maxLength: 30,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (_selectedRelationship == RelationshipType.other &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter a custom relationship';
                      }
                      return null;
                    },
                  ),
                ],
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
              : Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
