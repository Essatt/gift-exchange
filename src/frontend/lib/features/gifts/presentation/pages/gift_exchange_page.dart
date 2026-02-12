import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../models/gift.dart';
import '../../../../models/gift_type.dart';
import '../../../../models/person.dart';
import '../../../../providers/gift_providers.dart';
import '../../../people/presentation/widgets/add_gift_dialog.dart';

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
          return _GiftCard(
            gift: gift,
            person: person,
            onEdit: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (_) =>
                    AddGiftDialog(personId: gift.personId, existingGift: gift),
              );
              if (result == true) {
                ref.read(refreshSignalProvider.notifier).state++;
              }
            },
            onDelete: () async {
              final confirmed = await _confirmDelete(context);
              if (confirmed) {
                try {
                  final service = ref.read(giftServiceProvider);
                  await service.deleteGift(gift.id);
                  ref.read(refreshSignalProvider.notifier).state++;
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete: $e')),
                    );
                  }
                }
              }
            },
          );
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

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Gift?'),
            content: const Text('Are you sure you want to delete this gift?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _GiftCard extends StatelessWidget {
  final Gift gift;
  final Person? person;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GiftCard({
    required this.gift,
    required this.person,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isGiven = gift.type == GiftType.given;
    final colors = Theme.of(context).colorScheme;
    final color = isGiven ? colors.error : colors.tertiary;
    final icon = isGiven ? Icons.call_made : Icons.call_received;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person?.name ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      gift.description.isNotEmpty
                          ? gift.description
                          : gift.eventType,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${gift.eventType} \u2022 ${DateFormat.yMMMd().format(gift.date)}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${gift.value.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    isGiven ? 'Given' : 'Received',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                padding: EdgeInsets.zero,
                iconSize: 20,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
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
            ],
          ),
        ),
      ),
    );
  }
}
