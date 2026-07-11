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

  // Undo state — keyed by deleted entity id so rapid consecutive deletes each
  // retain their own snapshot (a single slot would let "Undo" on one SnackBar
  // restore the wrong record). Bounded to the most recent few to avoid
  // unbounded memory growth over a long session.
  static const int _maxUndoSnapshots = 20;
  final Map<String, _DeletedPersonSnapshot> _deletedPeople = {};
  final Map<String, Gift> _deletedGifts = {};

  bool get hasUndoPersonData => _deletedPeople.isNotEmpty;
  bool get hasUndoGiftData => _deletedGifts.isNotEmpty;

  void _rememberDeletedPerson(String id, _DeletedPersonSnapshot snapshot) {
    _deletedPeople[id] = snapshot;
    _trimSnapshots(_deletedPeople);
  }

  void _rememberDeletedGift(String id, Gift gift) {
    _deletedGifts[id] = gift;
    _trimSnapshots(_deletedGifts);
  }

  void _trimSnapshots(Map<String, Object?> snapshots) {
    while (snapshots.length > _maxUndoSnapshots) {
      snapshots.remove(snapshots.keys.first);
    }
  }

  /// Restores a specific deleted person (and their gifts) by id. Safe to call
  /// after other deletions have occurred; no-op if the snapshot has expired.
  Future<void> undoDeletePerson(String id) async {
    final snapshot = _deletedPeople.remove(id);
    if (snapshot == null) return;
    await _peopleBox.put(snapshot.person.id, snapshot.person);
    if (snapshot.gifts.isNotEmpty) {
      await _giftsBox.putAll({for (final g in snapshot.gifts) g.id: g});
    }
    _invalidateLabelCache();
  }

  /// Restores a specific deleted gift by id. Safe to call after other
  /// deletions; no-op if the snapshot has expired.
  Future<void> undoDeleteGift(String id) async {
    final gift = _deletedGifts.remove(id);
    if (gift == null) return;
    await _giftsBox.put(gift.id, gift);
    await _touchPerson(gift.personId);
    _invalidateLabelCache();
  }

  void clearUndoData() {
    _deletedPeople.clear();
    _deletedGifts.clear();
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

    // Store for undo before deleting (keyed by id so a later delete doesn't
    // clobber this snapshot).
    if (person != null) {
      _rememberDeletedPerson(
        id,
        _DeletedPersonSnapshot(person: person, gifts: gifts),
      );
    }

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
    if (gift != null) {
      _rememberDeletedGift(id, gift);
    }
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

  /// Highest schema version this build can import.
  static const int _supportedBackupVersion = 1;

  /// Imports a backup produced by [exportToJson].
  ///
  /// The import is additive: records whose id does not already exist are added,
  /// and a record whose id DOES exist is overwritten with the backup's version
  /// (last-write-wins by id) — no existing record is deleted. It is staged in
  /// memory and validated in full BEFORE anything is written, so a malformed
  /// backup can never leave the database half-imported. Individual malformed
  /// records are skipped (and counted) rather than aborting the whole import;
  /// gifts referencing a person that is neither in the backup nor already
  /// stored are dropped to avoid orphans. Throws [FormatException] only when
  /// the payload is not a valid backup envelope at all (bad JSON / wrong
  /// shape / unsupported version).
  Future<String> importFromJson(String json) async {
    final dynamic decoded;
    try {
      decoded = jsonDecode(json);
    } catch (_) {
      throw const FormatException('Backup is not valid JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup format is not recognized.');
    }
    final map = decoded;

    // Absent version → assume the original v1 (which had no version field).
    // Present-but-non-numeric version → treat as unrecognized, not v1, so a
    // corrupt/newer envelope can't slip past the compatibility gate.
    final int version;
    if (map.containsKey('version')) {
      final parsed = _asInt(map['version']);
      if (parsed == null) {
        throw const FormatException(
          'Backup version is invalid or unrecognized.',
        );
      }
      version = parsed;
    } else {
      version = 1;
    }
    if (version > _supportedBackupVersion) {
      throw FormatException(
        'This backup was created by a newer version of the app '
        '(backup v$version, supported v$_supportedBackupVersion). '
        'Please update the app before importing.',
      );
    }

    final peopleList = map['people'] is List ? map['people'] as List : const [];
    final giftsList = map['gifts'] is List ? map['gifts'] as List : const [];
    final labelsList =
        map['customLabels'] is List ? map['customLabels'] as List : const [];

    // --- Stage everything in memory first; write nothing until fully parsed ---
    final stagedPeople = <String, Person>{};
    final stagedGifts = <String, Gift>{};
    var skippedPeople = 0;
    var skippedGifts = 0;

    for (final p in peopleList) {
      final person = _tryParsePerson(p);
      if (person == null) {
        skippedPeople++;
        continue;
      }
      stagedPeople[person.id] = person;
    }

    for (final g in giftsList) {
      final gift = _tryParseGift(g);
      if (gift == null) {
        skippedGifts++;
        continue;
      }
      // Drop gifts that would be orphaned — their person is neither in this
      // backup nor already stored locally.
      final personExists = stagedPeople.containsKey(gift.personId) ||
          _peopleBox.containsKey(gift.personId);
      if (!personExists) {
        skippedGifts++;
        continue;
      }
      stagedGifts[gift.id] = gift;
    }

    // --- Commit: all-or-nothing at the field level already guaranteed above ---
    if (stagedPeople.isNotEmpty) {
      await _peopleBox.putAll(stagedPeople);
    }
    if (stagedGifts.isNotEmpty) {
      await _giftsBox.putAll(stagedGifts);
    }

    for (final label in labelsList) {
      if (label is String && label.isNotEmpty) {
        await addCustomLabel(label);
      }
    }

    _invalidateLabelCache();

    final parts = <String>[
      'Imported ${stagedPeople.length} people and ${stagedGifts.length} gifts',
    ];
    final skipped = skippedPeople + skippedGifts;
    if (skipped > 0) {
      parts.add('skipped $skipped invalid record${skipped == 1 ? '' : 's'}');
    }
    return parts.join(' — ');
  }

  Person? _tryParsePerson(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw.map((k, v) => MapEntry(k.toString(), v));
    final id = _asNonEmptyString(map['id']);
    final name = _asNonEmptyString(map['name']);
    final createdAt = _asDate(map['createdAt']);
    final updatedAt = _asDate(map['updatedAt']);
    if (id == null || name == null || createdAt == null || updatedAt == null) {
      return null;
    }
    return Person(
      id: id,
      name: name,
      relationship: RelationshipType.values.firstWhere(
        (r) => r.name == _asStringOrNull(map['relationship']),
        orElse: () => RelationshipType.friend,
      ),
      customRelationship: _asStringOrNull(map['customRelationship']) ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Gift? _tryParseGift(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw.map((k, v) => MapEntry(k.toString(), v));
    final id = _asNonEmptyString(map['id']);
    final personId = _asNonEmptyString(map['personId']);
    final value = _asPositiveFiniteDouble(map['value']);
    final date = _asDate(map['date']);
    final createdAt = _asDate(map['createdAt']);
    final updatedAt = _asDate(map['updatedAt']);
    if (id == null ||
        personId == null ||
        value == null ||
        date == null ||
        createdAt == null ||
        updatedAt == null) {
      return null;
    }
    return Gift(
      id: id,
      personId: personId,
      type: GiftType.values.firstWhere(
        (r) => r.name == _asStringOrNull(map['type']),
        orElse: () => GiftType.given,
      ),
      value: value,
      date: date,
      eventType: _asStringOrNull(map['eventType']) ?? '',
      description: _asStringOrNull(map['description']) ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static int? _asInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);

  static String? _asNonEmptyString(dynamic v) {
    if (v is! String) return null;
    return v.isEmpty ? null : v;
  }

  /// Returns [v] if it is a String, else null — never throws on a non-String
  /// value (unlike a raw `as String?` cast, which throws a TypeError on e.g.
  /// a JSON number/bool/object). Used for OPTIONAL string fields so one
  /// malformed field skips the record instead of aborting the whole import.
  static String? _asStringOrNull(dynamic v) => v is String ? v : null;

  static DateTime? _asDate(dynamic v) {
    if (v is! String) return null;
    return DateTime.tryParse(v);
  }

  static double? _asPositiveFiniteDouble(dynamic v) {
    final double? d = v is num
        ? v.toDouble()
        : (v is String ? double.tryParse(v) : null);
    if (d == null || !d.isFinite || d <= 0) return null;
    return d;
  }
}

/// Snapshot of a deleted person plus their gifts, retained for undo.
class _DeletedPersonSnapshot {
  final Person person;
  final List<Gift> gifts;

  const _DeletedPersonSnapshot({required this.person, required this.gifts});
}
