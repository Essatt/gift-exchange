import 'package:flutter/material.dart';
import '../../../../models/person.dart';

class TopSpenders extends StatelessWidget {
  final Map<Person, double> spendingByPerson;

  const TopSpenders({super.key, required this.spendingByPerson});

  @override
  Widget build(BuildContext context) {
    final sorted = spendingByPerson.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return const SizedBox.shrink();
    }

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
                            '\$${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
