import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

// Hive-backed offline store: diagnosis history, disease library cache,
// pending photo queue, language + province preferences.
class LocalStore {
  static const _historyBox = 'history';
  static const _diseaseBox = 'diseases';
  static const _queueBox = 'pending';
  static const _prefsBox = 'prefs';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<String>(_historyBox),
      Hive.openBox<String>(_diseaseBox),
      Hive.openBox<String>(_queueBox),
      Hive.openBox<String>(_prefsBox),
    ]);
  }

  static Box<String> get _history => Hive.box<String>(_historyBox);
  static Box<String> get _diseases => Hive.box<String>(_diseaseBox);
  static Box<String> get _queue => Hive.box<String>(_queueBox);
  static Box<String> get _prefs => Hive.box<String>(_prefsBox);

  // --- diagnosis history ---
  static void saveDiagnosis(Map<String, dynamic> d) =>
      _history.add(jsonEncode(d));

  static List<Map<String, dynamic>> history() => _history.values
      .map((s) => jsonDecode(s) as Map<String, dynamic>)
      .toList()
      .reversed
      .toList();

  // --- disease library (offline cache) ---
  static void cacheDiseases(List<Map<String, dynamic>> list) =>
      _diseases.put('all', jsonEncode(list));

  static List<Map<String, dynamic>> diseases() {
    final s = _diseases.get('all');
    if (s == null) return [];
    return (jsonDecode(s) as List).cast<Map<String, dynamic>>();
  }

  // --- offline diagnosis queue ---
  static void enqueuePhoto(Map<String, dynamic> req) =>
      _queue.add(jsonEncode(req));

  static List<Map<String, dynamic>> pendingPhotos() => _queue.values
      .map((s) => jsonDecode(s) as Map<String, dynamic>)
      .toList();

  static void clearPending() => _queue.clear();

  // --- prefs ---
  static String get language => _prefs.get('language') ?? 'tpi';
  static set language(String v) => _prefs.put('language', v);

  static String get province => _prefs.get('province') ?? 'Morobe';
  static set province(String v) => _prefs.put('province', v);
}
