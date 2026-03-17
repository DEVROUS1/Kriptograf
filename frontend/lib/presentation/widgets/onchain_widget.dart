import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';

final onchainProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final url = Uri.parse('${AppConfig.httpBaseUrl}/api/onchain');
  final res = await http.get(url).timeout(const Duration(seconds: 15));
  return json.decode(res.body) as Map<String, dynamic>;
});

class OnchainWidget extends ConsumerWidget {
  const OnchainWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(onchainProvider);

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
                decoration: const BoxDecoration(color: Color(0xFF00D68F), shape: BoxShape.circle)),
            const SizedBox(width: 7),
            const Text('ON-CHAIN METRİKLER',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: Color(0xFF5a6080), letterSpacing: 0.8)),
            const Spacer(),
            dataAsync.when(
              data: (d) => Text(d['guncelleme'] as String,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF3a3d55))),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ]),
        ),
        dataAsync.when(
          data: (d) => _Body(data: d),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(12),
            child: Text('On-chain verisi alınamadı',
                style: TextStyle(color: AppTheme.bearish, fontSize: 11)),
          ),
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
    final mvrv = data['mvrv'] as Map<String, dynamic>;
    final nupl = data['nupl'] as Map<String, dynamic>;
    final fg = data['fear_greed'] as Map<String, dynamic>;
    final btc = data['btc'] as Map<String, dynamic>;
    final evre = data['piyasa_evresi'] as String;
    final dominance = (data['btc_dominance'] as num).toDouble();

    final mvrvDeger = (mvrv['deger'] as num).toDouble();
    final nuplDeger = (nupl['deger'] as num).toDouble();

    final mvrvColor = switch (mvrv['renk'] as String) {
      'KIRMIZI' => AppTheme.bearish,
      'TURUNCU' => const Color(0xFFFF8C42),
      'YESIL' => AppTheme.bullish,
      _ => const Color(0xFF0099ff),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Piyasa evresi
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(evre,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),

        // MVRV
        _MetrikKart(
          baslik: 'MVRV',
          deger: mvrvDeger.toStringAsFixed(2),
          alt: mvrv['yorum'] as String,
          color: mvrvColor,
          progress: (mvrvDeger / 4.0).clamp(0.0, 1.0),
          aciklama: 'Realized Price: \$${(mvrv['realized_price'] as num).toStringAsFixed(0)}',
        ),
        const SizedBox(height: 8),

        // NUPL
        _MetrikKart(
          baslik: 'NUPL',
          deger: nuplDeger.toStringAsFixed(3),
          alt: nupl['yorum'] as String,
          color: nuplDeger > 0 ? AppTheme.bullish : AppTheme.bearish,
          progress: ((nuplDeger + 1) / 2).clamp(0.0, 1.0),
          zone: nupl['zone'] as String,
        ),
        const SizedBox(height: 12),

        // ATH'dan uzaklık
        Row(children: [
          Expanded(
            child: _MiniKart(
              etiket: 'ATH\'dan Uzaklık',
              deger: '-%${(btc['ath_uzaklik_yuzde'] as num).toStringAsFixed(1)}',
              color: AppTheme.bearish,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MiniKart(
              etiket: 'BTC Dominance',
              deger: '%${dominance.toStringAsFixed(1)}',
              color: AppTheme.primary,
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Fear & Greed trend
        const Text('KORKU/AÇGÖZLÜLÜK TRENDI (7 GÜN)',
            style: TextStyle(fontSize: 9, color: Color(0xFF5a6080),
                fontWeight: FontWeight.w700, letterSpacing: 0.7)),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: (fg['haftalik'] as List).reversed.toList()
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(),
                          (e.value as num).toDouble()))
                      .toList(),
                  isCurved: true,
                  color: AppTheme.warning,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.warning.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('7g önce: ${(fg['haftalik'] as List).last}',
              style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.3))),
          Text('30g ort: ${(fg['aylik_ortalama'] as num).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 9, color: Color(0xFF5a6080))),
          Text('Bugün: ${fg['guncel']}',
              style: TextStyle(fontSize: 9, color: AppTheme.warning, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

class _MetrikKart extends StatelessWidget {
  const _MetrikKart({
    required this.baslik,
    required this.deger,
    required this.alt,
    required this.color,
    required this.progress,
    this.aciklama,
    this.zone,
  });
  final String baslik;
  final String deger;
  final String alt;
  final Color color;
  final double progress;
  final String? aciklama;
  final String? zone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(baslik,
              style: const TextStyle(fontSize: 10, color: Color(0xFF8890b0), fontWeight: FontWeight.w700)),
          const Spacer(),
          if (zone != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(zone!,
                  style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
            ),
        ]),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(deger,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(alt,
                  style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        // Skala barı
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ]),
        if (aciklama != null) ...[
          const SizedBox(height: 6),
          Text(aciklama!,
              style: const TextStyle(fontSize: 10, color: Color(0xFF5a6080))),
        ],
      ]),
    );
  }
}

class _MiniKart extends StatelessWidget {
  const _MiniKart({required this.etiket, required this.deger, required this.color});
  final String etiket;
  final String deger;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(etiket, style: const TextStyle(fontSize: 9, color: Color(0xFF6b6f8e))),
        const SizedBox(height: 3),
        Text(deger,
            style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
