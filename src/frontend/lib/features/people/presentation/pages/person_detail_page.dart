import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../models/gift.dart';
import '../../../../models/gift_type.dart';
import '../../../../models/person.dart';
import '../../../../providers/gift_providers.dart';
import '../widgets/add_gift_dialog.dart';

class PersonDetailPage extends ConsumerStatefulWidget {
  final Person person;

  const PersonDetailPage({super.key, required this.person});

  @override
  ConsumerState<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends ConsumerState<PersonDetailPage> {
  String _selectedTimeframe = 'overall';

  void _onTimeframeChanged(String value) {
    setState(() {
      _selectedTimeframe = value;
    });

    final now = DateTime.now();
    final TimeFilter filter = switch (value) {
      'yearly' => TimeFilter.forYear(now.year),
      'monthly' => TimeFilter.forMonth(year: now.year, month: now.month),
      _ => TimeFilter.allTime,
    };
    ref.read(personDetailTimeFilterProvider(widget.person.id).notifier).state =
        filter;
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(filteredPersonStatsProvider(widget.person.id));
    final gifts = ref.watch(filteredGiftsByPersonProvider(widget.person.id));

    return Scaffold(
      appBar: AppBar(title: Text(widget.person.name), elevation: 0),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(refreshSignalProvider.notifier).state++;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildBalanceCard(context, stats)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _TimeframeToggle(
                  selected: _selectedTimeframe,
                  onSelectionChanged: _onTimeframeChanged,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            if (gifts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final gift = gifts[index];
                    return Dismissible(
                      key: ValueKey(gift.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        final confirmed = await _confirmDismiss(context);
                        if (confirmed) {
                          try {
                            final service = ref.read(giftServiceProvider);
                            await service.deleteGift(gift.id);
                            ref.read(refreshSignalProvider.notifier).state++;
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete gift: $e'),
                                ),
                              );
                            }
                            return false;
                          }
                        }
                        return confirmed;
                      },
                      onDismissed: (_) {},
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.onError,
                        ),
                      ),
                      child: _GiftItem(gift: gift),
                    );
                  }, childCount: gifts.length),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddGiftDialog(personId: widget.person.id),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, PersonStats stats) {
    final colors = Theme.of(context).colorScheme;
    final isPositive = stats.netBalance >= 0;
    final balanceColor = stats.netBalance == 0
        ? colors.outline
        : (isPositive ? colors.tertiary : colors.error);
    final balanceLabel = stats.netBalance == 0
        ? 'Balanced'
        : (isPositive ? 'You received more' : 'You gave more');

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${stats.totalGiven.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.error,
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${stats.totalReceived.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.tertiary,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 80,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(
            'No gifts recorded yet',
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

  Future<bool> _confirmDismiss(BuildContext context) async {
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

class _TimeframeToggle extends StatelessWidget {
  final String selected;
  final Function(String) onSelectionChanged;

  const _TimeframeToggle({
    required this.selected,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'overall',
          label: Text('All'),
          icon: Icon(Icons.all_inclusive),
        ),
        ButtonSegment(
          value: 'yearly',
          label: Text('Year'),
          icon: Icon(Icons.calendar_today),
        ),
        ButtonSegment(
          value: 'monthly',
          label: Text('Month'),
          icon: Icon(Icons.calendar_month),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (Set<String> newSelection) {
        onSelectionChanged(newSelection.first);
      },
    );
  }
}

class _GiftItem extends StatelessWidget {
  final Gift gift;

  const _GiftItem({required this.gift});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.isNegative) return DateFormat.yMMMd().format(date);
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
    return DateFormat.yMMMd().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isGiven = gift.type == GiftType.given;
    final colors = Theme.of(context).colorScheme;
    final color = isGiven ? colors.error : colors.tertiary;
    final icon = isGiven ? Icons.call_made : Icons.call_received;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
          gift.description.isNotEmpty ? gift.description : gift.eventType,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _formatDate(gift.date),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
