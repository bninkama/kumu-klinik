import 'package:flutter_test/flutter_test.dart';
import 'package:kumu_klinic/strings.dart';
import 'package:kumu_klinic/models/diagnosis.dart';

void main() {
  group('Strings', () {
    test('Tok Pisin strings resolve', () {
      const s = Strings('tpi');
      expect(s.get('take_photo'), 'TEKIM PIKSA BILONG KUMU');
      expect(s.get('do_now'), 'Wokim nau');
    });

    test('unknown key falls back to English then key', () {
      const s = Strings('tpi');
      expect(s.get('nonexistent_key'), 'nonexistent_key');
    });
  });

  group('Diagnosis.fromJson', () {
    test('parses backend response', () {
      final d = Diagnosis.fromJson({
        'disease_name': 'Black Pod',
        'confidence_score': 0.92,
        'scientific_name': 'Phytophthora palmivora',
        'crop': 'cocoa',
        'urgency': 'high',
        'english': {'immediate_action': 'Remove pods'},
        'tok_pisin': {'immediate_action': 'Rausim kumu'},
      });
      expect(d.diseaseName, 'Black Pod');
      expect(d.confidence, closeTo(0.92, 0.001));
      expect(d.urgency, 'high');
      expect(d.tokPisin.immediateAction, 'Rausim kumu');
      expect(d.english.immediateAction, 'Remove pods');
    });

    test('handles missing fields', () {
      final d = Diagnosis.fromJson({});
      expect(d.diseaseName, 'unknown');
      expect(d.confidence, 0);
    });
  });
}
