import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/models/news_model.dart';
import '../../config/app_config.dart';

final newsProvider = FutureProvider<List<NewsModel>>((ref) async {
  try {
    final response = await http.get(Uri.parse('${AppConfig.backendHttpUrl}/api/haberler'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => NewsModel.fromJson(json)).toList();
    }
  } catch (_) {
    // fallback
  }
  return [];
});
