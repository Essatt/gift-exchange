import 'package:flutter/material.dart';

class TimeframeToggle extends StatelessWidget {
  final String selected;
  final void Function(String) onSelectionChanged;

  const TimeframeToggle({
    super.key,
    required this.selected,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<String>(
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
        ),
      ),
    );
  }
}
