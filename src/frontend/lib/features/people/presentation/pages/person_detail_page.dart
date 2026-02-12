import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../models/gift.dart';
import '../../../../models/gift_type.dart';
import '../../../../models/person.dart';
import '../../../../providers/gift_providers.dart';
import '../widgets/add_gift_dialog.dart';
import '../widgets/add_person_dialog.dart';

class PersonDetailPage extends ConsumerStatefulWidget {
  final Person person;

  const PersonDetailPage({super.key, required this.person});

  @override
  ConsumerState<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends ConsumerState<PersonDetailPage> {
  String _selectedTimeframe = 'overall';
  String? _expandedEvent;

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

  Future<void> _editPerson() async {
    final service = ref.read(giftServiceProvider);
    final current = service.getPerson(widget.person.id) ?? widget.person;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AddPersonDialog(existingPerson: current),
    );
    if (result == true) {
      ref.read(refreshSignalProvider.notifier).state++;
    }
  }

  Future<void> _editGift(Gift gift) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) =>
          AddGiftDialog(personId: widget.person.id, existingGift: gift),
    );
    if (result == true) {
      ref.read(refreshSignalProvider.notifier).state++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(filteredPersonStatsProvider(widget.person.id));
    final gifts = ref.watch(filteredGiftsByPersonProvider(widget.person.id));
    // Get live person data for the appbar title
    final livePerson = ref
        .watch(peopleProvider)
        .where((p) => p.id == widget.person.id);
    final personName = livePerson.isNotEmpty
        ? livePerson.first.name
        : widget.person.name;

    // Group gifts by event type
    final eventGroups = <String, List<Gift>>{};
    for (final gift in gifts) {
      eventGroups.putIfAbsent(gift.eventType, () => []).add(gift);
    }
    // Sort events by total volume descending
    final sortedEvents = eventGroups.entries.toList()
      ..sort((a, b) {
        final aTotal = a.value.fold<double>(0, (s, g) => s + g.value);
        final bTotal = b.value.fold<double>(0, (s, g) => s + g.value);
        return bTotal.compareTo(aTotal);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(personName),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit person',
            onPressed: _editPerson,
          ),
        ],
      ),
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
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (gifts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Events',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = sortedEvents[index];
                    return _EventCard(
                      eventType: entry.key,
                      gifts: entry.value,
                      isExpanded: _expandedEvent == entry.key,
                      onTap: () {
                        setState(() {
                          _expandedEvent = _expandedEvent == entry.key
                              ? null
                              : entry.key;
                        });
                      },
                      onEditGift: _editGift,
                      onDeleteGift: (giftId) async {
                        final confirmed = await _confirmDismiss(context);
                        if (confirmed) {
                          try {
                            final service = ref.read(giftServiceProvider);
                            await service.deleteGift(giftId);
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
                  }, childCount: sortedEvents.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
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
            'Tap + to add a gift',
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

// ---------------------------------------------------------------------------
// Event card with expandable gift comparison
// ---------------------------------------------------------------------------

class _EventCard extends StatelessWidget {
  final String eventType;
  final List<Gift> gifts;
  final bool isExpanded;
  final VoidCallback onTap;
  final void Function(Gift gift) onEditGift;
  final Future<void> Function(String giftId) onDeleteGift;

  const _EventCard({
    required this.eventType,
    required this.gifts,
    required this.isExpanded,
    required this.onTap,
    required this.onEditGift,
    required this.onDeleteGift,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final givenGifts = gifts.where((g) => g.type == GiftType.given).toList();
    final receivedGifts = gifts
        .where((g) => g.type == GiftType.received)
        .toList();
    final totalGiven = givenGifts.fold<double>(0, (s, g) => s + g.value);
    final totalReceived = receivedGifts.fold<double>(0, (s, g) => s + g.value);
    final net = totalReceived - totalGiven;
    final netColor = net == 0
        ? colors.outline
        : (net > 0 ? colors.tertiary : colors.error);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header — always visible
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _eventIcon(eventType),
                            color: colors.onPrimaryContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                eventType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${gifts.length} gift${gifts.length == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Mini comparison bar
                    Row(
                      children: [
                        _MiniStat(
                          icon: Icons.call_made,
                          label: 'Given',
                          value: totalGiven,
                          color: colors.error,
                        ),
                        const SizedBox(width: 16),
                        _MiniStat(
                          icon: Icons.call_received,
                          label: 'Received',
                          value: totalReceived,
                          color: colors.tertiary,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: netColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Net \$${net.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: netColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Expanded gift list
            if (isExpanded) ...[
              Divider(height: 1, color: colors.outlineVariant),
              // Given section
              if (givenGifts.isNotEmpty) ...[
                _SectionHeader(label: 'You Gave', color: colors.error),
                ...givenGifts.map(
                  (g) => _GiftRow(
                    gift: g,
                    onEdit: () => onEditGift(g),
                    onDelete: () => onDeleteGift(g.id),
                  ),
                ),
              ],
              // Received section
              if (receivedGifts.isNotEmpty) ...[
                _SectionHeader(label: 'You Received', color: colors.tertiary),
                ...receivedGifts.map(
                  (g) => _GiftRow(
                    gift: g,
                    onEdit: () => onEditGift(g),
                    onDelete: () => onDeleteGift(g.id),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  IconData _eventIcon(String event) {
    final lower = event.toLowerCase();
    if (lower.contains('birthday')) return Icons.cake_outlined;
    if (lower.contains('wedding')) return Icons.favorite_outline;
    if (lower.contains('holiday') || lower.contains('christmas')) {
      return Icons.park_outlined;
    }
    if (lower.contains('anniversary')) return Icons.celebration_outlined;
    if (lower.contains('housewarming') || lower.contains('house')) {
      return Icons.home_outlined;
    }
    if (lower.contains('graduation')) return Icons.school_outlined;
    if (lower.contains('baby')) return Icons.child_care_outlined;
    return Icons.card_giftcard_outlined;
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '\$${value.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftRow extends StatelessWidget {
  final Gift gift;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GiftRow({
    required this.gift,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isGiven = gift.type == GiftType.given;
    final color = isGiven ? colors.error : colors.tertiary;

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gift.description.isNotEmpty
                        ? gift.description
                        : gift.eventType,
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    DateFormat.yMMMd().format(gift.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '\$${gift.value.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit_outlined,
              size: 14,
              color: colors.onSurfaceVariant.withAlpha(120),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close,
                size: 16,
                color: colors.onSurfaceVariant.withAlpha(120),
              ),
            ),
          ],
        ),
      ),
    );
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
