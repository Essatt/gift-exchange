import 'package:flutter_test/flutter_test.dart';
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

      await service.undoDeletePerson();
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

      await service.undoDeleteGift();
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
  });
}
