import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/person.dart';
import '../models/gift.dart';

class GiftService {
  static const String _peopleBoxName = 'people';
  static const String _giftsBoxName = 'gifts';
  static const String _customLabelsBoxName = 'custom_event_labels';
  static const _uuid = Uuid();

  static const List<String> defaultEventTypes = [
    'Birthday',
    'Wedding',
    'Housewarming',
    'Holiday',
    'Anniversary',
  ];

  static const int maxLabelLength = 50;

  // Lazy getters with open-state assertions
  Box<Person> get _peopleBox {
    assert(
      Hive.isBoxOpen(_peopleBoxName),
      '$_peopleBoxName box must be opened before use',
    );
    return Hive.box<Person>(_peopleBoxName);
  }

  Box<Gift> get _giftsBox {
    assert(
      Hive.isBoxOpen(_giftsBoxName),
      '$_giftsBoxName box must be opened before use',
    );
    return Hive.box<Gift>(_giftsBoxName);
  }

  Box<String> get _customLabelsBox {
    assert(
      Hive.isBoxOpen(_customLabelsBoxName),
      '$_customLabelsBoxName box must be opened before use',
    );
    return Hive.box<String>(_customLabelsBoxName);
  }

  // Label cache
  List<String>? _labelCache;

  void _invalidateLabelCache() {
    _labelCache = null;
  }

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
    _invalidateLabelCache();
  }

  Person? getPerson(String id) => _peopleBox.get(id);

  List<Person> getAllPeople() => _peopleBox.values.toList();

  // --- Gift CRUD ---

  Future<void> addGift(Gift gift) async {
    final id = gift.id.isEmpty ? _generateId() : gift.id;
    final giftWithId = gift.copyWith(id: id);
    await _giftsBox.put(id, giftWithId);
    await _touchPerson(gift.personId);
    _invalidateLabelCache();
  }

  Future<void> updateGift(Gift gift) async {
    await _giftsBox.put(gift.id, gift);
    await _touchPerson(gift.personId);
    _invalidateLabelCache();
  }

  Future<void> deleteGift(String id) async {
    final gift = _giftsBox.get(id);
    await _giftsBox.delete(id);
    if (gift != null) {
      await _touchPerson(gift.personId);
    }
    _invalidateLabelCache();
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

  // --- Custom Event Labels ---

  List<String> getAllEventLabels() {
    if (_labelCache != null) return _labelCache!;

    final labels = <String>{...defaultEventTypes};

    // Add custom labels from dedicated box
    labels.addAll(_customLabelsBox.values);

    // Add any event types from existing gift data (backward compat)
    for (final gift in _giftsBox.values) {
      if (gift.eventType.isNotEmpty && gift.eventType != 'Custom') {
        labels.add(gift.eventType);
      }
    }

    final sorted = labels.toList()..sort();
    _labelCache = sorted;
    return sorted;
  }

  Future<void> addCustomLabel(String label) async {
    final trimmed = _sanitizeLabel(label);
    if (trimmed.isEmpty) return;
    if (trimmed.length > maxLabelLength) return;
    // Avoid duplicates
    if (_customLabelsBox.values.contains(trimmed)) return;
    await _customLabelsBox.add(trimmed);
    _invalidateLabelCache();
  }

  Future<void> deleteCustomLabel(String label) async {
    // Materialize keys list before iterating to avoid concurrent modification
    final keysToDelete = _customLabelsBox.keys
        .where((key) => _customLabelsBox.get(key) == label)
        .toList();
    for (final key in keysToDelete) {
      await _customLabelsBox.delete(key);
    }
    _invalidateLabelCache();
  }

  String _sanitizeLabel(String input) {
    // Remove control characters, trim whitespace
    return input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
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
