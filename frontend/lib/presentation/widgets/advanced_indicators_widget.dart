import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../providers/selected_coin_provider.dart';

final advancedIndicatorsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final coin = ref.watch(selectedCoinProvider);
  final url = Uri.parse(
      '${AppConfig.httpBaseUrl}/api/indikatorler/${coin.symbol.toUpperCase()}');
  final res = await http.get(url).timeout(const Duration(seconds: 12));
  return json.decode(res.body) as Map<String, dynamic>;
});

class AdvancedIndicatorsWidget extends ConsumerWidget {
  const AdvancedIndicatorsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(advancedIndicatorsProvider);

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
                decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
            const SizedBox(width: 7),
            const Text('GELİŞMİŞ İNDİKATÖRLER',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: Color(0xFF5a6080), letterSpacing: 0.8)),
            const Spacer(),
            dataAsync.when(
              data: (d) {
                final sinyal = d['genel_sinyal'] as String;
                final skor = (d['genel_skor'] as num).toInt();
                final color = skor >= 60 ? AppTheme.bullish : skor <= 40 ? AppTheme.bearish : AppTheme.warning;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(sinyal, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ]),
        ),
        dataAsync.when(
          data: (d) => _Body(data: d),
          loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (e, _) => const Padding(
              padding: EdgeInsets.all(12),
              child: Text('İndikatörler alınamadı',
                  style: TextStyle(color: AppTheme.bearish, fontSize: 11))),
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
    final rsi = (data['rsi'] as num).toDouble();
    final macd = data['macd'] as Map<String, dynamic>;
    final bb = data['bollinger'] as Map<String, dynamic>;
    final stoch = data['stoch_rsi'] as Map<String, dynamic>;
    final ema = data['ema'] as Map<String, dynamic>;
    final cci = (data['cci'] as num).toDouble();
    final wr = (data['williams_r'] as num).toDouble();
    final ich = data['ichimoku'] as Map<String, dynamic>;
    final atr = data['atr'] as Map<String, dynamic>;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(children: [
        // RSI
        _IndRow(
          label: 'RSI (14)',
          value: rsi.toStringAsFixed(1),
          badge: data['rsi_yorum'] as String,
          badgeColor: rsi < 30 ? AppTheme.bullish : rsi > 70 ? AppTheme.bearish : AppTheme.warning,
          progress: rsi / 100,
        ),
        // Stoch RSI
        _IndRow(
          label: 'Stoch RSI',
          value: 'K:${(stoch['k'] as num).toStringAsFixed(0)} D:${(stoch['d'] as num).toStringAsFixed(0)}',
          badge: stoch['yorum'] as String,
          badgeColor: (stoch['k'] as num) < 20 ? AppTheme.bullish : (stoch['k'] as num) > 80 ? AppTheme.bearish : AppTheme.warning,
        ),
        // MACD
        _IndRow(
          label: 'MACD',
          value: (macd['histogram'] as num).toStringAsFixed(4),
          badge: (macd['histogram'] as num) > 0 ? 'Yükseliş' : 'Düşüş',
          badgeColor: (macd['histogram'] as num) > 0 ? AppTheme.bullish : AppTheme.bearish,
        ),
        // CCI
        _IndRow(
          label: 'CCI (20)',
          value: cci.toStringAsFixed(1),
          badge: cci > 100 ? 'Aşırı Alım' : cci < -100 ? 'Aşırı Satım' : 'Nötr',
          badgeColor: cci > 100 ? AppTheme.bearish : cci < -100 ? AppTheme.bullish : AppTheme.warning,
        ),
        // Williams %R
        _IndRow(
          label: 'Williams %R',
          value: wr.toStringAsFixed(1),
          badge: wr > -20 ? 'Aşırı Alım' : wr < -80 ? 'Aşırı Satım' : 'Nötr',
          badgeColor: wr > -20 ? AppTheme.bearish : wr < -80 ? AppTheme.bullish : AppTheme.warning,
        ),
        // Bollinger
        _IndRow(
          label: 'Bollinger',
          value: 'Genişlik: %${(bb['genislik'] as num).toStringAsFixed(1)}',
          badge: bb['pozisyon'] as String,
          badgeColor: (bb['pozisyon'] as String) == 'UST' ? AppTheme.bearish :
                      (bb['pozisyon'] as String) == 'ALT' ? AppTheme.bullish : AppTheme.warning,
        ),
        // ATR
        _IndRow(
          label: 'ATR (14)',
          value: '%${(atr['yuzde'] as num).toStringAsFixed(2)} volatilite',
        ),
        // EMA Trend
        _IndRow(
          label: 'EMA Trend',
          value: 'EMA50: \$${_fmt((ema['ema50'] as num).toDouble())}',
          badge: ema['trend'] as String,
          badgeColor: (ema['trend'] as String) == 'YUKSELIS' ? AppTheme.bullish : AppTheme.bearish,
        ),
        // Ichimoku
        _IndRow(
          label: 'Ichimoku Bulutu',
          value: ich['bulut_rengi'] as String,
          badge: (ich['fiyat_bulut_ustu'] as bool) ? 'Bulut Üstü' : 'Bulut Altı',
          badgeColor: (ich['fiyat_bulut_ustu'] as bool) ? AppTheme.bullish : AppTheme.bearish,
        ),
        // OBV
        _IndRow(
          label: 'OBV Trendi',
          value: data['obv_trend'] as String,
          badge: data['obv_trend'] as String,
          badgeColor: (data['obv_trend'] as String) == 'YUKSELIS' ? AppTheme.bullish : AppTheme.bearish,
        ),
      ]),
    );
  }

  String _fmt(double v) {
    if (v >= 10000) return v.toStringAsFixed(0);
    if (v >= 1) return v.toStringAsFixed(2);
    return v.toStringAsFixed(6);
  }
}

class _IndRow extends StatelessWidget {
  const _IndRow({
    required this.label,
    required this.value,
    this.badge,
    this.badgeColor,
    this.progress,
  });
  final String label;
  final String value;
  final String? badge;
  final Color? badgeColor;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: const TextStyle(color: Color(0xFF8B8FA8), fontSize: 11)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? Colors.grey).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(badge!,
                  style: TextStyle(fontSize: 9, color: badgeColor ?? Colors.grey, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        if (progress != null) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress!.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(
                progress! < 0.3 ? AppTheme.bullish : progress! > 0.7 ? AppTheme.bearish : AppTheme.warning,
              ),
              minHeight: 3,
            ),
          ),
        ],
        Container(height: 0.5, color: Colors.white.withValues(alpha: 0.04),
            margin: const EdgeInsets.only(top: 5)),
      ]),
    );
  }
}
