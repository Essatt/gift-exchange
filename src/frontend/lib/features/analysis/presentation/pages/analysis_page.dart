import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/gift.dart';
import '../../../../models/gift_type.dart';
import '../../../../models/person.dart';
import '../../../../models/relationship_type.dart';
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
    final giftsAsync = ref.watch(giftsProvider);
    final peopleAsync = ref.watch(peopleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        elevation: 0,
      ),
      body: giftsAsync.when(
        data: (gifts) {
          if (gifts.isEmpty) {
            return _buildEmptyState(context);
          }

          // Filter gifts based on timeframe
          final filteredGifts = _filterGiftsByTimeframe(gifts);

          final totalSpent = filteredGifts
              .where((g) => g.type == GiftType.given)
              .fold<double>(0, (sum, g) => sum + g.value);
          final totalReceived = filteredGifts
              .where((g) => g.type == GiftType.received)
              .fold<double>(0, (sum, g) => sum + g.value);

          final spendingByPerson = _calculateSpendingByPerson(filteredGifts, peopleAsync.value ?? []);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(giftsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOverallStats(context, totalSpent, totalReceived),
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
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  List<Gift> _filterGiftsByTimeframe(List<Gift> gifts) {
    final now = DateTime.now();

    switch (_selectedTimeframe) {
      case 'overall':
        return gifts;
      case 'yearly':
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
        return gifts
            .where((g) => g.date.isAfter(startOfYear) && g.date.isBefore(endOfYear))
            .toList();
      case 'monthly':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
        final endOfDay = DateTime(endOfMonth.year, endOfMonth.month, endOfMonth.day, 23, 59, 59);
        return gifts
            .where((g) => g.date.isAfter(startOfMonth) && g.date.isBefore(endOfDay))
            .toList();
      default:
        return gifts;
    }
  }

  Map<Person, double> _calculateSpendingByPerson(List<Gift> gifts, List<Person> people) {
    final Map<Person, double> spending = {};

    for (final gift in gifts) {
      if (gift.type == GiftType.given) {
        final person = people.firstWhere(
          (p) => p.id == gift.personId,
          orElse: () => Person(
            id: gift.personId,
            name: 'Unknown',
            relationship: RelationshipType.other,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        spending[person] = (spending[person] ?? 0) + gift.value;
      }
    }

    return spending;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No data to analyze',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging gifts to see your spending',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats(BuildContext context, double totalSpent, double totalReceived) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Spending',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _OverallStatItem(
                  label: 'Total Given',
                  value: '\$${totalSpent.toStringAsFixed(2)}',
                  color: Colors.red,
                ),
                _OverallStatItem(
                  label: 'Total Received',
                  value: '\$${totalReceived.toStringAsFixed(2)}',
                  color: Colors.green,
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
                  '\$${(totalReceived - totalSpent).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: totalReceived > totalSpent ? Colors.green : Colors.red,
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
                color: Colors.grey[600],
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
