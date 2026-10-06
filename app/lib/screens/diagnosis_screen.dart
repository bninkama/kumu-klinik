import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../strings.dart';
import '../models/diagnosis.dart';
import '../services/api_service.dart';
import '../services/local_store.dart';
import '../services/tts_service.dart';

class DiagnosisScreen extends StatefulWidget {
  final Strings s;
  const DiagnosisScreen({super.key, required this.s});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final _picker = ImagePicker();
  Uint8List? _photoBytes;
  bool _loading = false;
  Diagnosis? _result;
  String? _error;
  bool _speaking = false;
  bool _showTpi = true; // Tok Pisin first, per spec

  Future<void> _pickAndDiagnose(ImageSource source) async {
    final photo = await _picker.pickImage(source: source, maxWidth: 1024);
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _loading = true;
      _result = null;
      _error = null;
    });
    try {
      final json = await ApiService.diagnose(
        imageBase64: base64Encode(bytes),
        mimeType: photo.mimeType ?? 'image/jpeg',
        province: LocalStore.province,
      );
      if (json['disease_name'] == 'not_crop') {
        setState(() => _error = widget.s.get('not_crop'));
        return;
      }
      final d = Diagnosis.fromJson(json);
      LocalStore.saveDiagnosis(json);
      setState(() => _result = d);
    } catch (_) {
      // Offline: queue the photo for later and tell the farmer.
      LocalStore.enqueuePhoto({
        'image_base64': base64Encode(bytes),
        'mime_type': photo.mimeType ?? 'image/jpeg',
        'location_province': LocalStore.province,
      });
      setState(() => _error = widget.s.get('offline_queued'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _speak() async {
    if (_result == null) return;
    final a = _result!.tokPisin;
    setState(() => _speaking = true);
    await TtsService.speak(
      '${_result!.diseaseName}. Wokim nau: ${a.immediateAction}. Marasin: ${a.organicTreatment}. Blom bihain: ${a.prevention}.',
    );
    if (mounted) setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.get('take_photo_sub'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_photoBytes == null) ...[
            Row(
              children: [
                Expanded(
                  child: _bigAction(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _pickAndDiagnose(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _bigAction(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickAndDiagnose(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
          if (_photoBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(_photoBytes!, height: 220, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
          ],
          if (_loading)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                const CircularProgressIndicator(strokeWidth: 6),
                const SizedBox(height: 16),
                Text(s.get('gemini_looking'),
                    style: const TextStyle(fontSize: 20)),
              ]),
            ),
          if (_error != null)
            Card(
              color: Colors.amber.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: const TextStyle(fontSize: 18)),
              ),
            ),
          if (_result != null) _resultCard(s),
        ],
      ),
    );
  }

  Widget _bigAction(
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 120,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(width: 3, color: Color(0xFF2E7D32)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 48, color: const Color(0xFF2E7D32)),
          Text(label, style: const TextStyle(fontSize: 18)),
        ]),
      ),
    );
  }

  Widget _resultCard(Strings s) {
    final d = _result!;
    final a = _showTpi ? d.tokPisin : d.english;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(d.diseaseName,
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
            _urgencyChip(d.urgency),
          ]),
          if (d.scientificName.isNotEmpty)
            Text(d.scientificName,
                style: const TextStyle(fontStyle: FontStyle.italic)),
          Text('${(d.confidence * 100).toStringAsFixed(0)}% ${s.get('confidence')}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // Language tabs + TTS
          Row(children: [
            ChoiceChip(
              label: const Text('Tok Pisin'),
              selected: _showTpi,
              onSelected: (_) => setState(() => _showTpi = true),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('English'),
              selected: !_showTpi,
              onSelected: (_) => setState(() => _showTpi = false),
            ),
            const Spacer(),
            IconButton.filled(
              iconSize: 32,
              icon: Icon(_speaking ? Icons.stop : Icons.volume_up),
              tooltip: s.get('listen_tpi'),
              onPressed: _speaking ? TtsService.stop : _speak,
            ),
          ]),
          const Divider(height: 24),
          _step(s.get('do_now'), a.immediateAction, Icons.bolt, Colors.red),
          _step(s.get('treatment'), a.organicTreatment, Icons.medication, Colors.orange),
          _step(s.get('prevention'), a.prevention, Icons.shield, Colors.green),
        ]),
      ),
    );
  }

  Widget _step(String title, String body, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(body, style: const TextStyle(fontSize: 18, height: 1.4)),
          ]),
        ),
      ]),
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
