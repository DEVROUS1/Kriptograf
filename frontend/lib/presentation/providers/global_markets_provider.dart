import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../data/models/global_market_model.dart';
import '../../data/models/portfolio_model.dart';

// ── Küresel piyasalar ──────────────────────────────────────────────────────

final globalMarketsProvider =
    FutureProvider.autoDispose<GlobalMarketsModel>((ref) async {
  final url = Uri.parse('${AppConfig.httpBaseUrl}/api/kuresel-piyasalar');
  final res = await http.get(url).timeout(const Duration(seconds: 15));
  if (res.statusCode != 200) throw Exception('Piyasa verisi alınamadı');
  return GlobalMarketsModel.fromJson(
      json.decode(res.body) as Map<String, dynamic>);
});

final correlationProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final url = Uri.parse('${AppConfig.httpBaseUrl}/api/korelasyon');
  final res = await http.get(url).timeout(const Duration(seconds: 15));
  return json.decode(res.body) as Map<String, dynamic>;
});

// ── Portföy (Backend REST API) ─────────────────────────────────────────────

class PortfolioNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async => _yukle();

  Future<List<Map<String, dynamic>>> _yukle() async {
    try {
      final url = Uri.parse('${AppConfig.httpBaseUrl}/api/portfoy');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final list = json.decode(res.body) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> ekle(String sembol, double miktar, double alisFiyati) async {
    try {
      final url = Uri.parse('${AppConfig.httpBaseUrl}/api/portfoy');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sembol': sembol.toUpperCase(),
          'miktar': miktar,
          'alis_fiyati': alisFiyati,
        }),
      ).timeout(const Duration(seconds: 10));
      ref.invalidateSelf();
    } catch (_) {}
  }

  Future<void> sil(String id) async {
    try {
      final url = Uri.parse('${AppConfig.httpBaseUrl}/api/portfoy/$id');
      await http.delete(url).timeout(const Duration(seconds: 10));
      ref.invalidateSelf();
    } catch (_) {}
  }
}

final portfolioNotifierProvider =
    AsyncNotifierProvider<PortfolioNotifier, List<Map<String, dynamic>>>(
  PortfolioNotifier.new,
);

final portfolioValueProvider =
    FutureProvider.autoDispose<PortfolioModel>((ref) async {
  final varliklar = await ref.watch(portfolioNotifierProvider.future);
  if (varliklar.isEmpty) {
    return const PortfolioModel(
        varliklar: [], toplamUsd: 0, toplamTl: 0, usdTry: 0);
  }

  // USD/TRY oranını küresel piyasalardan al
  double usdTry = 32.0;
  try {
    final gmUrl = Uri.parse('${AppConfig.httpBaseUrl}/api/kuresel-piyasalar');
    final gmRes = await http.get(gmUrl).timeout(const Duration(seconds: 8));
    final gmData = json.decode(gmRes.body) as Map<String, dynamic>;
    usdTry =
        ((gmData['turkiye']['usd_try']['fiyat'] as num?) ?? 32.0).toDouble();
  } catch (_) {}

  // Backend'deki /api/portfoy-hesapla endpoint'ine kayıtlı varlıkları gönder
  final payload = varliklar
      .map((k) => {
            'sembol': k['sembol'],
            'miktar': k['miktar'],
            'alis_fiyati': k['alis_fiyati'],
          })
      .toList();

  final url = Uri.parse('${AppConfig.httpBaseUrl}/api/portfoy-hesapla');
  final res = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'varliklar': payload, 'usd_try': usdTry}),
  ).timeout(const Duration(seconds: 10));

  return PortfolioModel.fromJson(
      json.decode(res.body) as Map<String, dynamic>);
});

// ── Fiyat alarmları (Backend REST API) ───────────────────────────────────

class AlarmNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async => _yukle();

  Future<List<Map<String, dynamic>>> _yukle() async {
    try {
      final url = Uri.parse('${AppConfig.httpBaseUrl}/api/alarmlar');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final list = json.decode(res.body) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> ekle({
    required String sembol,
    required double hedefFiyat,
    required String yon,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.httpBaseUrl}/api/alarmlar');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sembol': sembol.toUpperCase(),
          'hedef_fiyat': hedefFiyat,
          'yon': yon,
        }),
      ).timeout(const Duration(seconds: 10));
      ref.invalidateSelf();
    } catch (_) {}
  }

  Future<void> sil(String id) async {
    try {
      final url = Uri.parse('${AppConfig.httpBaseUrl}/api/alarmlar/$id');
      await http.delete(url).timeout(const Duration(seconds: 10));
      ref.invalidateSelf();
    } catch (_) {}
  }
}

final alarmProvider =
    AsyncNotifierProvider<AlarmNotifier, List<Map<String, dynamic>>>(
  AlarmNotifier.new,
);
