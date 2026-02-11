import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/person.dart';
import '../models/gift.dart';

class GiftService {
  static const String _peopleBoxName = 'people';
  static const String _giftsBoxName = 'gifts';
  static const _uuid = Uuid();

  // Lazy getters — boxes are opened once in main.dart
  Box<Person> get _peopleBox => Hive.box<Person>(_peopleBoxName);
  Box<Gift> get _giftsBox => Hive.box<Gift>(_giftsBoxName);

  // Singleton
  GiftService._internal();
  static final GiftService _instance = GiftService._internal();
  factory GiftService() => _instance;

  String _generateId() => _uuid.v4();

  // --- Person CRUD ---

  Future<void> addPerson(Person person) async {
    final id = person.id.isEmpty ? _generateId() : person.id;
    final personWithId = person.copyWith(id: id);
    await _peopleBox.put(id, personWithId);
  }

  Future<void> updatePerson(Person person) async {
    await _peopleBox.put(person.id, person.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> deletePerson(String id) async {
    final giftKeys = _giftsBox.values
        .where((g) => g.personId == id)
        .map((g) => g.id)
        .toList();
    await _giftsBox.deleteAll(giftKeys);
    await _peopleBox.delete(id);
  }

  Person? getPerson(String id) => _peopleBox.get(id);

  List<Person> getAllPeople() => _peopleBox.values.toList();

  // --- Gift CRUD ---

  Future<void> addGift(Gift gift) async {
    final id = gift.id.isEmpty ? _generateId() : gift.id;
    final giftWithId = gift.copyWith(id: id);
    await _giftsBox.put(id, giftWithId);
    await _touchPerson(gift.personId);
  }

  Future<void> updateGift(Gift gift) async {
    await _giftsBox.put(gift.id, gift);
    await _touchPerson(gift.personId);
  }

  Future<void> deleteGift(String id) async {
    final gift = _giftsBox.get(id);
    await _giftsBox.delete(id);
    if (gift != null) {
      await _touchPerson(gift.personId);
    }
  }

  Future<void> _touchPerson(String personId) async {
    final person = _peopleBox.get(personId);
    if (person != null) {
      await _peopleBox.put(
        personId,
        person.copyWith(updatedAt: DateTime.now()),
      );
    }
  }

  Gift? getGift(String id) => _giftsBox.get(id);

  List<Gift> getAllGifts() => _giftsBox.values.toList();

  List<Gift> getGiftsByPersonId(String personId) {
    return _giftsBox.values.where((gift) => gift.personId == personId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // --- Query Methods ---

  List<String> getAllEventTypes() {
    return _giftsBox.values.map((gift) => gift.eventType).toSet().toList()
      ..sort();
  }

  Map<String, List<Gift>> getGiftsByEvent(String personId) {
    final gifts = getGiftsByPersonId(personId);
    final grouped = <String, List<Gift>>{};
    for (final gift in gifts) {
      grouped.putIfAbsent(gift.eventType, () => []).add(gift);
    }
    return grouped;
  }
}
