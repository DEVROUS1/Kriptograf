import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../providers/selected_coin_provider.dart';

class CoinSelector extends ConsumerWidget {
  const CoinSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coin = ref.watch(selectedCoinProvider);

    return Row(children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: coin.symbol,
              dropdownColor: AppTheme.surfaceVariant,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              icon: Icon(Icons.expand_more_rounded,
                  color: Colors.white.withValues(alpha: 0.4), size: 18),
              items: AppConfig.supportedSymbols
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.toUpperCase().replaceAll('USDT', '/USDT')),
                      ))
                  .toList(),
              onChanged: (s) =>
                  ref.read(selectedCoinProvider.notifier).setSymbol(s!),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      ...['1m', '5m', '15m', '1h', '4h', '1d'].map((i) {
        final isSelected = i == coin.interval;
        final color =
            isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.3);
        return GestureDetector(
          onTap: () => ref.read(selectedCoinProvider.notifier).setInterval(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }),
    ]);
  }
}
