class LabelStats {
  final String label;
  final double totalGiven;
  final double totalReceived;
  final int giftCount;

  double get netBalance => totalReceived - totalGiven;

  const LabelStats({
    required this.label,
    required this.totalGiven,
    required this.totalReceived,
    required this.giftCount,
  }) : assert(totalGiven >= 0, 'totalGiven must be non-negative'),
       assert(totalReceived >= 0, 'totalReceived must be non-negative'),
       assert(giftCount >= 0, 'giftCount must be non-negative');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabelStats &&
          label == other.label &&
          totalGiven == other.totalGiven &&
          totalReceived == other.totalReceived &&
          giftCount == other.giftCount;

  @override
  int get hashCode => Object.hash(label, totalGiven, totalReceived, giftCount);
}
