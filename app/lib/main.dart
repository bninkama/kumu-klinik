import 'package:flutter/material.dart';
import 'strings.dart';
import 'services/local_store.dart';
import 'services/tts_service.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/weather_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.init();
  await TtsService.init();
  runApp(const KumuKlinicApp());
}

class KumuKlinicApp extends StatefulWidget {
  const KumuKlinicApp({super.key});

  @override
  State<KumuKlinicApp> createState() => _KumuKlinicAppState();
}

class _KumuKlinicAppState extends State<KumuKlinicApp> {
  String _lang = LocalStore.language;

  void setLanguage(String lang) {
    setState(() => _lang = lang);
    LocalStore.language = lang;
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings(_lang);
    return MaterialApp(
      title: 'Kumu Klinic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF795548), // earth brown
        ),
        // Large fonts + high contrast for outdoor use / sun glare.
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 19, height: 1.4),
          bodyMedium: TextStyle(fontSize: 17, height: 1.4),
        ),
      ),
      home: Shell(strings: s, onLanguageChanged: setLanguage, lang: _lang),
    );
  }
}

class Shell extends StatefulWidget {
  final Strings strings;
  final String lang;
  final void Function(String) onLanguageChanged;

  const Shell({
    super.key,
    required this.strings,
    required this.lang,
    required this.onLanguageChanged,
  });

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final screens = [
      HomeScreen(s: s),
      LibraryScreen(s: s),
      WeatherScreen(s: s),
    ];
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home, size: 32),
            label: s.get('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book, size: 32),
            label: s.get('library'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.wb_sunny, size: 32),
            label: s.get('weather_market'),
          ),
        ],
      ),
      appBar: AppBar(
        title: Text(s.get('app_title')),
        actions: [
          // Language switcher: cycles EN -> TP -> HO
          TextButton(
            onPressed: () {
              const order = ['tpi', 'en', 'ho'];
              final next = order[(order.indexOf(widget.lang) + 1) % order.length];
              widget.onLanguageChanged(next);
            },
            child: Text(
              {'tpi': 'TOK PISIN', 'en': 'ENGLISH', 'ho': 'HIRI MOTU'}[widget.lang]!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
