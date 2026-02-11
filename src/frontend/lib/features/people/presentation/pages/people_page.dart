import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/person.dart';
import '../../../../models/relationship_type.dart';
import '../../../../providers/gift_providers.dart';
import '../widgets/add_person_dialog.dart';
import 'person_detail_page.dart';

class PeoplePage extends ConsumerWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('People'), elevation: 0),
      body: people.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: people.length,
              itemBuilder: (context, index) {
                final person = people[index];
                return _PersonCard(
                  person: person,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PersonDetailPage(person: person),
                      ),
                    );
                  },
                  onDelete: () => _confirmDeletePerson(context, ref, person),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(context: context, builder: (_) => const AddPersonDialog());
        },
        label: const Text('Add Person'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: colors.onSurfaceVariant),
          const SizedBox(height: 24),
          Text(
            'No people added yet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Person" to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePerson(
    BuildContext context,
    WidgetRef ref,
    Person person,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Person?'),
        content: Text(
          'This will delete "${person.name}" and ALL their gifts. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(giftServiceProvider);
      await service.deletePerson(person.id);
      ref.read(refreshSignalProvider.notifier).state++;

      messenger.showSnackBar(
        SnackBar(
          content: Text('${person.name} deleted'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PersonCard({
    required this.person,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRelationshipColor(person.relationship);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(25),
          child: Text(
            person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Text(
          person.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _getRelationshipLabel(person.relationship),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getRelationshipColor(RelationshipType type) {
    switch (type) {
      case RelationshipType.family:
        return Colors.purple;
      case RelationshipType.friend:
        return Colors.blue;
      case RelationshipType.colleague:
        return Colors.orange;
      case RelationshipType.other:
        return Colors.grey;
    }
  }

  String _getRelationshipLabel(RelationshipType type) {
    switch (type) {
      case RelationshipType.family:
        return 'Family';
      case RelationshipType.friend:
        return 'Friend';
      case RelationshipType.colleague:
        return 'Colleague';
      case RelationshipType.other:
        return 'Other';
    }
  }
}
