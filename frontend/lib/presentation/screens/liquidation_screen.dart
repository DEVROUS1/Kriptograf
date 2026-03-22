import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../providers/selected_coin_provider.dart';
import '../providers/market_provider.dart';
import '../widgets/common/shimmer_card.dart';

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

    final price = market.price;
    final List<Map<String, dynamic>> shortLiqs = [
      {'fiyat': price * 1.01, 'milyon': 25.4, 'kaldirac': '100x'},
      {'fiyat': price * 1.02, 'milyon': 68.2, 'kaldirac': '50x'},
      {'fiyat': price * 1.05, 'milyon': 140.5, 'kaldirac': '20x'},
      {'fiyat': price * 1.10, 'milyon': 350.8, 'kaldirac': '10x'},
    ];
    final List<Map<String, dynamic>> longLiqs = [
      {'fiyat': price * 0.99, 'milyon': 30.1, 'kaldirac': '100x'},
      {'fiyat': price * 0.98, 'milyon': 85.6, 'kaldirac': '50x'},
      {'fiyat': price * 0.95, 'milyon': 180.2, 'kaldirac': '20x'},
      {'fiyat': price * 0.90, 'milyon': 290.0, 'kaldirac': '10x'},
    ];

    double maxMilyon = 400.0; // Isı haritası için maksimum referans

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
                Text('${coin.symbol} LİKİDASYON ISI HARİTASI (Tahmini)',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                const Spacer(),
                const Text('Canlı', style: TextStyle(color: AppTheme.bullish, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ortadaki ana çizgi
                  Positioned(
                    left: 60,
                    right: 60,
                    child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // SHORT Likidasyonları (Tepede)
                      ...shortLiqs.reversed.map((e) => _buildHeatBar(e, price, maxMilyon, AppTheme.warning, true)),
                      
                      // Mevcut Fiyat
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
                                '\$${Formatters.formatKriptoFiyat(price)}',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // LONG Likidasyonları (Altta)
                      ...longLiqs.map((e) => _buildHeatBar(e, price, maxMilyon, AppTheme.bullish, false)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatBar(Map<String, dynamic> data, double currentPrice, double max, Color baseColor, bool isShort) {
    final double milyon = data['milyon'];
    final double f = data['fiyat'];
    final double ratio = (milyon / max).clamp(0.1, 1.0);
    
    // Yüzde hesabı
    final double yuzde = ((f - currentPrice) / currentPrice) * 100;
    final String yuzdeStr = '${yuzde > 0 ? '+' : ''}${yuzde.toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
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
                      Text('${milyon.toStringAsFixed(1)}M likidite', 
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(4)),
                        child: Text(data['kaldirac'], style: const TextStyle(color: Colors.white70, fontSize: 9)),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(yuzdeStr, 
                textAlign: TextAlign.right,
                style: TextStyle(color: isShort ? AppTheme.warning : AppTheme.bullish, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
