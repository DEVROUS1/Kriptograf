import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../providers/selected_coin_provider.dart';

final spreadProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final coin = ref.watch(selectedCoinProvider);
  final sym = coin.symbol.toUpperCase().replaceAll('USDT', '');
  final url = Uri.parse('${AppConfig.httpBaseUrl}/api/spread/$sym');
  final res = await http.get(url).timeout(const Duration(seconds: 8));
  return json.decode(res.body) as Map<String, dynamic>;
});

class SpreadWidget extends ConsumerWidget {
  const SpreadWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(spreadProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: AppTheme.warning, shape: BoxShape.circle)),
                const SizedBox(width: 7),
                const Text('ARBİTRAJ RADARI — BORSA SPREAD',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: Color(0xFF5a6080), letterSpacing: 0.8)),
              ],
            ),
          ),
          dataAsync.when(
            data: (d) => _SpreadBody(data: d),
            loading: () => const SizedBox(height: 80,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, _) => const SizedBox(height: 40),
          ),
        ],
      ),
    );
  }
}

class _SpreadBody extends StatelessWidget {
  const _SpreadBody({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final borsalar = (data['borsalar'] as Map<String, dynamic>);
    final firsat = data['firsat'] as bool;
    final spreadYuzde = (data['spread_yuzde'] as num).toDouble();
    final enUcuz = data['en_ucuz'] as String?;
    final enPahali = data['en_pahali'] as String?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        children: [
          // Borsa fiyatları
          ...borsalar.entries.map((e) {
            final isMin = e.key == enUcuz;
            final isMax = e.key == enPahali;
            final color = isMin ? AppTheme.bullish : isMax ? AppTheme.bearish : Colors.white70;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 20,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(e.key,
                        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Text('\$${(e.value as num).toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (isMin) Text('EN UCUZ',
                      style: TextStyle(fontSize: 9, color: AppTheme.bullish, fontWeight: FontWeight.w700)),
                  if (isMax) Text('EN PAHALI',
                      style: TextStyle(fontSize: 9, color: AppTheme.bearish, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          // Spread özeti
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: firsat
                  ? AppTheme.warning.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: firsat
                    ? AppTheme.warning.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SPREAD', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
                    Text('\$${data['spread_usd']}  (%${spreadYuzde.toStringAsFixed(4)})',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: firsat ? AppTheme.warning : Colors.white70,
                        )),
                  ],
                ),
                if (firsat)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('ARBİTRAJ FIRSATI',
                        style: TextStyle(fontSize: 9, color: AppTheme.warning, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
