import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../data/models/ai_summary_model.dart';
import '../../data/models/signal_model.dart';
import 'selected_coin_provider.dart';

final aiSummaryProvider = FutureProvider.autoDispose<AiSummaryModel>((ref) async {
  final coin = ref.watch(selectedCoinProvider);
  final url = Uri.parse(
    '${AppConfig.httpBaseUrl}/api/ai-ozet/${coin.symbol.toUpperCase()}',
  );
  final res = await http.get(url).timeout(const Duration(seconds: 25));
  if (res.statusCode != 200) throw Exception('AI özeti alınamadı');
  return AiSummaryModel.fromJson(json.decode(res.body) as Map<String, dynamic>);
});

final signalProvider = FutureProvider.autoDispose<SignalModel>((ref) async {
  final coin = ref.watch(selectedCoinProvider);
  final url = Uri.parse(
    '${AppConfig.httpBaseUrl}/api/sinyal/${coin.symbol.toUpperCase()}',
  );
  final res = await http.get(url).timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) throw Exception('Sinyal alınamadı');
  return SignalModel.fromJson(json.decode(res.body) as Map<String, dynamic>);
});

final anomalyProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final coin = ref.watch(selectedCoinProvider);
  final url = Uri.parse(
    '${AppConfig.httpBaseUrl}/api/anomali/${coin.symbol.toUpperCase()}',
  );
  final res = await http.get(url).timeout(const Duration(seconds: 10));
  return json.decode(res.body) as Map<String, dynamic>;
});

final newsSentimentProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final url = Uri.parse('${AppConfig.httpBaseUrl}/api/haber-duygu');
  final res = await http.get(url).timeout(const Duration(seconds: 15));
  return json.decode(res.body) as Map<String, dynamic>;
});