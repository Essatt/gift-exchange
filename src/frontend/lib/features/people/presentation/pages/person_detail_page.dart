import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/gift.dart';
import '../../../../models/gift_type.dart';
import '../../../../models/person.dart';
import '../../../../providers/gift_providers.dart';
import '../widgets/add_gift_dialog.dart';

class PersonDetailPage extends ConsumerWidget {
  final Person person;

  const PersonDetailPage({super.key, required this.person});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(personStatsProvider(person.id));
    final gifts = ref.watch(giftsByPersonProvider(person.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(personStatsProvider(person.id));
          ref.invalidate(giftsByPersonProvider(person.id));
        },
        child: Column(
          children: [
            _buildBalanceCard(context, stats),
            Expanded(
              child: gifts.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: gifts.length,
                      itemBuilder: (context, index) {
                        final gift = gifts[index];
                        return _GiftItem(gift: gift, onDelete: () => _showDeleteConfirmation(context, ref, gift));
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddGiftDialog(personId: person.id),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, PersonStats stats) {
    final isPositive = stats.netBalance >= 0;
    final balanceColor = isPositive ? Colors.green : Colors.red;
    final balanceLabel = isPositive ? 'Up' : 'Down';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net Balance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Given',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${stats.totalGiven.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Received',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${stats.totalReceived.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Net Balance',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                Text(
                  '\$${stats.netBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balanceColor,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: balanceColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    balanceLabel,
                    style: TextStyle(
                      color: balanceColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No gifts recorded yet',
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

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Gift gift) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Gift?'),
        content: Text('Are you sure you want to delete "${gift.description}"?'),
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
        final service = ref.read(giftServiceProvider);
        await service.deleteGift(gift.id);
        ref.invalidate(giftsProvider);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Gift deleted'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }
}

class _GiftItem extends StatelessWidget {
  final Gift gift;
  final VoidCallback? onDelete;

  const _GiftItem({required this.gift, this.onDelete});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${(difference.inDays / 7).floor()} weeks ago';
  }

  @override
  Widget build(BuildContext context) {
    final isGiven = gift.type == GiftType.given;
    final color = isGiven ? Colors.red : Colors.green;
    final icon = isGiven ? Icons.call_made : Icons.call_received;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
          gift.description.isNotEmpty ? gift.description : gift.eventType,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(gift.date),
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                color: Colors.grey[600],
                tooltip: 'Delete gift',
              )
            : null,
      ),
    );
  }
}
