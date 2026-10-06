import 'package:flutter/material.dart';
import '../strings.dart';
import '../models/diagnosis.dart';
import '../services/local_store.dart';
import '../services/api_service.dart';
import 'diagnosis_screen.dart';

class HomeScreen extends StatefulWidget {
  final Strings s;
  const HomeScreen({super.key, required this.s});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _weather;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final w = await ApiService.weather(LocalStore.province);
      if (mounted) setState(() => _weather = w);
    } catch (_) {/* offline: card hidden */}
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final history = LocalStore.history().take(3).toList();
    final alert = _weather?['alert'];

    return RefreshIndicator(
      onRefresh: _loadWeather,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Big camera button — the hero action.
          SizedBox(
            height: 140,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.camera_alt, size: 56),
              label: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.get('take_photo'),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(s.get('take_photo_sub'), style: const TextStyle(fontSize: 16)),
                ],
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DiagnosisScreen(s: s)),
              ).then((_) => setState(() {})),
            ),
          ),
          const SizedBox(height: 16),

          // Weather alert card
          if (alert != null)
            Card(
              color: Colors.orange.shade100,
              child: ListTile(
                leading: const Icon(Icons.thunderstorm, size: 40, color: Colors.orange),
                title: Text(s.get('weather_alert'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  s.lang == 'en' ? alert['message_en'] : alert['message_tpi'],
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ),

          const SizedBox(height: 16),
          Text(s.get('recent_diagnoses'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Icon(Icons.eco, size: 64, color: Colors.black26)
          else
            ...history.map((h) {
              final d = Diagnosis.fromJson(h);
              return Card(
                child: ListTile(
                  leading: Icon(
                    d.diseaseName.toLowerCase().contains('healthy')
                        ? Icons.check_circle
                        : Icons.coronavirus,
                    size: 36,
                    color: d.diseaseName.toLowerCase().contains('healthy')
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: Text(d.diseaseName),
                  subtitle: Text(
                      '${(d.confidence * 100).toStringAsFixed(0)}% ${s.get('confidence')}'),
                  trailing: _urgencyChip(d.urgency),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _urgencyChip(String u) {
    final color = switch (u) {
      'high' => Colors.red,
      'medium' => Colors.orange,
      _ => Colors.green,
    };
    return Chip(
      label: Text(u.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: color,
    );
  }
}
