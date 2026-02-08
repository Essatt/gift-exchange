import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/gift.dart';
import '../../../models/person.dart';
import '../../../providers/gift_providers.dart';

class AnalysisPage extends ConsumerWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

          final totalSpent = gifts
              .where((g) => g.type == GiftType.given)
              .fold<double>(0, (sum, g) => sum + g.value);
          final totalReceived = gifts
              .where((g) => g.type == GiftType.received)
              .fold<double>(0, (sum, g) => sum + g.value);

          final spendingByPerson = _calculateSpendingByPerson(gifts, peopleAsync.value ?? []);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(giftsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOverallStats(context, totalSpent, totalReceived),
                const SizedBox(height: 16),
                _buildTimeframeToggle(),
                const SizedBox(height: 16),
                _buildTopSpenders(spendingByPerson),
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
                _OverallStatItem('Total Given', '\$$totalSpent.toStringAsFixed(2)}', Colors.red),
                _OverallStatItem('Total Received', '\$$totalReceived.toStringAsFixed(2)}', Colors.green),
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

class _TimeframeToggle extends StatefulWidget {
  const _TimeframeToggle({super.key});

  @override
  State<_TimeframeToggle> createState() => _TimeframeToggleState();
}

class _TimeframeToggleState extends State<_TimeframeToggle> {
  String _selectedTimeframe = 'overall';

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'overall',
          label: 'Overall',
          icon: Icon(Icons.infinite),
        ),
        ButtonSegment(
          value: 'yearly',
          label: 'Yearly',
          icon: Icon(Icons.calendar_today),
        ),
        ButtonSegment(
          value: 'monthly',
          label: 'Monthly',
          icon: Icon(Icons.calendar_month),
        ),
      ],
      selected: {_selectedTimeframe},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _selectedTimeframe = newSelection.first;
        });
      },
    );
  }
}

class _TopSpenders extends StatelessWidget {
  final Map<Person, double> spendingByPerson;

  const _TopSpenders({required this.spendingByPerson});

  @override
  Widget build(BuildContext context) {
    final sorted = spendingByPerson.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Recipients',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 12),
            ...sorted.take(5).map((entry) {
              final person = entry.key;
              final amount = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '\$$amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
          ],
        ),
      );
    }
}

Map<Person, double> _calculateSpendingByPerson(List<Gift> gifts, List<Person> people) {
  final Map<Person, double> spending = {};

  for (final gift in gifts) {
    if (gift.type == GiftType.given) {
      final person = people.firstWhere(
            (p) => p.id == gift.personId,
            orElse: () => Person(id: '', name: 'Unknown'),
          );
      spending[person] = (spending[person] ?? 0) + gift.value;
    }
  }

  return spending;
}
