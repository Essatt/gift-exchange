import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../models/gift.dart';
import '../../../../models/gift_type.dart';
import '../../../../models/person.dart';
import '../../../../providers/gift_providers.dart';

class GiftExchangePage extends ConsumerWidget {
  const GiftExchangePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedGifts = ref.watch(sortedGiftsProvider);
    final peopleMap = ref.watch(peopleMapProvider);

    if (sortedGifts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recent Exchanges'), elevation: 0),
        body: _buildEmptyState(context),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Recent Exchanges'), elevation: 0),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedGifts.length,
        itemBuilder: (context, index) {
          final gift = sortedGifts[index];
          final person = peopleMap[gift.personId];
          return _GiftCard(gift: gift, person: person);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: colors.onSurfaceVariant),
          const SizedBox(height: 24),
          Text(
            'No exchanges recorded yet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging gifts to see your history',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
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
    final colors = Theme.of(context).colorScheme;
    final color = isGiven ? colors.error : colors.tertiary;
    final icon = isGiven ? Icons.call_made : Icons.call_received;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
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
