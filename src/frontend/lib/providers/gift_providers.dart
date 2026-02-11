import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gift_service.dart';
import '../models/person.dart';
import '../models/gift.dart';
import '../models/gift_type.dart';

// Increment after any mutation to rebuild all data providers
final refreshSignalProvider = StateProvider<int>((ref) => 0);

final giftServiceProvider = Provider<GiftService>((ref) => GiftService());

final peopleProvider = Provider<List<Person>>((ref) {
  ref.watch(refreshSignalProvider);
  return ref.watch(giftServiceProvider).getAllPeople();
});

final personProvider = Provider.family<Person?, String>((ref, id) {
  ref.watch(refreshSignalProvider);
  return ref.watch(giftServiceProvider).getPerson(id);
});

// O(1) lookup map for person by ID — avoids O(n) scans in list pages
final peopleMapProvider = Provider<Map<String, Person>>((ref) {
  final people = ref.watch(peopleProvider);
  return {for (final p in people) p.id: p};
});

final giftsProvider = Provider<List<Gift>>((ref) {
  ref.watch(refreshSignalProvider);
  return ref.watch(giftServiceProvider).getAllGifts();
});

// Pre-sorted by date descending — memoized, avoids re-sorting on every build
final sortedGiftsProvider = Provider<List<Gift>>((ref) {
  final gifts = ref.watch(giftsProvider);
  return List<Gift>.from(gifts)..sort((a, b) => b.date.compareTo(a.date));
});

final giftsByPersonProvider = Provider.family<List<Gift>, String>((
  ref,
  personId,
) {
  ref.watch(refreshSignalProvider);
  return ref.watch(giftServiceProvider).getGiftsByPersonId(personId);
});

// Single-pass stats calculation (was 7 separate full scans)
final personStatsProvider = Provider.family<PersonStats, String>((
  ref,
  personId,
) {
  ref.watch(refreshSignalProvider);
  final gifts = ref.watch(giftsByPersonProvider(personId));

  double totalGiven = 0;
  double totalReceived = 0;
  Gift? lastGiftFrom;
  Gift? lastGiftTo;

  for (final gift in gifts) {
    if (gift.type == GiftType.given) {
      totalGiven += gift.value;
      if (lastGiftTo == null || gift.date.isAfter(lastGiftTo.date)) {
        lastGiftTo = gift;
      }
    } else {
      totalReceived += gift.value;
      if (lastGiftFrom == null || gift.date.isAfter(lastGiftFrom.date)) {
        lastGiftFrom = gift;
      }
    }
  }

  return PersonStats(
    totalGiven: totalGiven,
    totalReceived: totalReceived,
    netBalance: totalReceived - totalGiven,
    lastGiftFrom: lastGiftFrom,
    lastGiftTo: lastGiftTo,
  );
});

class PersonStats {
  final double totalGiven;
  final double totalReceived;
  final double netBalance;
  final Gift? lastGiftFrom;
  final Gift? lastGiftTo;

  const PersonStats({
    required this.totalGiven,
    required this.totalReceived,
    required this.netBalance,
    this.lastGiftFrom,
    this.lastGiftTo,
  });
}
