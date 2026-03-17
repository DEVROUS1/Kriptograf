import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

// ── Portföy (SharedPreferences ile yerel saklama) ──────────────────────────

class PortfolioNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  PortfolioNotifier() : super([]) {
    _yukle();
  }

  Future<void> _yukle() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('portfoy');
    if (raw != null) {
      state = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    }
  }

  Future<void> _kaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('portfoy', json.encode(state));
  }

  void ekle(String sembol, double miktar) {
    final index = state.indexWhere(
        (v) => v['sembol'].toString().toUpperCase() == sembol.toUpperCase());
    if (index >= 0) {
      final yeni = List<Map<String, dynamic>>.from(state);
      yeni[index] = {'sembol': sembol.toUpperCase(), 'miktar': miktar};
      state = yeni;
    } else {
      state = [
        ...state,
        {'sembol': sembol.toUpperCase(), 'miktar': miktar}
      ];
    }
    _kaydet();
  }

  void sil(String sembol) {
    state = state
        .where((v) => v['sembol'].toString().toUpperCase() != sembol.toUpperCase())
        .toList();
    _kaydet();
  }
}

final portfolioNotifierProvider =
    StateNotifierProvider<PortfolioNotifier, List<Map<String, dynamic>>>(
  (ref) => PortfolioNotifier(),
);

final portfolioValueProvider =
    FutureProvider.autoDispose<PortfolioModel>((ref) async {
  final varliklar = ref.watch(portfolioNotifierProvider);
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
    usdTry = ((gmData['turkiye']['usd_try']['fiyat'] as num?) ?? 32.0).toDouble();
  } catch (_) {}

  final url = Uri.parse('${AppConfig.httpBaseUrl}/api/portfoy-hesapla');
  final res = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'varliklar': varliklar, 'usd_try': usdTry}),
  ).timeout(const Duration(seconds: 10));

  return PortfolioModel.fromJson(json.decode(res.body) as Map<String, dynamic>);
});

// ── Fiyat alarmları (yerel) ────────────────────────────────────────────────

class AlarmNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  AlarmNotifier() : super([]) {
    _yukle();
  }

  Future<void> _yukle() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('alarmlar');
    if (raw != null) {
      state = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    }
  }

  Future<void> _kaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarmlar', json.encode(state));
  }

  void ekle({
    required String sembol,
    required double hedefFiyat,
    required String yon,
  }) {
    state = [
      ...state,
      {
        'sembol': sembol.toUpperCase(),
        'hedef': hedefFiyat,
        'yon': yon,
        'aktif': true,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      }
    ];
    _kaydet();
  }

  void sil(String id) {
    state = state.where((a) => a['id'] != id).toList();
    _kaydet();
  }
}

final alarmProvider =
    StateNotifierProvider<AlarmNotifier, List<Map<String, dynamic>>>(
  (ref) => AlarmNotifier(),
);
