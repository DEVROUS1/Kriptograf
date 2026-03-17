import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../data/models/ai_summary_model.dart';
import '../../data/models/signal_model.dart';
import 'api_provider.dart';
import 'selected_coin_provider.dart';

// Riverpod Extension for Memory Caching (Tutulan veriyi 60 sn sonra çöpe atar)
extension AutoDisposeRefExtension on Ref {
  void keepAliveFor(Duration duration) {
    final keepAliveLink = keepAlive();
    Timer(duration, () => keepAliveLink.close());
  }
}

final aiSummaryProvider = FutureProvider.autoDispose<AiSummaryModel>((ref) async {
  // Coin değişimlerini dinle
  final coin = ref.watch(selectedCoinProvider);
  
  // Önceki coinler/sekmeler için veriyi 60 saniye boyunca bellekte (RAM) tut.
  ref.keepAliveFor(const Duration(seconds: 60));

  final dio = ref.watch(dioProvider);
  final cancelToken = CancelToken();

  // İstek atıldığında coin değişirse (Provider dispose olursa), eski isteği anında iptal et!
  ref.onDispose(() => cancelToken.cancel('User changed coin or left screen'));

  final url = '${AppConfig.httpBaseUrl}/api/ai-ozet/${coin.symbol.toUpperCase()}';
  
  try {
    final res = await dio.get(url, cancelToken: cancelToken);
    return AiSummaryModel.fromJson(res.data as Map<String, dynamic>);
  } on DioException catch (e) {
    if (CancelToken.isCancel(e)) throw Exception('İstek iptal edildi');
    throw Exception('AI özeti alınamadı: \${e.message}');
  }
});

final signalProvider = FutureProvider.autoDispose<SignalModel>((ref) async {
  final coin = ref.watch(selectedCoinProvider);
  ref.keepAliveFor(const Duration(seconds: 60));
  
  final dio = ref.watch(dioProvider);
  final cancelToken = CancelToken();
  ref.onDispose(() => cancelToken.cancel());

  final url = '${AppConfig.httpBaseUrl}/api/sinyal/${coin.symbol.toUpperCase()}';
  
  try {
    final res = await dio.get(url, cancelToken: cancelToken);
    return SignalModel.fromJson(res.data as Map<String, dynamic>);
  } on DioException catch (e) {
    if (CancelToken.isCancel(e)) throw Exception('İstek iptal edildi');
    throw Exception('Sinyal alınamadı: \${e.message}');
  }
});

final anomalyProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final coin = ref.watch(selectedCoinProvider);
  ref.keepAliveFor(const Duration(seconds: 60));
  
  final dio = ref.watch(dioProvider);
  final cancelToken = CancelToken();
  ref.onDispose(() => cancelToken.cancel());

  final url = '${AppConfig.httpBaseUrl}/api/anomali/${coin.symbol.toUpperCase()}';
  
  try {
    final res = await dio.get(url, cancelToken: cancelToken);
    return res.data as Map<String, dynamic>;
  } catch (e) {
    return {"durum": "hata", "mesaj": e.toString()};
  }
});

final newsSentimentProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.keepAliveFor(const Duration(seconds: 120)); // Haberler statiktir, daha uzun tutulur
  
  final dio = ref.watch(dioProvider);
  final cancelToken = CancelToken();
  ref.onDispose(() => cancelToken.cancel());

  final url = '${AppConfig.httpBaseUrl}/api/haber-duygu';
  try {
    final res = await dio.get(url, cancelToken: cancelToken);
    return res.data as Map<String, dynamic>;
  } catch (e) {
    return {"durum": "hata", "mesaj": e.toString()};
  }
});