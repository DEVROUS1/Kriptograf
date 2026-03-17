import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../providers/selected_coin_provider.dart';

final liquidityProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final coin = ref.watch(selectedCoinProvider);
  final url = Uri.parse('${AppConfig.httpBaseUrl}/api/derinlik/${coin.symbol.toUpperCase()}');
  final res = await http.get(url).timeout(const Duration(seconds: 8));
  return json.decode(res.body) as Map<String, dynamic>;
});

class LiquidityHeatmapWidget extends ConsumerWidget {
  const LiquidityHeatmapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(liquidityProvider);

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
                    decoration: const BoxDecoration(color: AppTheme.warning, shape: BoxShape.circle)),
                const SizedBox(width: 7),
                const Text('LİKİDİTE ISISI — ORDER BOOK',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: Color(0xFF5a6080), letterSpacing: 0.8)),
              ],
            ),
          ),
          dataAsync.when(
            data: (data) => _HeatmapBody(data: data),
            loading: () => const SizedBox(height: 80,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, _) => const SizedBox(height: 40),
          ),
        ],
      ),
    );
  }
}

class _HeatmapBody extends StatelessWidget {
  const _HeatmapBody({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final alis = (data['alis_duvarlari'] as List).cast<Map<String, dynamic>>();
    final satis = (data['satis_duvarlari'] as List).cast<Map<String, dynamic>>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _WallColumn(title: 'DESTEK (ALIŞ)', walls: alis, color: AppTheme.bullish)),
              const SizedBox(width: 8),
              Expanded(child: _WallColumn(title: 'DİRENÇ (SATIŞ)', walls: satis, color: AppTheme.bearish)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoChip(label: 'En Güçlü Destek',
                  value: '\$${(data['en_guclu_destek'] as num).toStringAsFixed(0)}',
                  color: AppTheme.bullish),
              _InfoChip(label: 'En Güçlü Direnç',
                  value: '\$${(data['en_guclu_direnc'] as num).toStringAsFixed(0)}',
                  color: AppTheme.bearish),
            ],
          ),
        ],
      ),
    );
  }
}

class _WallColumn extends StatelessWidget {
  const _WallColumn({required this.title, required this.walls, required this.color});
  final String title;
  final List<Map<String, dynamic>> walls;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7),
            fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ...walls.take(5).map((w) {
          final yogunluk = (w['yogunluk'] as num).toDouble() / 100;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: yogunluk.clamp(0.05, 1.0),
                        child: Container(
                          height: 18,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.25 + yogunluk * 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('\$${(w['fiyat'] as num).toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 9, color: Colors.white70)),
                              Text((w['miktar'] as num).toStringAsFixed(1),
                                  style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7))),
          Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
