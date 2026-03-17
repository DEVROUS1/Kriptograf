import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../providers/selected_coin_provider.dart';

final cvdProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final coin = ref.watch(selectedCoinProvider);
  final url = Uri.parse('${AppConfig.httpBaseUrl}/api/cvd/${coin.symbol.toUpperCase()}');
  final res = await http.get(url).timeout(const Duration(seconds: 8));
  return json.decode(res.body) as Map<String, dynamic>;
});

class CvdWidget extends ConsumerWidget {
  const CvdWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(cvdProvider);

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                const SizedBox(width: 7),
                const Text('CVD — KÜMÜLATİF HACİM DELTA',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: Color(0xFF5a6080), letterSpacing: 0.8)),
                const Spacer(),
                dataAsync.when(
                  data: (d) {
                    final alis = d['alis_baskisi'] as bool;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (alis ? AppTheme.bullish : AppTheme.bearish).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(alis ? 'ALIŞ BASKISI' : 'SATIŞ BASKISI',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: alis ? AppTheme.bullish : AppTheme.bearish,
                          )),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),
          Expanded(
            child: dataAsync.when(
              data: (d) => _CvdChart(data: d),
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(
                child: Text('CVD verisi alınamadı',
                    style: TextStyle(color: AppTheme.bearish, fontSize: 11)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CvdChart extends StatelessWidget {
  const _CvdChart({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final veri = (data['veri'] as List).cast<Map<String, dynamic>>();
    if (veri.isEmpty) return const SizedBox();

    final spots = veri.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['kumulatif'] as num).toDouble());
    }).toList();

    final isPositive = (data['alis_baskisi'] as bool);
    final lineColor = isPositive ? AppTheme.bullish : AppTheme.bearish;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: null,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 0.5,
            ),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
