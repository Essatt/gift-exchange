// End-to-end CRUD smoke test driving the real UI on a device/simulator.
//
// Covers the flows unit tests cannot: tapping through dialogs, navigation,
// list rendering, undo SnackBars, and the empty-state action button. Runs the
// app against a real (temp) Hive store so persistence behaves as in production.
//
// Run with:
//   flutter test integration_test/app_crud_test.dart -d <device-id>
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

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScopedApp());
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Use a clean, isolated Hive dir so runs are deterministic and never touch
    // real user data. Boxes are opened unencrypted here — this test exercises UI
    // + persistence flows, not the encryption path (unit-tested separately).
    final dir = await getApplicationDocumentsDirectory();
    final testPath = Directory('${dir.path}/integration_test_hive');
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

  setUp(() async {
    // Fresh boxes for every test so ordering never matters.
    await Hive.deleteBoxFromDisk('people');
    await Hive.deleteBoxFromDisk('gifts');
    await Hive.deleteBoxFromDisk('custom_event_labels');
    await Hive.openBox<Person>('people');
    await Hive.openBox<Gift>('gifts');
    await Hive.openBox<String>('custom_event_labels');
  });

  tearDown(() async {
    await Hive.close();
  });

  testWidgets('People empty state renders with Add Person action', (
    tester,
  ) async {
    await _pumpApp(tester);
    expect(find.text('No people added yet'), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'Add Person'), findsOneWidget);
  });

  testWidgets('Add a person via the dialog and see it in the list', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Person'));
    await tester.pumpAndSettle();

    expect(find.text('Add Person'), findsWidgets); // dialog title + button
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Alice',
    );
    // Relationship defaults to Family; just save.
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    // Back on the list, the new person appears and the empty state is gone.
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('No people added yet'), findsNothing);
  });

  testWidgets('Edit a person\'s name via the card menu', (tester) async {
    await _pumpApp(tester);

    // Add first.
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Person'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Bob');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    // Open the card's popup menu and choose Edit.
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Bobby',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Bobby'), findsOneWidget);
    expect(find.text('Bob'), findsNothing);
  });

  testWidgets('Delete a person and undo restores them', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Person'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Carol');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Confirm dialog -> Delete.
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Carol'), findsNothing);

    // Undo from the SnackBar restores.
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Carol'), findsOneWidget);
  });

  testWidgets('Add a gift to a person and see it reflected', (tester) async {
    await _pumpApp(tester);

    // Add person.
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Person'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Dana');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    // Open person detail.
    await tester.tap(find.text('Dana'));
    await tester.pumpAndSettle();

    // Tap the add-gift FAB (the plain FAB on the detail page).
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Watch',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Value'),
      '50',
    );
    // The gift dialog's save button is a FilledButton.icon labelled 'Save'.
    // The .icon variant isn't matched by widgetWithText(FilledButton, ...),
    // so tap the label text directly.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Back on the detail page the gift is grouped under a collapsible event
    // card showing "1 gift". Confirm the group appeared, then expand it and
    // verify the gift description is shown.
    expect(find.text('1 gift'), findsOneWidget);
    await tester.tap(find.text('1 gift'));
    await tester.pumpAndSettle();
    expect(find.text('Watch'), findsOneWidget);
  });

  testWidgets('Nav bar switches between People, History and Analysis', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'History'));
    await tester.pumpAndSettle();
    expect(find.text('No exchanges recorded yet'), findsOneWidget);
    // Empty-state action routes back to People. The button is a
    // FilledButton.tonalIcon, so assert/tap on its label text directly.
    expect(find.text('Add People First'), findsOneWidget);
    await tester.tap(find.text('Add People First'));
    await tester.pumpAndSettle();
    expect(find.text('No people added yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Analysis'));
    await tester.pumpAndSettle();
    // Analysis screen exists and rendered without throwing.
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
