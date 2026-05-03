import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/person.dart';
import '../models/gift.dart';
import '../models/relationship_type.dart';
import '../models/gift_type.dart';

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

  // Undo state
  Person? _lastDeletedPerson;
  List<Gift>? _lastDeletedGifts;
  Gift? _lastDeletedGift;

  bool get hasUndoPersonData => _lastDeletedPerson != null;
  bool get hasUndoGiftData => _lastDeletedGift != null;

  Future<void> undoDeletePerson() async {
    final person = _lastDeletedPerson;
    final gifts = _lastDeletedGifts;
    if (person == null) return;
    await _peopleBox.put(person.id, person);
    if (gifts != null) {
      await _giftsBox.putAll(
        {for (final g in gifts) g.id: g},
      );
    }
    _lastDeletedPerson = null;
    _lastDeletedGifts = null;
    _invalidateLabelCache();
  }

  Future<void> undoDeleteGift() async {
    final gift = _lastDeletedGift;
    if (gift == null) return;
    await _giftsBox.put(gift.id, gift);
    await _touchPerson(gift.personId);
    _lastDeletedGift = null;
    _invalidateLabelCache();
  }

  void clearUndoData() {
    _lastDeletedPerson = null;
    _lastDeletedGifts = null;
    _lastDeletedGift = null;
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
    final person = _peopleBox.get(id);
    final gifts = _giftsBox.values
        .where((g) => g.personId == id)
        .toList();
    final giftKeys = gifts.map((g) => g.id).toList();

    // Store for undo before deleting
    _lastDeletedPerson = person;
    _lastDeletedGifts = gifts;

    await _giftsBox.deleteAll(giftKeys);
    await _peopleBox.delete(id);
    _invalidateLabelCache();
  }

  Person? getPerson(String id) => _peopleBox.get(id);

  List<Person> getAllPeople() => _peopleBox.values.toList();

  bool isNameDuplicate(String name, {String? excludeId}) {
    final lower = name.trim().toLowerCase();
    return _peopleBox.values.any(
      (p) => p.name.trim().toLowerCase() == lower && p.id != excludeId,
    );
  }

  // --- Gift CRUD ---

  Future<void> addGift(Gift gift) async {
    final id = gift.id.isEmpty ? _generateId() : gift.id;
    final giftWithId = gift.copyWith(id: id);
    await _giftsBox.put(id, giftWithId);
    await _touchPerson(gift.personId);
    _invalidateLabelCache();
  }

  Future<void> updateGift(Gift gift) async {
    await _giftsBox.put(
      gift.id,
      gift.copyWith(updatedAt: DateTime.now()),
    );
    await _touchPerson(gift.personId);
    _invalidateLabelCache();
  }

  Future<void> deleteGift(String id) async {
    final gift = _giftsBox.get(id);
    _lastDeletedGift = gift;
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

  // --- Backup / Restore ---

  String exportToJson() {
    final people = _peopleBox.values.toList();
    final gifts = _giftsBox.values.toList();
    final labels = _customLabelsBox.values.toList();

    final map = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'people': people.map((p) => {
            'id': p.id,
            'name': p.name,
            'relationship': p.relationship.name,
            'customRelationship': p.customRelationship,
            'createdAt': p.createdAt.toIso8601String(),
            'updatedAt': p.updatedAt.toIso8601String(),
          }).toList(),
      'gifts': gifts.map((g) => {
            'id': g.id,
            'personId': g.personId,
            'type': g.type.name,
            'value': g.value,
            'date': g.date.toIso8601String(),
            'eventType': g.eventType,
            'description': g.description,
            'createdAt': g.createdAt.toIso8601String(),
            'updatedAt': g.updatedAt.toIso8601String(),
          }).toList(),
      'customLabels': labels,
    };

    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Future<String> importFromJson(String json) async {
    final map = jsonDecode(json) as Map<String, dynamic>;

    final peopleList = (map['people'] as List<dynamic>?) ?? [];
    final giftsList = (map['gifts'] as List<dynamic>?) ?? [];
    final labelsList = (map['customLabels'] as List<dynamic>?) ?? [];

    int importedPeople = 0;
    int importedGifts = 0;

    for (final p in peopleList) {
      final pMap = p as Map<String, dynamic>;
      final person = Person(
        id: pMap['id'] as String,
        name: pMap['name'] as String,
        relationship: RelationshipType.values.firstWhere(
          (r) => r.name == (pMap['relationship'] as String?),
          orElse: () => RelationshipType.friend,
        ),
        customRelationship: (pMap['customRelationship'] as String?) ?? '',
        createdAt: DateTime.parse(pMap['createdAt'] as String),
        updatedAt: DateTime.parse(pMap['updatedAt'] as String),
      );
      await _peopleBox.put(person.id, person);
      importedPeople++;
    }

    for (final g in giftsList) {
      final gMap = g as Map<String, dynamic>;
      final gift = Gift(
        id: gMap['id'] as String,
        personId: gMap['personId'] as String,
        type: GiftType.values.firstWhere(
          (r) => r.name == (gMap['type'] as String?),
          orElse: () => GiftType.given,
        ),
        value: (gMap['value'] as num).toDouble(),
        date: DateTime.parse(gMap['date'] as String),
        eventType: (gMap['eventType'] as String?) ?? '',
        description: (gMap['description'] as String?) ?? '',
        createdAt: DateTime.parse(gMap['createdAt'] as String),
        updatedAt: DateTime.parse(gMap['updatedAt'] as String),
      );
      await _giftsBox.put(gift.id, gift);
      importedGifts++;
    }

    for (final label in labelsList) {
      if (label is String && label.isNotEmpty) {
        await addCustomLabel(label);
      }
    }

    _invalidateLabelCache();
    return 'Imported $importedPeople people and $importedGifts gifts';
  }
}
