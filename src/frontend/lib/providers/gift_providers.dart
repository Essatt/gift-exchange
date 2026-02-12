import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gift_service.dart';
import '../models/person.dart';
import '../models/gift.dart';
import '../models/gift_type.dart';
import '../models/time_filter.dart';
import '../models/person_stats.dart';
import '../models/label_stats.dart';
import '../models/person_spending.dart';

// Re-export model types so existing consumers don't need to update imports
export '../models/time_filter.dart';
export '../models/person_stats.dart';
export '../models/label_stats.dart';
export '../models/person_spending.dart';

// ---------------------------------------------------------------------------
// Refresh signal — increment after any mutation to rebuild all data providers
// ---------------------------------------------------------------------------
final refreshSignalProvider = StateProvider<int>((ref) => 0);

final giftServiceProvider = Provider<GiftService>((ref) => GiftService());

// ---------------------------------------------------------------------------
// Core data providers
// ---------------------------------------------------------------------------

final peopleProvider = Provider<List<Person>>((ref) {
  ref.watch(refreshSignalProvider);
  return ref.watch(giftServiceProvider).getAllPeople();
});

final personProvider = Provider.family<Person?, String>((ref, id) {
  ref.watch(refreshSignalProvider);
  return ref.watch(giftServiceProvider).getPerson(id);
});

/// O(1) lookup map for person by ID
final peopleMapProvider = Provider<Map<String, Person>>((ref) {
  final people = ref.watch(peopleProvider);
  return {for (final p in people) p.id: p};
});

final giftsProvider = Provider<List<Gift>>((ref) {
  ref.watch(refreshSignalProvider);
  return ref.watch(giftServiceProvider).getAllGifts();
});

/// Pre-sorted by date descending
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

// ---------------------------------------------------------------------------
// Shared filtering utility
// ---------------------------------------------------------------------------

List<Gift> _applyTimeFilter(List<Gift> gifts, TimeFilter filter) {
  if (filter.type == TimeframeType.allTime) return gifts;
  return gifts.where((g) => filter.matches(g.date)).toList();
}

// ---------------------------------------------------------------------------
// Per-person stats (unfiltered)
// ---------------------------------------------------------------------------

final personStatsProvider = Provider.family<PersonStats, String>((
  ref,
  personId,
) {
  ref.watch(refreshSignalProvider);
  final gifts = ref.watch(giftsByPersonProvider(personId));
  return _computePersonStats(gifts);
});

PersonStats _computePersonStats(List<Gift> gifts) {
  double totalGiven = 0;
  double totalReceived = 0;
  Gift? lastReceivedGift;
  Gift? lastGivenGift;

  for (final gift in gifts) {
    if (gift.type == GiftType.given) {
      totalGiven += gift.value;
      if (lastGivenGift == null || gift.date.isAfter(lastGivenGift.date)) {
        lastGivenGift = gift;
      }
    } else {
      totalReceived += gift.value;
      if (lastReceivedGift == null ||
          gift.date.isAfter(lastReceivedGift.date)) {
        lastReceivedGift = gift;
      }
    }
  }

  return PersonStats(
    totalGiven: totalGiven,
    totalReceived: totalReceived,
    lastReceivedGift: lastReceivedGift,
    lastGivenGift: lastGivenGift,
  );
}

// ---------------------------------------------------------------------------
// Analysis page time filter + filtered gifts
// ---------------------------------------------------------------------------

final analysisTimeFilterProvider = StateProvider<TimeFilter>(
  (ref) => TimeFilter.allTime,
);

final filteredGiftsProvider = Provider<List<Gift>>((ref) {
  final gifts = ref.watch(giftsProvider);
  final filter = ref.watch(analysisTimeFilterProvider);
  return _applyTimeFilter(gifts, filter);
});

// ---------------------------------------------------------------------------
// Person detail page time filter + filtered data
// ---------------------------------------------------------------------------

final personDetailTimeFilterProvider = StateProvider.family<TimeFilter, String>(
  (ref, personId) => TimeFilter.allTime,
);

final filteredGiftsByPersonProvider = Provider.family<List<Gift>, String>((
  ref,
  personId,
) {
  final gifts = ref.watch(giftsByPersonProvider(personId));
  final filter = ref.watch(personDetailTimeFilterProvider(personId));
  return _applyTimeFilter(gifts, filter);
});

final filteredPersonStatsProvider = Provider.family<PersonStats, String>((
  ref,
  personId,
) {
  final gifts = ref.watch(filteredGiftsByPersonProvider(personId));
  return _computePersonStats(gifts);
});

// ---------------------------------------------------------------------------
// Label stats (analysis page — "By Label" view)
// ---------------------------------------------------------------------------

final labelStatsProvider = Provider<List<LabelStats>>((ref) {
  final gifts = ref.watch(filteredGiftsProvider);
  final Map<String, ({double given, double received, int count})> accum = {};

  for (final gift in gifts) {
    final prev = accum[gift.eventType] ?? (given: 0.0, received: 0.0, count: 0);
    if (gift.type == GiftType.given) {
      accum[gift.eventType] = (
        given: prev.given + gift.value,
        received: prev.received,
        count: prev.count + 1,
      );
    } else {
      accum[gift.eventType] = (
        given: prev.given,
        received: prev.received + gift.value,
        count: prev.count + 1,
      );
    }
  }

  return accum.entries
      .map(
        (e) => LabelStats(
          label: e.key,
          totalGiven: e.value.given,
          totalReceived: e.value.received,
          giftCount: e.value.count,
        ),
      )
      .toList()
    ..sort((a, b) => b.giftCount.compareTo(a.giftCount));
});

// ---------------------------------------------------------------------------
// Per-person spending for analysis page "By Person" view
// ---------------------------------------------------------------------------

final filteredPersonSpendingProvider = Provider<List<PersonSpending>>((ref) {
  final gifts = ref.watch(filteredGiftsProvider);
  final peopleMap = ref.watch(peopleMapProvider);

  final Map<String, ({double given, double received})> accum = {};

  for (final gift in gifts) {
    final prev = accum[gift.personId] ?? (given: 0.0, received: 0.0);
    if (gift.type == GiftType.given) {
      accum[gift.personId] = (
        given: prev.given + gift.value,
        received: prev.received,
      );
    } else {
      accum[gift.personId] = (
        given: prev.given,
        received: prev.received + gift.value,
      );
    }
  }

  return accum.entries
      .map(
        (e) => PersonSpending(
          personId: e.key,
          name: peopleMap[e.key]?.name ?? 'Unknown',
          totalGiven: e.value.given,
          totalReceived: e.value.received,
        ),
      )
      .toList()
    ..sort((a, b) => b.totalGiven.compareTo(a.totalGiven));
});

// ---------------------------------------------------------------------------
// Event labels provider
// ---------------------------------------------------------------------------

final eventLabelsProvider = Provider<List<String>>((ref) {
  ref.watch(refreshSignalProvider);
  return ref.watch(giftServiceProvider).getAllEventLabels();
});
