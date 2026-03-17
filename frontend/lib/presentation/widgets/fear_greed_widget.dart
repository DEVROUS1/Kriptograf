import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';

final fearGreedProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final url = Uri.parse('https://api.alternative.me/fng/?limit=7');
  final res = await http.get(url).timeout(const Duration(seconds: 8));
  final data = (json.decode(res.body)['data'] as List).cast<Map<String, dynamic>>();
  return {
    'bugun': int.parse(data[0]['value'].toString()),
    'etiket': data[0]['value_classification'].toString(),
    'haftalik': data.map((d) => int.parse(d['value'].toString())).toList(),
  };
});

class FearGreedWidget extends ConsumerWidget {
  const FearGreedWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(fearGreedProvider);

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
                decoration: BoxDecoration(color: AppTheme.warning, shape: BoxShape.circle)),
            const SizedBox(width: 7),
            const Text('KORKU / AÇGÖZLÜLÜK',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: Color(0xFF5a6080), letterSpacing: 0.8)),
          ]),
          const SizedBox(height: 12),
          dataAsync.when(
            data: (d) => _Body(data: d),
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox(height: 40),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final deger = data['bugun'] as int;
    final etiket = _turkceEtiket(data['etiket'] as String);
    final haftalik = (data['haftalik'] as List).cast<int>();

    final color = deger < 25
        ? AppTheme.bearish
        : deger < 45
            ? const Color(0xFFFF8C42)
            : deger < 55
                ? AppTheme.warning
                : deger < 75
                    ? const Color(0xFF7BC67E)
                    : AppTheme.bullish;

    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      // Dairesel gösterge
      SizedBox(
        width: 80,
        height: 80,
        child: Stack(alignment: Alignment.center, children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              sections: [
                PieChartSectionData(
                  value: deger.toDouble(),
                  color: color,
                  radius: 12,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: (100 - deger).toDouble(),
                  color: Colors.white.withValues(alpha: 0.06),
                  radius: 12,
                  showTitle: false,
                ),
              ],
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$deger',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text(etiket,
                style: TextStyle(
                    fontSize: 8, color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ]),
        ]),
      ),
      const SizedBox(width: 16),
      // 7 günlük mini trend
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('7 Günlük Trend',
                style: TextStyle(fontSize: 9, color: Color(0xFF5a6080))),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: haftalik.reversed.toList().asMap().entries.map((e) =>
                          FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${haftalik.last} (7g)',
                    style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.3))),
                Text('${haftalik.first} (bugün)',
                    style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7))),
              ],
            ),
          ],
        ),
      ),
    ]);
  }

  String _turkceEtiket(String en) => switch (en.toLowerCase()) {
        'extreme fear' => 'AŞIRI KORKU',
        'fear' => 'KORKU',
        'neutral' => 'NÖTR',
        'greed' => 'AÇGÖZLÜLÜK',
        'extreme greed' => 'AŞIRI AÇGÖZLÜLÜK',
        _ => en.toUpperCase(),
      };
}
