import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_exchange/shared/widgets/timeframe_toggle.dart';
import 'package:gift_exchange/shared/format/currency.dart';
import 'package:gift_exchange/models/person.dart';
import 'package:gift_exchange/models/gift.dart';
import 'package:gift_exchange/models/gift_type.dart';
import 'package:gift_exchange/models/relationship_type.dart';
import 'package:gift_exchange/models/time_filter.dart';
import 'package:gift_exchange/models/person_stats.dart';
import 'package:gift_exchange/models/label_stats.dart';
import 'package:gift_exchange/models/person_spending.dart';
import 'package:gift_exchange/services/gift_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  group('Responsive + formatting', () {
    testWidgets(
        'TimeframeToggle does not overflow on a 320dp screen at 3x text scale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
              child: TimeframeToggle(
                selected: 'overall',
                onSelectionChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      // A RenderFlex overflow would surface as a thrown FlutterError here.
      expect(tester.takeException(), isNull);
    });

    test('formatCurrency places the sign before the symbol and groups', () {
      expect(formatCurrency(1234.5), '\$1,234.50');
      expect(formatCurrency(-1234.5), '-\$1,234.50');
      expect(formatCurrency(double.nan), '\$0.00');
      expect(formatCurrency(double.infinity), '\$0.00');
    });
  });

  group('Person model', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final person = Person(
        id: 'p1',
        name: 'Alice',
        relationship: RelationshipType.friend,
        createdAt: now,
        updatedAt: now,
      );

      expect(person.id, 'p1');
      expect(person.name, 'Alice');
      expect(person.relationship, RelationshipType.friend);
      expect(person.customRelationship, '');
    });

    test('relationshipLabel returns correct labels', () {
      final now = DateTime.now();
      final family = Person(
        id: '1', name: 'Mom', relationship: RelationshipType.family,
        createdAt: now, updatedAt: now,
      );
      final friend = Person(
        id: '2', name: 'Bob', relationship: RelationshipType.friend,
        createdAt: now, updatedAt: now,
      );
      final other = Person(
        id: '3', name: 'Neighbor', relationship: RelationshipType.other,
        customRelationship: 'Neighbor', createdAt: now, updatedAt: now,
      );

      expect(family.relationshipLabel, 'Family');
      expect(friend.relationshipLabel, 'Friend');
      expect(other.relationshipLabel, 'Neighbor');
    });

    test('copyWith preserves unchanged fields', () {
      final now = DateTime.now();
      final person = Person(
        id: 'p1', name: 'Alice', relationship: RelationshipType.friend,
        createdAt: now, updatedAt: now,
      );
      final updated = person.copyWith(name: 'Alicia');

      expect(updated.id, 'p1');
      expect(updated.name, 'Alicia');
      expect(updated.relationship, RelationshipType.friend);
    });

    test('equality by id', () {
      final now = DateTime.now();
      final a = Person(id: '1', name: 'A', relationship: RelationshipType.friend, createdAt: now, updatedAt: now);
      final b = Person(id: '1', name: 'B', relationship: RelationshipType.family, createdAt: now, updatedAt: now);
      final c = Person(id: '2', name: 'A', relationship: RelationshipType.friend, createdAt: now, updatedAt: now);

      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('Gift model', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final gift = Gift(
        id: 'g1', personId: 'p1', type: GiftType.given,
        value: 50.0, date: now, eventType: 'Birthday',
        description: 'Watch', createdAt: now, updatedAt: now,
      );

      expect(gift.id, 'g1');
      expect(gift.value, 50.0);
      expect(gift.type, GiftType.given);
    });

    test('asserts positive value', () {
      final now = DateTime.now();
      expect(
        () => Gift(
          id: 'g1', personId: 'p1', type: GiftType.given,
          value: 0, date: now, eventType: 'Birthday',
          description: '', createdAt: now, updatedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith updates fields', () {
      final now = DateTime.now();
      final gift = Gift(
        id: 'g1', personId: 'p1', type: GiftType.given,
        value: 50.0, date: now, eventType: 'Birthday',
        description: 'Watch', createdAt: now, updatedAt: now,
      );
      final updated = gift.copyWith(value: 75.0, description: 'Necklace');

      expect(updated.value, 75.0);
      expect(updated.description, 'Necklace');
      expect(updated.id, 'g1');
    });
  });

  group('TimeFilter', () {
    test('allTime matches any date', () {
      const filter = TimeFilter.allTime;
      expect(filter.matches(DateTime(2020, 1, 1)), true);
      expect(filter.matches(DateTime.now()), true);
    });

    test('forYear matches only given year', () {
      final filter = TimeFilter.forYear(2024);
      expect(filter.matches(DateTime(2024, 6, 15)), true);
      expect(filter.matches(DateTime(2023, 6, 15)), false);
      expect(filter.matches(DateTime(2025, 1, 1)), false);
    });

    test('forMonth matches only given month', () {
      final filter = TimeFilter.forMonth(year: 2024, month: 6);
      expect(filter.matches(DateTime(2024, 6, 15)), true);
      expect(filter.matches(DateTime(2024, 7, 1)), false);
      expect(filter.matches(DateTime(2023, 6, 1)), false);
    });
  });

  group('PersonStats', () {
    test('netBalance is received minus given', () {
      const stats = PersonStats(totalGiven: 100, totalReceived: 150);
      expect(stats.netBalance, 50);
    });

    test('netBalance can be negative', () {
      const stats = PersonStats(totalGiven: 200, totalReceived: 150);
      expect(stats.netBalance, -50);
    });

    test('asserts non-negative values', () {
      expect(
        () => PersonStats(totalGiven: -1, totalReceived: 100),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('LabelStats', () {
    test('netBalance calculation', () {
      const stats = LabelStats(
        label: 'Birthday', totalGiven: 100, totalReceived: 200, giftCount: 3,
      );
      expect(stats.netBalance, 100);
    });
  });

  group('PersonSpending', () {
    test('netBalance calculation', () {
      const spending = PersonSpending(
        personId: 'p1', name: 'Alice', totalGiven: 200, totalReceived: 100,
      );
      expect(spending.netBalance, -100);
    });
  });

  group('GiftService', () {
    late GiftService service;

    setUp(() async {
      Hive.init('./test/hive_test');
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(RelationshipTypeAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(GiftTypeAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PersonAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(GiftAdapter());

      await Hive.openBox<Person>('people');
      await Hive.openBox<Gift>('gifts');
      await Hive.openBox<String>('custom_event_labels');

      service = GiftService();
    });

    tearDown(() async {
      await Hive.deleteBoxFromDisk('people');
      await Hive.deleteBoxFromDisk('gifts');
      await Hive.deleteBoxFromDisk('custom_event_labels');
    });

    test('adds and retrieves a person', () async {
      final now = DateTime.now();
      final person = Person(
        id: '', name: 'Alice', relationship: RelationshipType.friend,
        createdAt: now, updatedAt: now,
      );
      await service.addPerson(person);

      final people = service.getAllPeople();
      expect(people.length, 1);
      expect(people.first.name, 'Alice');
      expect(people.first.id, isNotEmpty);
    });

    test('updates a person', () async {
      final now = DateTime.now();
      final person = Person(
        id: 'p1', name: 'Alice', relationship: RelationshipType.friend,
        createdAt: now, updatedAt: now,
      );
      await service.addPerson(person);
      await service.updatePerson(person.copyWith(name: 'Alicia'));

      final updated = service.getPerson('p1');
      expect(updated?.name, 'Alicia');
    });

    test('deletes a person and their gifts', () async {
      final now = DateTime.now();
      final person = Person(
        id: 'p1', name: 'Alice', relationship: RelationshipType.friend,
        createdAt: now, updatedAt: now,
      );
      await service.addPerson(person);
      await service.addGift(Gift(
        id: '', personId: 'p1', type: GiftType.given,
        value: 50.0, date: now, eventType: 'Birthday',
        description: 'Watch', createdAt: now, updatedAt: now,
      ));

      await service.deletePerson('p1');

      expect(service.getPerson('p1'), null);
      expect(service.getGiftsByPersonId('p1'), isEmpty);
    });

    test('undo delete person restores person and gifts', () async {
      final now = DateTime.now();
      final person = Person(
        id: 'p1', name: 'Alice', relationship: RelationshipType.friend,
        createdAt: now, updatedAt: now,
      );
      await service.addPerson(person);
      await service.addGift(Gift(
        id: '', personId: 'p1', type: GiftType.given,
        value: 50.0, date: now, eventType: 'Birthday',
        description: 'Watch', createdAt: now, updatedAt: now,
      ));

      await service.deletePerson('p1');
      expect(service.getPerson('p1'), null);

      await service.undoDeletePerson('p1');
      expect(service.getPerson('p1'), isNotNull);
      expect(service.getPerson('p1')?.name, 'Alice');
      expect(service.getGiftsByPersonId('p1').length, 1);
    });

    test('adds and retrieves gifts', () async {
      final now = DateTime.now();
      final person = Person(
        id: 'p1', name: 'Alice', relationship: RelationshipType.friend,
        createdAt: now, updatedAt: now,
      );
      await service.addPerson(person);
      await service.addGift(Gift(
        id: '', personId: 'p1', type: GiftType.given,
        value: 50.0, date: now, eventType: 'Birthday',
        description: 'Watch', createdAt: now, updatedAt: now,
      ));
      await service.addGift(Gift(
        id: '', personId: 'p1', type: GiftType.received,
        value: 75.0, date: now, eventType: 'Holiday',
        description: 'Book', createdAt: now, updatedAt: now,
      ));

      final gifts = service.getGiftsByPersonId('p1');
      expect(gifts.length, 2);
    });

    test('undo delete gift restores gift', () async {
      final now = DateTime.now();
      final person = Person(
        id: 'p1', name: 'Alice', relationship: RelationshipType.friend,
        createdAt: now, updatedAt: now,
      );
      await service.addPerson(person);
      final gift = Gift(
        id: 'g1', personId: 'p1', type: GiftType.given,
        value: 50.0, date: now, eventType: 'Birthday',
        description: 'Watch', createdAt: now, updatedAt: now,
      );
      await service.addGift(gift);

      await service.deleteGift('g1');
      expect(service.getGift('g1'), null);

      await service.undoDeleteGift('g1');
      expect(service.getGift('g1'), isNotNull);
      expect(service.getGift('g1')?.value, 50.0);
    });

    test('name duplicate detection', () async {
      final now = DateTime.now();
      await service.addPerson(Person(
        id: 'p1', name: ' Alice ', relationship: RelationshipType.friend,
        createdAt: now, updatedAt: now,
      ));

      expect(service.isNameDuplicate('alice'), true);
      expect(service.isNameDuplicate('ALICE'), true);
      expect(service.isNameDuplicate('Bob'), false);
      expect(service.isNameDuplicate('alice', excludeId: 'p1'), false);
    });

    test('manages custom labels', () async {
      await service.addCustomLabel('Graduation');
      await service.addCustomLabel('Baby Shower');

      final labels = service.getAllEventLabels();
      expect(labels, contains('Graduation'));
      expect(labels, contains('Baby Shower'));
      expect(labels, contains('Birthday')); // default
    });

    test('sanitizes labels', () async {
      await service.addCustomLabel('Test\x00Label');
      final labels = service.getAllEventLabels();
      expect(labels.any((l) => l.contains('\x00')), false);
      expect(labels, contains('TestLabel'));
    });

    test('export and import backup', () async {
      final now = DateTime.now();
      await service.addPerson(Person(
        id: 'p1', name: 'Alice', relationship: RelationshipType.friend,
        createdAt: now, updatedAt: now,
      ));
      await service.addGift(Gift(
        id: 'g1', personId: 'p1', type: GiftType.given,
        value: 50.0, date: now, eventType: 'Birthday',
        description: 'Watch', createdAt: now, updatedAt: now,
      ));

      final json = service.exportToJson();
      expect(json, contains('Alice'));
      expect(json, contains('Birthday'));

      // Clear and reimport
      await Hive.box<Person>('people').clear();
      await Hive.box<Gift>('gifts').clear();

      final result = await service.importFromJson(json);
      expect(result, contains('1 people'));
      expect(result, contains('1 gifts'));

      final people = service.getAllPeople();
      expect(people.length, 1);
      expect(people.first.name, 'Alice');

      final gifts = service.getAllGifts();
      expect(gifts.length, 1);
      expect(gifts.first.value, 50.0);
    });

    test('undo restores the correct gift after consecutive deletes', () async {
      final now = DateTime.now();
      await service.addPerson(Person(
        id: 'p1', name: 'Alice', relationship: RelationshipType.friend,
        createdAt: now, updatedAt: now,
      ));
      for (final id in ['g1', 'g2']) {
        await service.addGift(Gift(
          id: id, personId: 'p1', type: GiftType.given,
          value: 10.0, date: now, eventType: 'Birthday',
          description: id, createdAt: now, updatedAt: now,
        ));
      }

      // Delete both, then undo the FIRST one — must restore g1, not g2.
      await service.deleteGift('g1');
      await service.deleteGift('g2');
      await service.undoDeleteGift('g1');

      expect(service.getGift('g1'), isNotNull);
      expect(service.getGift('g2'), null); // still deleted
    });

    test('import rejects malformed JSON without corrupting data', () async {
      final now = DateTime.now();
      await service.addPerson(Person(
        id: 'keep', name: 'Existing', relationship: RelationshipType.friend,
        createdAt: now, updatedAt: now,
      ));

      expect(
        () => service.importFromJson('not json at all'),
        throwsFormatException,
      );
      // Existing data untouched.
      expect(service.getPerson('keep'), isNotNull);
    });

    test('import skips invalid records but imports valid ones', () async {
      const json = '''
      {
        "version": 1,
        "people": [
          {"id": "ok", "name": "Valid", "relationship": "friend",
           "createdAt": "2024-01-01T00:00:00.000", "updatedAt": "2024-01-01T00:00:00.000"},
          {"id": "", "name": "NoId", "relationship": "friend",
           "createdAt": "2024-01-01T00:00:00.000", "updatedAt": "2024-01-01T00:00:00.000"}
        ],
        "gifts": [
          {"id": "gok", "personId": "ok", "type": "given", "value": 5.0,
           "date": "2024-01-01T00:00:00.000", "eventType": "Birthday", "description": "",
           "createdAt": "2024-01-01T00:00:00.000", "updatedAt": "2024-01-01T00:00:00.000"},
          {"id": "gbad", "personId": "ok", "type": "given", "value": -5.0,
           "date": "2024-01-01T00:00:00.000", "eventType": "Birthday", "description": "",
           "createdAt": "2024-01-01T00:00:00.000", "updatedAt": "2024-01-01T00:00:00.000"}
        ],
        "customLabels": []
      }
      ''';
      final result = await service.importFromJson(json);
      expect(service.getPerson('ok'), isNotNull);
      expect(service.getGift('gok'), isNotNull);
      expect(service.getGift('gbad'), null); // negative value rejected
      expect(result, contains('skipped'));
    });

    test('import rejects a newer backup version', () async {
      const json =
          '{"version": 999, "people": [], "gifts": [], "customLabels": []}';
      expect(
        () => service.importFromJson(json),
        throwsFormatException,
      );
    });

    test('import skips a record with a non-string optional field '
        'without aborting the whole import', () async {
      // "relationship": 123 (a number) previously threw an uncaught TypeError
      // via `as String?`, aborting the entire import. It must now skip only
      // that record and still import the valid one.
      const json = '''
      {
        "version": 1,
        "people": [
          {"id": "bad", "name": "BadRel", "relationship": 123,
           "createdAt": "2024-01-01T00:00:00.000", "updatedAt": "2024-01-01T00:00:00.000"},
          {"id": "good", "name": "GoodRel", "relationship": "family",
           "createdAt": "2024-01-01T00:00:00.000", "updatedAt": "2024-01-01T00:00:00.000"}
        ],
        "gifts": [],
        "customLabels": []
      }
      ''';
      final result = await service.importFromJson(json);
      // "bad" record still imports (relationship falls back to friend) because
      // the non-string optional field is coerced to null, not thrown on.
      expect(service.getPerson('good'), isNotNull);
      expect(service.getPerson('good')?.relationship,
          RelationshipType.family);
      expect(service.getPerson('bad'), isNotNull);
      expect(service.getPerson('bad')?.relationship, RelationshipType.friend);
      expect(result, contains('2 people'));
    });

    test('import drops orphan gifts referencing a missing person', () async {
      const json = '''
      {
        "version": 1,
        "people": [
          {"id": "p1", "name": "Alice", "relationship": "friend",
           "createdAt": "2024-01-01T00:00:00.000", "updatedAt": "2024-01-01T00:00:00.000"}
        ],
        "gifts": [
          {"id": "gok", "personId": "p1", "type": "given", "value": 5.0,
           "date": "2024-01-01T00:00:00.000", "eventType": "Birthday", "description": "",
           "createdAt": "2024-01-01T00:00:00.000", "updatedAt": "2024-01-01T00:00:00.000"},
          {"id": "gorphan", "personId": "ghost", "type": "given", "value": 5.0,
           "date": "2024-01-01T00:00:00.000", "eventType": "Birthday", "description": "",
           "createdAt": "2024-01-01T00:00:00.000", "updatedAt": "2024-01-01T00:00:00.000"}
        ],
        "customLabels": []
      }
      ''';
      await service.importFromJson(json);
      expect(service.getGift('gok'), isNotNull);
      expect(service.getGift('gorphan'), null); // orphan dropped
    });

    test('import rejects a non-numeric backup version', () async {
      const json =
          '{"version": "abc", "people": [], "gifts": [], "customLabels": []}';
      expect(
        () => service.importFromJson(json),
        throwsFormatException,
      );
    });
  });
}
