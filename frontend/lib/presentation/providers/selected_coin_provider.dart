import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoinSelection {
  final String symbol;
  final String interval;

  const CoinSelection({required this.symbol, required this.interval});

  CoinSelection copyWith({String? symbol, String? interval}) => CoinSelection(
        symbol: symbol ?? this.symbol,
        interval: interval ?? this.interval,
      );

  String get displaySymbol =>
      symbol.toUpperCase().replaceAll('USDT', '/USDT');
}

class SelectedCoinNotifier extends StateNotifier<CoinSelection> {
  SelectedCoinNotifier()
      : super(const CoinSelection(symbol: 'btcusdt', interval: '1m'));

  void setSymbol(String symbol) =>
      state = state.copyWith(symbol: symbol.toLowerCase());

  void setInterval(String interval) =>
      state = state.copyWith(interval: interval);
}

final selectedCoinProvider =
    StateNotifierProvider<SelectedCoinNotifier, CoinSelection>(
  (ref) => SelectedCoinNotifier(),
);
