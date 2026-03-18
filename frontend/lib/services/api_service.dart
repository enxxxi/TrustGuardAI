import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Deployed backend endpoints
  static const String analyzeUrl =
      'https://trustguard-api.onrender.com/predict';
  static const String apiUrl = 'https://api-pa2tyrfh6q-uc.a.run.app';

  // Analyze transaction
  static Future<Map<String, dynamic>> analyzeTransaction(Map<String, dynamic> data) async {
    final url = Uri.parse(analyzeUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'error':
              'Server error: ${response.statusCode} ${response.body}',
        };
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Predict (if you have another endpoint)
  static Future<Map<String, dynamic>> predictTransaction(Map<String, dynamic> data) async {
    final url = Uri.parse('$apiUrl/predict');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
