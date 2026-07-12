// Seeds the app with realistic sample data and captures screenshots of every
// main screen for visual/polish review. NOT a correctness gate — it exists to
// produce eyeballable images of the populated app.
//
// Run with:
//   flutter test integration_test/screenshot_sweep_test.dart -d <device-id>
//
// Screenshots are written to the test's build dir; their paths print at the end.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:gift_exchange/models/person.dart';
import 'package:gift_exchange/models/gift.dart';
import 'package:gift_exchange/models/relationship_type.dart';
import 'package:gift_exchange/models/gift_type.dart';
import 'package:gift_exchange/main.dart';
import 'package:gift_exchange/services/gift_service.dart';

const _shotDir = '/tmp/gx-screenshots';

Future<void> _shot(IntegrationTestWidgetsFlutterBinding binding, String name) async {
  final bytes = await binding.takeScreenshot(name);
  final f = File('$_shotDir/$name');
  await f.writeAsBytes(bytes);
  debugPrint('WROTE_SHOT=$f');
}

Future<void> _seed(GiftService service) async {
  await service.addPerson(Person(
    id: '',
    name: 'Mom',
    relationship: RelationshipType.family,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  ));
  await service.addPerson(Person(
    id: '',
    name: 'Sarah',
    relationship: RelationshipType.friend,
    createdAt: DateTime(2025, 1, 2),
    updatedAt: DateTime(2025, 1, 2),
  ));
  await service.addPerson(Person(
    id: '',
    name: 'Alex',
    relationship: RelationshipType.colleague,
    createdAt: DateTime(2025, 1, 3),
    updatedAt: DateTime(2025, 1, 3),
  ));

  String idFor(String name) =>
      service.getAllPeople().firstWhere((p) => p.name == name).id;

  final mom = idFor('Mom');
  final sarah = idFor('Sarah');
  final alex = idFor('Alex');

  final now = DateTime.now();
  Future<void> gift(String pid, GiftType t, double v, String desc, String ev,
      DateTime d) async {
    await service.addGift(Gift(
      id: '',
      personId: pid,
      type: t,
      value: v,
      description: desc,
      eventType: ev,
      date: d,
      createdAt: now,
      updatedAt: now,
    ));
  }

  await gift(mom, GiftType.given, 120, 'Cash Gift', 'Birthday',
      DateTime(now.year, now.month, 3));
  await gift(mom, GiftType.received, 85, 'Sweater', 'Christmas',
      DateTime(now.year - 1, 12, 25));
  await gift(mom, GiftType.given, 60, 'Flowers', 'Birthday',
      DateTime(now.year - 1, now.month, 3));
  await gift(sarah, GiftType.received, 45, 'Book', 'Birthday',
      DateTime(now.year, now.month, 10));
  await gift(sarah, GiftType.given, 30, 'Lunch', 'Other',
      DateTime(now.year, now.month, 1));
  await gift(alex, GiftType.given, 25, 'Coffee Mug', 'Other',
      DateTime(now.year, now.month, 5));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final binding = IntegrationTestWidgetsFlutterBinding.instance;

  setUpAll(() async {
    final dir = await getApplicationDocumentsDirectory();
    final testPath = Directory('${dir.path}/screenshot_hive');
    if (testPath.existsSync()) testPath.deleteSync(recursive: true);
    testPath.createSync(recursive: true);
    Hive.init(testPath.path);
    if (!Hive.isAdapterRegistered(RelationshipTypeAdapter().typeId)) {
      Hive.registerAdapter(RelationshipTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(GiftTypeAdapter().typeId)) {
      Hive.registerAdapter(GiftTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(PersonAdapter().typeId)) {
      Hive.registerAdapter(PersonAdapter());
    }
    if (!Hive.isAdapterRegistered(GiftAdapter().typeId)) {
      Hive.registerAdapter(GiftAdapter());
    }
  });

  testWidgets('capture populated screens', (tester) async {
    await Hive.openBox<Person>('people');
    await Hive.openBox<Gift>('gifts');
    await Hive.openBox<String>('custom_event_labels');
    final service = GiftService();
    await _seed(service);

    await tester.pumpWidget(const ProviderScopedApp());
    await tester.pumpAndSettle();

    final out = Directory(_shotDir);
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    // 1. People list (populated)
    await _shot(binding, '01-people.png');

    // 2. Person detail (Mom) — expand the top event group
    await tester.tap(find.text('Mom'));
    await tester.pumpAndSettle();
    // Expand the largest-volume group if collapsed.
    final expandFinder = find.byIcon(Icons.expand_more);
    if (expandFinder.evaluate().isNotEmpty) {
      await tester.tap(expandFinder.first);
      await tester.pumpAndSettle();
    }
    await _shot(binding, '02-person-detail.png');

    // Pop back to the People list so the bottom nav bar is available.
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    // 3. History
    await tester.tap(find.widgetWithText(NavigationDestination, 'History'));
    await tester.pumpAndSettle();
    await _shot(binding, '03-history.png');

    // 4. Analysis
    await tester.tap(find.widgetWithText(NavigationDestination, 'Analysis'));
    await tester.pumpAndSettle();
    await _shot(binding, '04-analysis.png');

    debugPrint('SCREENSHOTS_WRITTEN_TO=$_shotDir');
    await Hive.close();
  });
}
