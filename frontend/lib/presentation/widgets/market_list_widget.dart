import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_provider.dart';
import '../providers/selected_coin_provider.dart';

class MarketListWidget extends ConsumerWidget {
  const MarketListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markets = ref.watch(marketListProvider);
    final coin = ref.watch(selectedCoinProvider);
    final selectedSymbol = coin.symbol.toUpperCase();

    if (markets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: markets.length,
      itemBuilder: (context, index) {
        final market = markets[index];
        final isSelected = market.symbol == selectedSymbol;
        final color = market.changePercent >= 0 ? Colors.greenAccent : Colors.redAccent;

        return ListTile(
          selected: isSelected,
          selectedTileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          title: Text(market.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Vol: \$${(market.volume / 1000000).toStringAsFixed(2)}M'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${market.price.toStringAsFixed(4)}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              Text('${market.changePercent >= 0 ? '+' : ''}${market.changePercent.toStringAsFixed(2)}%', style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
          onTap: () {
            ref.read(selectedCoinProvider.notifier).setSymbol(market.symbol);
          },
        );
      },
    );
  }
}
