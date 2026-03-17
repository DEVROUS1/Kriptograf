import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../providers/selected_coin_provider.dart';

final stressIndexProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final coin = ref.watch(selectedCoinProvider);
  // Stres endeksini anomali + sinyal verilerinden hesapla
  final anomalyUrl = Uri.parse(
    '${AppConfig.httpBaseUrl}/api/anomali/${coin.symbol.toUpperCase()}',
  );
  final signalUrl = Uri.parse(
    '${AppConfig.httpBaseUrl}/api/sinyal/${coin.symbol.toUpperCase()}',
  );

  final results = await Future.wait([
    http.get(anomalyUrl).timeout(const Duration(seconds: 8)),
    http.get(signalUrl).timeout(const Duration(seconds: 8)),
  ]);

  final anomaly = json.decode(results[0].body) as Map<String, dynamic>;
  final signal = json.decode(results[1].body) as Map<String, dynamic>;

  // Stres skoru hesapla
  int puan = 0;
  final siddet = anomaly['siddet']?.toString() ?? 'NORMAL';
  if (siddet == 'KRİTİK') {
    puan += 60;
  } else if (siddet == 'DİKKAT') {
    puan += 30;
  }

  int signalGuc = 50;
  if (signal['guc'] is num) {
    signalGuc = (signal['guc'] as num).toInt();
  } else if (signal['guc'] is String) {
    signalGuc = int.tryParse(signal['guc'].toString()) ?? 50;
  }
  
  if (signalGuc <= 25) {
    puan += 30;
  } else if (signalGuc >= 75) {
    puan += 10;
  }

  int anomaliSayisi = 0;
  if (anomaly['anomaliler'] is List) {
    anomaliSayisi = (anomaly['anomaliler'] as List).length;
  }
  puan += (anomaliSayisi * 10).clamp(0, 30);
  puan = puan.clamp(0, 100);

  String etiket;
  if (puan < 30) {
    etiket = 'STABİL';
  } else if (puan < 60) {
    etiket = 'DİKKATLİ';
  } else {
    etiket = 'KRİTİK';
  }

  return {'puan': puan, 'etiket': etiket, 'siddet': siddet};
});

class StressIndexWidget extends ConsumerWidget {
  const StressIndexWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(stressIndexProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle)),
            const SizedBox(width: 7),
            const Text('STRES ENDEKSİ',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: Color(0xFF5a6080), letterSpacing: 0.8)),
            const Spacer(),
            dataAsync.when(
              data: (d) {
                final etiket = d['etiket'] as String;
                final color = etiket == 'STABİL'
                    ? AppTheme.bullish
                    : etiket == 'DİKKATLİ'
                        ? AppTheme.warning
                        : AppTheme.bearish;
                return Text(etiket,
                    style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w800));
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ]),
          const SizedBox(height: 10),
          dataAsync.when(
            data: (d) {
              final puan = (d['puan'] as num).toInt();
              final color = puan < 30
                  ? AppTheme.bullish
                  : puan < 60
                      ? AppTheme.warning
                      : AppTheme.bearish;
              return Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: puan / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.2))),
                    Text('$puan', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                    Text('100', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.2))),
                  ],
                ),
              ]);
            },
            loading: () => const LinearProgressIndicator(minHeight: 8),
            error: (_, __) => const SizedBox(height: 8),
          ),
        ],
      ),
    );
  }
}
