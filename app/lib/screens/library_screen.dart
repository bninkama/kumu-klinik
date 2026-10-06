import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../strings.dart';
import '../models/diagnosis.dart';
import '../services/api_service.dart';
import '../services/local_store.dart';
import '../services/tts_service.dart';

class LibraryScreen extends StatefulWidget {
  final Strings s;
  const LibraryScreen({super.key, required this.s});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Disease> _diseases = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Offline-first: bundled asset -> Hive cache -> network refresh.
    List<Map<String, dynamic>> data = LocalStore.diseases();
    if (data.isEmpty) {
      final raw = await rootBundle.loadString('assets/diseases.json');
      data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      LocalStore.cacheDiseases(data);
    }
    if (mounted) {
      setState(() => _diseases = data.map(Disease.fromJson).toList());
    }
    // Try to refresh from the API in the background.
    try {
      final remote = await ApiService.diseases();
      LocalStore.cacheDiseases(remote.cast<Map<String, dynamic>>());
      if (mounted) {
        setState(() => _diseases =
            remote.map((e) => Disease.fromJson(e as Map<String, dynamic>)).toList());
      }
    } catch (_) {/* stay offline */}
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final isTpi = s.lang != 'en';
    return Scaffold(
      appBar: AppBar(title: Text(s.get('disease_library'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _diseases.length,
        itemBuilder: (_, i) {
          final d = _diseases[i];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2E7D32),
                child: const Icon(Icons.eco, color: Colors.white, size: 30),
              ),
              title: Text(isTpi && d.nameTpi.isNotEmpty ? d.nameTpi : d.nameEn,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              subtitle: Text(d.crop.toUpperCase()),
              trailing: const Icon(Icons.chevron_right, size: 32),
              onTap: () => _showDetail(d),
            ),
          );
        },
      ),
    );
  }

  void _showDetail(Disease d) {
    final s = widget.s;
    final isTpi = s.lang != 'en';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  isTpi && d.nameTpi.isNotEmpty ? d.nameTpi : d.nameEn,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton.filled(
                iconSize: 32,
                icon: const Icon(Icons.volume_up),
                onPressed: () => TtsService.speak(
                  '${d.nameTpi}. ${s.get('symptoms')}: ${d.symptomsTpi}. ${s.get('treatment')}: ${d.treatmentTpi}.',
                ),
              ),
            ]),
            if (d.scientificName.isNotEmpty)
              Text(d.scientificName,
                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16)),
            const SizedBox(height: 12),
            _section(s.get('symptoms'), isTpi && d.symptomsTpi.isNotEmpty ? d.symptomsTpi : d.symptoms),
            _section(s.get('treatment'), isTpi && d.treatmentTpi.isNotEmpty ? d.treatmentTpi : d.treatmentEn),
            _section(s.get('prevention'), isTpi && d.preventionTpi.isNotEmpty ? d.preventionTpi : d.preventionEn),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    if (body.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        const SizedBox(height: 4),
        Text(body, style: const TextStyle(fontSize: 18, height: 1.45)),
      ]),
    );
  }
}
