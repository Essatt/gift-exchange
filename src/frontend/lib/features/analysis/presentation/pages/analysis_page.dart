import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/gift.dart';
import '../../../../models/gift_type.dart';
import '../../../../models/person.dart';
import '../../../../providers/gift_providers.dart';
import '_top_spenders.dart';

class AnalysisPage extends ConsumerStatefulWidget {
  const AnalysisPage({super.key});

  @override
  ConsumerState<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends ConsumerState<AnalysisPage> {
  String _selectedTimeframe = 'overall';

  void _onTimeframeChanged(String value) {
    setState(() {
      _selectedTimeframe = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gifts = ref.watch(giftsProvider);
    final peopleMap = ref.watch(peopleMapProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis'), elevation: 0),
      body: gifts.isEmpty
          ? _buildEmptyState(context)
          : _buildContent(context, gifts, peopleMap),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Gift> gifts,
    Map<String, Person> peopleMap,
  ) {
    final filteredGifts = _filterGiftsByTimeframe(gifts);

    final totalSpent = filteredGifts
        .where((g) => g.type == GiftType.given)
        .fold<double>(0, (sum, g) => sum + g.value);
    final totalReceived = filteredGifts
        .where((g) => g.type == GiftType.received)
        .fold<double>(0, (sum, g) => sum + g.value);

    final spendingByPerson = _calculateSpendingByPerson(
      filteredGifts,
      peopleMap,
    );

    final timeframeLabel = switch (_selectedTimeframe) {
      'yearly' => "This Year's Spending",
      'monthly' => "This Month's Spending",
      _ => 'Overall Spending',
    };

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(refreshSignalProvider.notifier).state++;
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverallStats(
            context,
            totalSpent,
            totalReceived,
            timeframeLabel,
          ),
          const SizedBox(height: 16),
          _TimeframeToggle(
            selected: _selectedTimeframe,
            onSelectionChanged: _onTimeframeChanged,
          ),
          const SizedBox(height: 16),
          TopSpenders(spendingByPerson: spendingByPerson),
        ],
      ),
    );
  }

  List<Gift> _filterGiftsByTimeframe(List<Gift> gifts) {
    final now = DateTime.now();

    switch (_selectedTimeframe) {
      case 'yearly':
        return gifts.where((g) => g.date.year == now.year).toList();
      case 'monthly':
        return gifts
            .where((g) => g.date.year == now.year && g.date.month == now.month)
            .toList();
      default:
        return gifts;
    }
  }

  Map<String, double> _calculateSpendingByPerson(
    List<Gift> gifts,
    Map<String, Person> peopleMap,
  ) {
    final Map<String, double> spending = {};

    for (final gift in gifts) {
      if (gift.type == GiftType.given) {
        final name = peopleMap[gift.personId]?.name ?? 'Unknown';
        spending[name] = (spending[name] ?? 0) + gift.value;
      }
    }

    return spending;
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: colors.onSurfaceVariant),
          const SizedBox(height: 24),
          Text(
            'No data to analyze',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging gifts to see your spending',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats(
    BuildContext context,
    double totalSpent,
    double totalReceived,
    String title,
  ) {
    final colors = Theme.of(context).colorScheme;
    final netBalance = totalReceived - totalSpent;
    final balanceColor = netBalance == 0
        ? colors.outline
        : (netBalance > 0 ? colors.tertiary : colors.error);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _OverallStatItem(
                  label: 'Total Given',
                  value: '\$${totalSpent.toStringAsFixed(2)}',
                  color: colors.error,
                ),
                _OverallStatItem(
                  label: 'Total Received',
                  value: '\$${totalReceived.toStringAsFixed(2)}',
                  color: colors.tertiary,
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
                  '\$${netBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balanceColor,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OverallStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
      ],
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
          label: Text('Overall'),
          icon: Icon(Icons.all_inclusive),
        ),
        ButtonSegment(
          value: 'yearly',
          label: Text('Yearly'),
          icon: Icon(Icons.calendar_today),
        ),
        ButtonSegment(
          value: 'monthly',
          label: Text('Monthly'),
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
