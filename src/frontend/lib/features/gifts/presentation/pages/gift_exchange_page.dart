import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../models/gift.dart';
import '../../../../models/gift_type.dart';
import '../../../../models/person.dart';
import '../../../../models/relationship_type.dart';
import '../../../../providers/gift_providers.dart';

class GiftExchangePage extends ConsumerWidget {
  const GiftExchangePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final giftsAsync = ref.watch(giftsProvider);
    final peopleAsync = ref.watch(peopleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Exchanges'),
        elevation: 0,
      ),
      body: giftsAsync.when(
        data: (gifts) {
          if (gifts.isEmpty) {
            return _buildEmptyState(context);
          }
          final sortedGifts = List<Gift>.from(gifts)
            ..sort((a, b) => b.date.compareTo(a.date));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedGifts.length,
            itemBuilder: (context, index) {
              final gift = sortedGifts[index];
              final person = peopleAsync.value?.firstWhere(
                    (p) => p.id == gift.personId,
                    orElse: () => Person(
                      id: '',
                      name: 'Unknown',
                      relationship: RelationshipType.other,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );
              return _GiftCard(gift: gift, person: person);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No exchanges recorded yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging gifts to see your history',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }
}

class _GiftCard extends StatelessWidget {
  final Gift gift;
  final Person? person;

  const _GiftCard({required this.gift, required this.person});

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isGiven = gift.type == GiftType.given;
    final color = isGiven ? Colors.red : Colors.green;
    final icon = isGiven ? Icons.call_made : Icons.call_received;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          person?.name ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gift.description.isNotEmpty ? gift.description : gift.eventType,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              _formatDate(gift.date),
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
        trailing: Text(
          '\$${gift.value.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
