import 'package:hive_flutter/hive_flutter.dart';
import '../models/person.dart';
import '../models/gift.dart';
import '../models/gift_type.dart';
import '../models/relationship_type.dart';

class GiftService {
  // Constants for box names
  static const String _peopleBoxName = 'people';
  static const String _giftsBoxName = 'gifts';

  // Box references
  late final Box<Person> _peopleBox;
  late final Box<Gift> _giftsBox;

  // Singleton pattern
  GiftService._internal();
  static final GiftService _instance = GiftService._internal();
  factory GiftService() => _instance;

  /// Initializes the service by opening Hive boxes.
  Future<void> init() async {
    try {
      _peopleBox = await Hive.openBox<Person>(_peopleBoxName);
      _giftsBox = await Hive.openBox<Gift>(_giftsBoxName);
    } catch (e) {
      rethrow;
    }
  }

  String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  // --- Person CRUD Operations ---

  Future<void> addPerson(Person person) async {
    try {
      final id = person.id.isEmpty ? _generateId() : person.id;
      final personWithId = person.copyWith(id: id);
      await _peopleBox.put(id, personWithId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePerson(Person person) async {
    try {
      await _peopleBox.put(person.id, person.copyWith(updatedAt: DateTime.now()));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePerson(String id) async {
    try {
      // Delete all gifts associated with this person first
      final gifts = _giftsBox.values.where((g) => g.personId == id).toList();
      for (final gift in gifts) {
        await _giftsBox.delete(gift.id);
      }
      // Then delete the person
      await _peopleBox.delete(id);
    } catch (e) {
      rethrow;
    }
  }

  Person? getPerson(String id) {
    return _peopleBox.get(id);
  }

  List<Person> getAllPeople() {
    return _peopleBox.values.toList();
  }

  // --- Gift CRUD Operations ---

  Future<void> addGift(Gift gift) async {
    try {
      final id = gift.id.isEmpty ? _generateId() : gift.id;
      final giftWithId = gift.copyWith(id: id);
      await _giftsBox.put(id, giftWithId);
      // Update person updatedAt timestamp
      final person = _peopleBox.get(gift.personId);
      if (person != null) {
        await _peopleBox.put(gift.personId, person.copyWith(updatedAt: DateTime.now()));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateGift(Gift gift) async {
    try {
      await _giftsBox.put(gift.id, gift);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteGift(String id) async {
    try {
      await _giftsBox.delete(id);
    } catch (e) {
      rethrow;
    }
  }

  Gift? getGift(String id) {
    return _giftsBox.get(id);
  }

  List<Gift> getAllGifts() {
    return _giftsBox.values.toList();
  }

  List<Gift> getGiftsByPersonId(String personId) {
    return _giftsBox.values
        .where((gift) => gift.personId == personId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
  }

  List<Gift> getGiftsByDateRange(DateTime start, DateTime end) {
    return _giftsBox.values
        .where((gift) => gift.date.isAfter(start) && gift.date.isBefore(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // --- Calculation Methods ---

  /// Gets total value of gifts given to a person
  double getTotalGivenForPerson(String personId) {
    return _giftsBox.values
        .where((gift) => gift.personId == personId && gift.type == GiftType.given)
        .fold(0.0, (sum, gift) => sum + gift.value);
  }

  /// Gets total value of gifts received from a person
  double getTotalReceivedForPerson(String personId) {
    return _giftsBox.values
        .where((gift) => gift.personId == personId && gift.type == GiftType.received)
        .fold(0.0, (sum, gift) => sum + gift.value);
  }

  /// Gets net balance for a person (positive = you gave more, negative = you received more)
  double getNetBalanceForPerson(String personId) {
    return getTotalGivenForPerson(personId) - getTotalReceivedForPerson(personId);
  }

  /// Gets total gifts given in a specific month/year
  double getTotalGivenInMonth(int month, int year) {
    return _giftsBox.values
        .where((gift) =>
            gift.type == GiftType.given &&
            gift.date.month == month &&
            gift.date.year == year)
        .fold(0.0, (sum, gift) => sum + gift.value);
  }

  /// Gets total gifts given in a specific year
  double getTotalGivenInYear(int year) {
    return _giftsBox.values
        .where((gift) =>
            gift.type == GiftType.given && gift.date.year == year)
        .fold(0.0, (sum, gift) => sum + gift.value);
  }

  /// Gets total gifts given overall
  double getTotalGivenOverall() {
    return _giftsBox.values
        .where((gift) => gift.type == GiftType.given)
        .fold(0.0, (sum, gift) => sum + gift.value);
  }

  /// Gets the last gift received from a person
  Gift? getLastGiftFromPerson(String personId) {
    return _giftsBox.values
        .where((gift) => gift.personId == personId && gift.type == GiftType.received)
        .fold<Gift?>(null, (latest, gift) {
          if (latest == null || gift.date.isAfter(latest.date)) {
            return gift;
          }
          return latest;
        });
  }

  /// Gets the last gift given to a person
  Gift? getLastGiftToPerson(String personId) {
    return _giftsBox.values
        .where((gift) => gift.personId == personId && gift.type == GiftType.given)
        .fold<Gift?>(null, (latest, gift) {
          if (latest == null || gift.date.isAfter(latest.date)) {
            return gift;
          }
          return latest;
        });
  }

  /// Gets all unique event types
  List<String> getAllEventTypes() {
    final eventTypes = _giftsBox.values.map((gift) => gift.eventType).toSet();
    return eventTypes.toList()..sort();
  }

  /// Gets gifts grouped by event type for a person
  Map<String, List<Gift>> getGiftsByEvent(String personId) {
    final gifts = getGiftsByPersonId(personId);
    final grouped = <String, List<Gift>>{};
    for (final gift in gifts) {
      if (!grouped.containsKey(gift.eventType)) {
        grouped[gift.eventType] = [];
      }
      grouped[gift.eventType]!.add(gift);
    }
    return grouped;
  }
}
