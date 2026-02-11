import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/person.dart';
import '../../../../models/relationship_type.dart';
import '../../../../providers/gift_providers.dart';
import '../../../../services/gift_service.dart';
import '../widgets/add_person_dialog.dart';
import 'person_detail_page.dart';

class PeoplePage extends ConsumerWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(peopleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        elevation: 0,
      ),
      body: peopleAsync.when(
        data: (people) {
          if (people.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
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
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddPersonDialog(),
          );
        },
        label: const Text('Add Person'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No people added yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first person',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback onTap;

  const _PersonCard({
    required this.person,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRelationshipColor(person.relationship);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteConfirmation(context, person),
              color: Colors.grey[600],
              tooltip: 'Delete person',
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Person person) {
    showDialog<bool>(
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        final service = GiftService();
        await service.deletePerson(person.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${person.name} deleted'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
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
