import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Prefer the app backend wrapper so we get normalized fields and fallback rules.
  static const String apiUrl = 'https://api-pa2tyrfh6q-uc.a.run.app';
  static const String legacyModelUrl =
      'https://trustguardai-api.onrender.com/predict';

  static Future<Map<String, dynamic>> analyzeTransaction(
      Map<String, dynamic> data) async {
    final endpoints = <String>[
      '$apiUrl/analyze',
      '$apiUrl/predict',
      legacyModelUrl,
    ];

    Object? lastError;
    for (final endpoint in endpoints) {
      try {
        final response = await _postJson(endpoint, data);
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            return _normalizeAnalysisResponse(decoded, endpoint, data);
          }
          return {
            'error': 'Unexpected response format from $endpoint',
          };
        }
        lastError = 'Server error: ${response.statusCode} ${response.body}';
      } catch (e) {
        lastError = e;
      }
    }

    return {'error': lastError?.toString() ?? 'Unable to analyze transaction'};
  }

  static Future<Map<String, dynamic>> predictTransaction(
      Map<String, dynamic> data) async {
    final url = Uri.parse('$apiUrl/predict');

    try {
      final response = await _postJson(url.toString(), data);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return _normalizeAnalysisResponse(decoded, url.toString(), data);
        }
        return {'error': 'Unexpected response format from $url'};
      } else {
        return {'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<http.Response> _postJson(
    String url,
    Map<String, dynamic> data,
  ) {
    return http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  static Map<String, dynamic> _normalizeAnalysisResponse(
    Map<String, dynamic> raw,
    String endpoint,
    Map<String, dynamic> requestData,
  ) {
    final explicitScore = _extractScore(raw);
    final score = explicitScore ?? _buildFallbackScore(requestData);
    final status = _extractStatus(raw, score);
    final reasons = _extractReasons(raw);

    return {
      ...raw,
      'risk_score': score,
      'status': status,
      'reasons': reasons,
      'score_source': explicitScore != null ? 'backend' : 'fallback_rules',
      'source_endpoint': endpoint,
    };
  }

  static int? _extractScore(Map<String, dynamic> raw) {
    final strongCandidates = [
      raw['risk_score'],
      raw['riskScore'],
      raw['score'],
      raw['fraud_score'],
      raw['fraudScore'],
    ];

    for (final value in strongCandidates) {
      final parsed = _parseScoreValue(value, allowBinaryFraction: true);
      if (parsed != null) return parsed;
    }

    final weakCandidates = [
      raw['probability'],
      raw['confidence'],
      raw['fraud_probability'],
      raw['fraudProbability'],
    ];

    for (final value in weakCandidates) {
      final parsed = _parseScoreValue(value, allowBinaryFraction: false);
      if (parsed != null) return parsed;
    }

    return null;
  }

  static int? _parseScoreValue(
    dynamic value, {
    required bool allowBinaryFraction,
  }) {
    if (value == null) return null;
    if (value is num) {
      if (!allowBinaryFraction && (value == 0 || value == 1)) {
        return null;
      }
      final normalized = value >= 0 && value <= 1 ? value * 100 : value;
      return normalized.round().clamp(0, 100).toInt();
    }

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final cleaned = text.replaceAll('%', '');
    final asNum = num.tryParse(cleaned);
    if (asNum != null) {
      if (!allowBinaryFraction && (asNum == 0 || asNum == 1)) {
        return null;
      }
      final normalized = asNum >= 0 && asNum <= 1 ? asNum * 100 : asNum;
      return normalized.round().clamp(0, 100).toInt();
    }

    return null;
  }

  static String _extractStatus(Map<String, dynamic> raw, int score) {
    final status = raw['status'] ?? raw['decision'] ?? raw['label'];
    final text = status?.toString().toUpperCase() ?? '';
    if (text.contains('BLOCK')) return 'BLOCKED';
    if (text.contains('FLAG') || text.contains('REVIEW')) return 'FLAGGED';
    if (text.contains('APPROV') || text.contains('ALLOW')) return 'APPROVED';

    final prediction = raw['prediction'];
    if (prediction == 1 || prediction == true) return 'BLOCKED';
    if (score >= 70) return 'BLOCKED';
    if (score >= 35) return 'FLAGGED';
    return 'APPROVED';
  }

  static int _buildFallbackScore(Map<String, dynamic> data) {
    final amount = _numValue(data['amount']);
    final device = (data['device'] ?? 'known').toString();
    final location = (data['location'] ?? 'home').toString();
    final time = (data['time'] ?? 'business').toString();
    final merchant = (data['merchant'] ?? 'regular').toString();

    var riskScore = 5;

    if (amount > 3000) {
      riskScore += 45;
    } else if (amount > 1000) {
      riskScore += 28;
    } else if (amount > 300) {
      riskScore += 14;
    }

    if (device == 'suspicious') {
      riskScore += 38;
    } else if (device == 'newDevice') {
      riskScore += 20;
    }

    if (location == 'vpn') {
      riskScore += 32;
    } else if (location == 'foreign') {
      riskScore += 24;
    } else if (location == 'nearby') {
      riskScore += 9;
    }

    if (time == 'lateNight') {
      riskScore += 18;
    } else if (time == 'evening') {
      riskScore += 5;
    }

    if (merchant == 'highRisk') {
      riskScore += 20;
    } else if (merchant == 'newMerchant') {
      riskScore += 8;
    }

    return riskScore.clamp(0, 99).toInt();
  }

  static double _numValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _extractReasons(Map<String, dynamic> raw) {
    final reasonSources = [
      raw['reasons'],
      raw['explanation'],
      raw['alerts'],
      raw['features'],
    ];

    for (final source in reasonSources) {
      if (source is List) {
        return source
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }

    final message = raw['message']?.toString();
    if (message != null && message.isNotEmpty) {
      return [message];
    }

    return const [];
  }
}
