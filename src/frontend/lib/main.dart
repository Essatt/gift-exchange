import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/person.dart';
import 'models/gift.dart';
import 'models/relationship_type.dart';
import 'models/gift_type.dart';
import 'features/people/presentation/pages/people_page.dart';
import 'features/gifts/presentation/pages/gift_exchange_page.dart';
import 'features/analysis/presentation/pages/analysis_page.dart';

Future<List<int>> _getEncryptionKey() async {
  const storage = FlutterSecureStorage();
  const key = 'hive_encryption_key';
  final existing = await storage.read(key: key);
  if (existing != null) {
    return base64Url.decode(existing);
  }
  final newKey = Hive.generateSecureKey();
  await storage.write(key: key, value: base64UrlEncode(newKey));
  return newKey;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

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

  final encryptionKey = await _getEncryptionKey();
  final cipher = HiveAesCipher(encryptionKey);

  await Hive.openBox<Person>('people', encryptionCipher: cipher);
  await Hive.openBox<Gift>('gifts', encryptionCipher: cipher);

  runApp(const ProviderScope(child: GiftExchangeApp()));
}

class GiftExchangeApp extends StatelessWidget {
  const GiftExchangeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gift Exchange',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6750A4),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          shape: CircleBorder(),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    PeoplePage(),
    GiftExchangePage(),
    AnalysisPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        height: 80,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'People',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard_rounded),
            label: 'Exchange',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Analysis',
          ),
        ],
      ),
    );
  }
}
