import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/gift_type.dart';
import '../../../../providers/gift_providers.dart';
import '_top_spenders.dart';

class AnalysisPage extends ConsumerStatefulWidget {
  const AnalysisPage({super.key});

  @override
  ConsumerState<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends ConsumerState<AnalysisPage> {
  String _selectedTimeframe = 'overall';
  String _selectedView = 'person'; // 'person' or 'label'

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
    ref.read(analysisTimeFilterProvider.notifier).state = filter;
  }

  @override
  Widget build(BuildContext context) {
    final allGifts = ref.watch(giftsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis'), elevation: 0),
      body: allGifts.isEmpty
          ? _buildEmptyState(context)
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final filteredGifts = ref.watch(filteredGiftsProvider);

    final totalSpent = filteredGifts
        .where((g) => g.type == GiftType.given)
        .fold<double>(0, (sum, g) => sum + g.value);
    final totalReceived = filteredGifts
        .where((g) => g.type == GiftType.received)
        .fold<double>(0, (sum, g) => sum + g.value);

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
          _ViewToggle(
            selected: _selectedView,
            onSelectionChanged: (value) {
              setState(() => _selectedView = value);
            },
          ),
          const SizedBox(height: 16),
          if (_selectedView == 'person')
            const TopSpenders()
          else
            const LabelBalanceList(),
        ],
      ),
    );
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

class _ViewToggle extends StatelessWidget {
  final String selected;
  final Function(String) onSelectionChanged;

  const _ViewToggle({required this.selected, required this.onSelectionChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'person',
          label: Text('By Person'),
          icon: Icon(Icons.person_outline),
        ),
        ButtonSegment(
          value: 'label',
          label: Text('By Label'),
          icon: Icon(Icons.label_outline),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (Set<String> newSelection) {
        onSelectionChanged(newSelection.first);
      },
    );
  }
}
