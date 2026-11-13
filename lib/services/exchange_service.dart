import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeService {
  static const _baseUrl = 'https://open.er-api.com/v6/latest';

  /// Returns {"EUR": 0.92, "TND": 3.1, ...} for the given base currency.
  Future<Map<String, double>> fetchRates(String base) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/$base'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Server error (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['result'] != 'success') {
      throw Exception('API returned an error');
    }

    final rates = data['rates'] as Map<String, dynamic>;
    return rates.map((code, value) => MapEntry(code, (value as num).toDouble()));
  }
}