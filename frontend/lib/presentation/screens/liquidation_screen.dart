import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../providers/selected_coin_provider.dart';
import '../providers/market_provider.dart';
import '../widgets/common/shimmer_card.dart';
import '../widgets/liquidity_heatmap_widget.dart' show liquidityProvider;

class LiquidationScreen extends ConsumerStatefulWidget {
  const LiquidationScreen({super.key});

  @override
  ConsumerState<LiquidationScreen> createState() => _LiquidationScreenState();
}

class _LiquidationScreenState extends ConsumerState<LiquidationScreen> {
  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(selectedCoinProvider);
    final markets = ref.watch(marketListProvider);
    final market = markets.firstWhere((m) => m.symbol == coin.symbol, 
        orElse: () => markets.isNotEmpty ? markets.first : throw Exception());

    if (markets.isEmpty) {
      return const ShimmerCard(height: double.infinity);
    }
    
    final dataAsync = ref.watch(liquidityProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: AppTheme.warning),
                const SizedBox(width: 8),
                Text('${coin.symbol} LİKİDİTE DERİNLİK HARİTASI (Gerçek-Zamanlı)',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  child: const Text('Binance Futures API', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: dataAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16.0),
                child: ShimmerCard(height: double.infinity),
              ),
              error: (err, stack) => Center(child: Text('Veri alınamadı: $err', style: const TextStyle(color: AppTheme.bearish))),
              data: (data) => _buildRealHeatmap(context, data, market.price),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealHeatmap(BuildContext context, Map<String, dynamic> data, double currentPrice) {
    // API'den gelen gerçek Satış (Direnç) ve Alış (Destek) Duvarları
    final satis = (data['satis_duvarlari'] as List).cast<Map<String, dynamic>>();
    final alis = (data['alis_duvarlari'] as List).cast<Map<String, dynamic>>();

    double maxUsd = 1.0;
    
    List<Map<String, dynamic>> parseWall(List<Map<String, dynamic>> walls) {
      return walls.map((w) {
        final double fiyat = (w['fiyat'] as num).toDouble();
        final double miktar = (w['miktar'] as num).toDouble();
        final double usd = fiyat * miktar;
        if (usd > maxUsd) maxUsd = usd;
        return {'fiyat': fiyat, 'usd': usd};
      }).toList();
    }

    final shortLiqs = parseWall(satis);
    // Shortları en uzaktan en yakına doğru sıralamak (artan sırayla fiyat)
    shortLiqs.sort((a, b) => (b['fiyat'] as double).compareTo(a['fiyat'] as double));
    
    final longLiqs = parseWall(alis);
    // Longları fiyata en yakından uzağa doğru sıralamak (azalan sırayla fiyat)
    longLiqs.sort((a, b) => (b['fiyat'] as double).compareTo(a['fiyat'] as double));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 60, right: 60,
            child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          ),
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...shortLiqs.take(7).map((e) => _buildHeatBar(e, currentPrice, maxUsd, AppTheme.warning, true)),
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          '\$${Formatters.formatKriptoFiyat(currentPrice)}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                ...longLiqs.take(7).map((e) => _buildHeatBar(e, currentPrice, maxUsd, AppTheme.bullish, false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatBar(Map<String, dynamic> data, double currentPrice, double maxUsd, Color baseColor, bool isShort) {
    final double usdValue = data['usd'];
    final double f = data['fiyat'];
    final double ratio = (usdValue / maxUsd).clamp(0.05, 1.0);
    
    final double yuzde = ((f - currentPrice) / currentPrice) * 100;
    final String yuzdeStr = '${yuzde > 0 ? '+' : ''}${yuzde.toStringAsFixed(1)}%';

    final milyonUsd = usdValue / 1000000;
    final binUsd = usdValue / 1000;
    final valueText = milyonUsd >= 1.0 
      ? '${milyonUsd.toStringAsFixed(1)}M likidite' 
      : '${binUsd.toStringAsFixed(0)}K likidite';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            child: Text('\$${Formatters.formatKriptoFiyat(f)}', 
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: baseColor.withValues(alpha: 0.2 + (ratio * 0.4)),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(color: baseColor.withValues(alpha: ratio * 0.5), blurRadius: ratio * 15)
                      ]
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(valueText, 
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(4)),
                        child: Text(isShort ? 'DİRENÇ' : 'DESTEK', style: const TextStyle(color: Colors.white70, fontSize: 9)),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(yuzdeStr, 
                textAlign: TextAlign.right,
                style: TextStyle(color: isShort ? AppTheme.warning : AppTheme.bullish, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
