import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../../models/gift_type.dart';
import '../../../../providers/gift_providers.dart';
import '../../../../shared/widgets/timeframe_toggle.dart';
import '../../../../shared/format/currency.dart';
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
      appBar: AppBar(
        title: const Text('Analysis'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export') _exportData(context, ref);
              if (value == 'import') _importData(context, ref);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_upload_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Export Backup'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Import Backup'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: allGifts.isEmpty
          ? _buildEmptyState(context)
          : _buildContent(context),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final service = ref.read(giftServiceProvider);
    final json = service.exportToJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup copied to clipboard. Save it somewhere safe!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Backup'),
        content: const Text(
          'This will ADD data from your backup. Existing data is preserved. Paste the backup JSON:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboard?.text == null || clipboard!.text!.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Clipboard is empty')),
        );
        return;
      }
      final service = ref.read(giftServiceProvider);
      final result = await service.importFromJson(clipboard.text!);
      ref.read(refreshSignalProvider.notifier).state++;
      messenger.showSnackBar(SnackBar(content: Text(result)));
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Import failed. Check the JSON format.')),
      );
    }
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
          TimeframeToggle(
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
                Flexible(
                  child: _OverallStatItem(
                    label: 'Total Given',
                    value: formatCurrency(totalSpent),
                    color: colors.error,
                  ),
                ),
                Flexible(
                  child: _OverallStatItem(
                    label: 'Total Received',
                    value: formatCurrency(totalReceived),
                    color: colors.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Net Balance',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                ),
                Flexible(
                  child: Text(
                    formatCurrency(netBalance),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: balanceColor,
                      fontSize: 20,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

class _ViewToggle extends StatelessWidget {
  final String selected;
  final Function(String) onSelectionChanged;

  const _ViewToggle({required this.selected, required this.onSelectionChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<String>(
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
        ),
      ),
    );
  }
}
