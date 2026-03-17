import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/whale_provider.dart';
import '../../data/models/whale_model.dart';

class WhaleWidget extends ConsumerWidget {
  const WhaleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final whaleAsync = ref.watch(whaleProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(),
          whaleAsync.when(
            data: (stats) => _Body(stats: stats),
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Veri alınamadı', style: TextStyle(color: AppTheme.bearish, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: const Color(0xFF6C63FF), shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          const Text('BALİNA HAREKETLERİ',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: Color(0xFF5a6080), letterSpacing: 0.8)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('\$500K+',
                style: TextStyle(fontSize: 9, color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.stats});
  final WhaleStatsModel stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Alış/Satış oranı barı
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ALIŞ ${stats.aliYuzde.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 10, color: AppTheme.bullish, fontWeight: FontWeight.w700)),
                  Text('SATIŞ ${(100 - stats.aliYuzde).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 10, color: AppTheme.bearish, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      Flexible(
                        flex: stats.aliYuzde.round(),
                        child: Container(color: AppTheme.bullish),
                      ),
                      Flexible(
                        flex: (100 - stats.aliYuzde).round(),
                        child: Container(color: AppTheme.bearish),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmtUsd(stats.alisHacimUsd),
                      style: TextStyle(fontSize: 11, color: AppTheme.bullish, fontWeight: FontWeight.w600)),
                  Text(_fmtUsd(stats.satisHacimUsd),
                      style: TextStyle(fontSize: 11, color: AppTheme.bearish, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // İşlem listesi
        ...stats.islemler.take(8).map((t) => _TradeRow(trade: t)),
      ],
    );
  }

  String _fmtUsd(int v) {
    if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
    return '\$${(v / 1000).toStringAsFixed(0)}K';
  }
}

class _TradeRow extends StatelessWidget {
  const _TradeRow({required this.trade});
  final WhaleTradeModel trade;

  @override
  Widget build(BuildContext context) {
    final color = trade.alismi ? AppTheme.bullish : AppTheme.bearish;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 18,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.center,
            child: Text(trade.yon, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${trade.miktar} ${trade.sembol.replaceAll('USDT', '')}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
          Text(trade.usdFormatli,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(trade.zaman,
              style: const TextStyle(color: Color(0xFF5a6080), fontSize: 10)),
        ],
      ),
    );
  }
}
