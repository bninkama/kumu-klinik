import 'dart:convert';
import 'package:http/http.dart' as http;

// Talks to the Cloud Run backend. All calls fail fast so the app can
// fall back to offline behaviour.
class ApiService {
  // Override with --dart-define=API_BASE=https://your-cloud-run-url
  static const baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:8080', // Android emulator -> localhost
  );

  static Future<Map<String, dynamic>> diagnose({
    required String imageBase64,
    String mimeType = 'image/jpeg',
    String? province,
    String? cropType,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/diagnose'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'image_base64': imageBase64,
            'mime_type': mimeType,
            'location_province': province,
            'crop_type': cropType,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('diagnose failed: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> weather(String province) async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/weather?province=$province'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('weather ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> prices() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/prices'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('prices ${res.statusCode}');
    return (jsonDecode(res.body)['prices'] as List);
  }

  static Future<List<dynamic>> diseases() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/diseases'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('diseases ${res.statusCode}');
    return (jsonDecode(res.body)['diseases'] as List);
  }
}
