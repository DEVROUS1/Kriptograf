import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../data/models/whale_model.dart';
import 'selected_coin_provider.dart';

final whaleProvider = FutureProvider.autoDispose<WhaleStatsModel>((ref) async {
  final coin = ref.watch(selectedCoinProvider);
  final symbol = coin.symbol.toUpperCase();
  final url = Uri.parse('${AppConfig.httpBaseUrl}/api/balinalar/$symbol');
  final res = await http.get(url).timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) throw Exception('Balina verisi alınamadı');
  return WhaleStatsModel.fromJson(json.decode(res.body) as Map<String, dynamic>);
});

// Otomatik yenile — her 15 saniyede
final whaleAutoRefreshProvider = Provider.autoDispose((ref) {
  ref.watch(whaleProvider);
  Future.delayed(const Duration(seconds: 15), () {
    ref.invalidate(whaleProvider);
  });
});
