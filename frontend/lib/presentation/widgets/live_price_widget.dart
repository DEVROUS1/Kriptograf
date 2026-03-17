import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_provider.dart';
import '../providers/selected_coin_provider.dart';

class LivePriceWidget extends ConsumerWidget {
  const LivePriceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coin = ref.watch(selectedCoinProvider);
    final symbol = coin.symbol.toUpperCase();
    final markets = ref.watch(marketListProvider);
    
    final selectedMarketSet = markets.where((m) => m.symbol == symbol);
    final selectedMarket = selectedMarketSet.isNotEmpty ? selectedMarketSet.first : null;

    if (selectedMarket == null) return const SizedBox.shrink();

    final color = selectedMarket.changePercent >= 0 ? Colors.greenAccent : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                selectedMarket.symbol,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Text(
                '\$${selectedMarket.price.toStringAsFixed(4)}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                '${selectedMarket.changePercent >= 0 ? '+' : ''}${selectedMarket.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 16, color: color),
              ),
            ],
          ),
          Row(
            children: [
              _buildStat('24s Yüksek', '\$${selectedMarket.high24h.toStringAsFixed(4)}'),
              const SizedBox(width: 16),
              _buildStat('24s Düşük', '\$${selectedMarket.low24h.toStringAsFixed(4)}'),
              const SizedBox(width: 16),
              _buildStat('24s Hacim', '\$${(selectedMarket.volume / 1000000).toStringAsFixed(2)}M'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
