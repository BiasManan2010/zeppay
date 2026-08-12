import 'dart:convert';

import 'package:http/http.dart' as http;

class FxService {
  FxService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Map<String, double>> rates({String base = 'INR'}) async {
    final uri = Uri.parse('https://open.er-api.com/v6/latest/$base');
    final res = await _client.get(uri);
    if (res.statusCode >= 400) {
      throw Exception('FX unavailable');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final rates = Map<String, dynamic>.from(body['rates'] as Map);
    return rates.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<double> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    if (from == to) return amount;
    final r = await rates(base: from);
    return amount * (r[to] ?? 1);
  }
}
