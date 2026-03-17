import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../providers/selected_coin_provider.dart';

final srProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final coin = ref.watch(selectedCoinProvider);
  final url = Uri.parse('${AppConfig.httpBaseUrl}/api/destek-direnc/${coin.symbol.toUpperCase()}');
  final res = await http.get(url).timeout(const Duration(seconds: 12));
  return json.decode(res.body) as Map<String, dynamic>;
});

class SupportResistanceWidget extends ConsumerWidget {
  const SupportResistanceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(srProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: Color(0xFFFFD32A), shape: BoxShape.circle)),
            const SizedBox(width: 7),
            const Text('DESTEK & DİRENÇ SEVİYELERİ',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: Color(0xFF5a6080), letterSpacing: 0.8)),
          ]),
        ),
        dataAsync.when(
          data: (d) => _Body(data: d),
          loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (e, _) => const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Veri alınamadı', style: TextStyle(color: AppTheme.bearish, fontSize: 11))),
        ),
      ]),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final guncel = (data['guncel_fiyat'] as num).toDouble();
    final direngler = (data['direngler'] as List).cast<Map<String, dynamic>>();
    final destekler = (data['destekler'] as List).cast<Map<String, dynamic>>();
    final fib = data['fibonacci'] as Map<String, dynamic>;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Güncel fiyat çizgisi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Güncel Fiyat', style: TextStyle(fontSize: 11, color: Color(0xFF8890b0))),
            Text('\$${_fmt(guncel)}',
                style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 10),

        // Direnç seviyeleri
        const Text('DİRENÇ', style: TextStyle(fontSize: 9, color: Color(0xFF5a6080),
            fontWeight: FontWeight.w700, letterSpacing: 0.7)),
        const SizedBox(height: 6),
        ...direngler.map((s) => _SeviyeSatiri(seviye: s, isDirenc: true)),

        const SizedBox(height: 10),

        // Destek seviyeleri
        const Text('DESTEK', style: TextStyle(fontSize: 9, color: Color(0xFF5a6080),
            fontWeight: FontWeight.w700, letterSpacing: 0.7)),
        const SizedBox(height: 6),
        ...destekler.map((s) => _SeviyeSatiri(seviye: s, isDirenc: false)),

        const SizedBox(height: 10),

        // Fibonacci seviyeleri
        const Text('FİBONACCİ', style: TextStyle(fontSize: 9, color: Color(0xFF5a6080),
            fontWeight: FontWeight.w700, letterSpacing: 0.7)),
        const SizedBox(height: 6),
        ...fib.entries.where((e) => e.key != '0' && e.key != '1').map((e) {
          final fibFiyat = (e.value as num).toDouble();
          final yakin = (fibFiyat - guncel).abs() / guncel * 100 < 3;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Fib ${e.key}', style: const TextStyle(fontSize: 11, color: Color(0xFF6b6f8e))),
              Text('\$${_fmt(fibFiyat)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: yakin ? AppTheme.warning : Colors.white70,
                      fontWeight: yakin ? FontWeight.w700 : FontWeight.w400)),
            ]),
          );
        }),
      ]),
    );
  }

  String _fmt(double v) {
    if (v >= 10000) return v.toStringAsFixed(0);
    if (v >= 1) return v.toStringAsFixed(2);
    return v.toStringAsFixed(6);
  }
}

class _SeviyeSatiri extends StatelessWidget {
  const _SeviyeSatiri({required this.seviye, required this.isDirenc});
  final Map<String, dynamic> seviye;
  final bool isDirenc;

  @override
  Widget build(BuildContext context) {
    final fiyat = (seviye['fiyat'] as num).toDouble();
    final guc = seviye['guc'] as String;
    final dokunma = seviye['dokunma'] as int;
    final mesafe = (seviye['mesafe_yuzde'] as num).toDouble();
    final color = isDirenc ? AppTheme.bearish : AppTheme.bullish;

    final gucRenk = switch (guc) {
      'COK_GUCLU' => const Color(0xFFFF4757),
      'GUCLU' => const Color(0xFFFF8C42),
      'ORTA' => const Color(0xFFFFD32A),
      _ => const Color(0xFF6b6f8e),
    };

    final gucYuzde = switch (guc) {
      'COK_GUCLU' => 1.0,
      'GUCLU' => 0.75,
      'ORTA' => 0.5,
      _ => 0.25,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          // Güç barı
          SizedBox(
            width: 3,
            height: 32,
            child: Column(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: gucRenk,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('\$${_fmt(fiyat)}',
                  style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: gucRenk.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(guc.replaceAll('_', ' '),
                      style: TextStyle(fontSize: 8, color: gucRenk, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                Text('$dokunma test', style: const TextStyle(fontSize: 9, color: Color(0xFF5a6080))),
              ]),
            ]),
          ),
          Text('%${mesafe.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 10, color: Color(0xFF5a6080))),
        ]),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 10000) return v.toStringAsFixed(0);
    if (v >= 1) return v.toStringAsFixed(2);
    return v.toStringAsFixed(6);
  }
}
