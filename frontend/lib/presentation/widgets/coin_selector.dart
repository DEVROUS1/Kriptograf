import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../providers/selected_coin_provider.dart';
import '../providers/dashboard_provider.dart';

class CoinSelector extends ConsumerStatefulWidget {
  const CoinSelector({super.key});

  @override
  ConsumerState<CoinSelector> createState() => _CoinSelectorState();
}

class _CoinSelectorState extends ConsumerState<CoinSelector> {
  void _showCoinMenu(BuildContext context, String currentSymbol) async {
    // Arama açıldığında grafiğin (iframe) pointer olaylarını yutmasını engellemek için state bildirimi:
    ref.read(isSearchOpenProvider.notifier).state = true;
    
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: _CoinSearchDialog(
            currentSymbol: currentSymbol,
            onSelected: (sym) {
              ref.read(selectedCoinProvider.notifier).setSymbol(sym);
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
    
    // Dialog kapandı, pointer serbest
    ref.read(isSearchOpenProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(selectedCoinProvider);

    return Row(children: [
      Expanded(
        flex: 3,
        child: InkWell(
          onTap: () => _showCoinMenu(context, coin.symbol),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    coin.symbol.toUpperCase().replaceAll('USDT', '/USDT'),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.4), size: 16),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 5,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: ['1m', '5m', '15m', '1h', '4h', '1d'].map((i) {
              final isSelected = i == coin.interval;
              final color =
                  isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.4);
              return GestureDetector(
                onTap: () => ref.read(selectedCoinProvider.notifier).setInterval(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.2)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                  child: Text(
                    AppConfig.intervalLabels[i] ?? i,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ]);
  }
}

class _CoinSearchDialog extends StatefulWidget {
  final String currentSymbol;
  final ValueChanged<String> onSelected;

  const _CoinSearchDialog({required this.currentSymbol, required this.onSelected});

  @override
  State<_CoinSearchDialog> createState() => _CoinSearchDialogState();
}

class _CoinSearchDialogState extends State<_CoinSearchDialog> {
  String _query = '';
  
  @override
  Widget build(BuildContext context) {
    final filtered = AppConfig.supportedSymbols
        .where((s) => s.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Container(
      width: double.maxFinite,
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Coin Ara (Örn: BTC)',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final sym = filtered[index];
                  final isSelected = sym == widget.currentSymbol;
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    tileColor: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : null,
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
                      radius: 18,
                      child: Icon(
                        Icons.currency_bitcoin_rounded,
                        size: 20,
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    title: Text(
                      sym.toUpperCase().replaceAll('USDT', '/USDT'),
                      style: TextStyle(
                        color: isSelected ? AppTheme.primary : Colors.white,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    onTap: () => widget.onSelected(sym),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
