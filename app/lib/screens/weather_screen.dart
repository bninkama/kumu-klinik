import 'package:flutter/material.dart';
import '../strings.dart';
import '../services/api_service.dart';
import '../services/local_store.dart';

class WeatherScreen extends StatefulWidget {
  final Strings s;
  const WeatherScreen({super.key, required this.s});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? _weather;
  List<dynamic> _prices = [];
  bool _offline = false;
  late String _province = LocalStore.province;

  static const _provinces = [
    'Port Moresby', 'Morobe', 'Eastern Highlands', 'Western Highlands',
    'East New Britain', 'Madang', 'East Sepik', 'Bougainville',
    'Milne Bay', 'Oro', 'Simbu', 'Enga', 'Hela',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _offline = false);
    try {
      final results = await Future.wait([
        ApiService.weather(_province),
        ApiService.prices(),
      ]);
      if (mounted) {
        setState(() {
          _weather = results[0] as Map<String, dynamic>;
          _prices = results[1] as List<dynamic>;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _offline = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final isTpi = s.lang != 'en';
    return Scaffold(
      appBar: AppBar(title: Text(s.get('weather_market'))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Province picker
            DropdownButtonFormField<String>(
              initialValue: _provinces.contains(_province) ? _province : 'Morobe',
              decoration: InputDecoration(
                labelText: 'Province / Provins',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.green.shade50,
              ),
              items: _provinces
                  .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 18))))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _province = v);
                LocalStore.province = v;
                _load();
              },
            ),
            const SizedBox(height: 16),
            if (_offline)
              Card(
                color: Colors.grey.shade200,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No internet — cannot load weather. / Intanet i nogat.',
                      style: TextStyle(fontSize: 17)),
                ),
              ),
            Text(s.get('forecast'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_weather != null)
              ...(_weather!['forecast'] as List).map((f) => Card(
                    child: ListTile(
                      leading: Icon(
                        (f['rain_chance_pct'] ?? 0) >= 70
                            ? Icons.thunderstorm
                            : (f['rain_chance_pct'] ?? 0) >= 40
                                ? Icons.cloud
                                : Icons.wb_sunny,
                        size: 40,
                        color: (f['rain_chance_pct'] ?? 0) >= 70
                            ? Colors.blue.shade800
                            : Colors.orange,
                      ),
                      title: Text('${f['date']} — ${f['temp_c']}°C',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${f['condition']} • ${f['rain_chance_pct']}% rain\n'
                        '${isTpi ? f['advisory_tpi'] : f['advisory_en']}',
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                      isThreeLine: true,
                    ),
                  )),
            const SizedBox(height: 16),
            Text(s.get('market_prices'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ..._prices.map((p) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.storefront, size: 36, color: Color(0xFF795548)),
                    title: Text(p['crop'], style: const TextStyle(fontSize: 18)),
                    subtitle: Text(p['market'] ?? ''),
                    trailing: Text('K${p['price_kina']}/${p['unit']}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32))),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
