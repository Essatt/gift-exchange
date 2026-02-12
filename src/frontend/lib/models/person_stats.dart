import 'gift.dart';

class PersonStats {
  final double totalGiven;
  final double totalReceived;
  final Gift? lastReceivedGift;
  final Gift? lastGivenGift;

  double get netBalance => totalReceived - totalGiven;

  const PersonStats({
    required this.totalGiven,
    required this.totalReceived,
    this.lastReceivedGift,
    this.lastGivenGift,
  }) : assert(totalGiven >= 0, 'totalGiven must be non-negative'),
       assert(totalReceived >= 0, 'totalReceived must be non-negative');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonStats &&
          totalGiven == other.totalGiven &&
          totalReceived == other.totalReceived &&
          lastReceivedGift == other.lastReceivedGift &&
          lastGivenGift == other.lastGivenGift;

  @override
  int get hashCode =>
      Object.hash(totalGiven, totalReceived, lastReceivedGift, lastGivenGift);
}
