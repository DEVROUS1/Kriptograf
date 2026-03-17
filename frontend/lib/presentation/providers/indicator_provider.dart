import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/models/fear_greed_model.dart';
import '../../config/app_config.dart';

final fearGreedProvider = FutureProvider<List<FearGreedModel>>((ref) async {
  try {
    final response = await http.get(Uri.parse('${AppConfig.backendHttpUrl}/api/korku-acgozluluk'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FearGreedModel.fromJson(json)).toList();
    }
  } catch (_) {}
  return [];
});

final stressIndexProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final response = await http.get(Uri.parse('${AppConfig.backendHttpUrl}/api/stres-endeksi'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
  } catch (_) {}
  return {
    "score": 50,
    "label": "STABIL",
    "components": {
        "volatility": 50,
        "fear_greed_stress": 50,
        "volume_anomaly": 50
    }
  };
});
