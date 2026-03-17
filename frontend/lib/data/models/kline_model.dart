class KlineModel {
  final int openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final int closeTime;
  final bool isClosed;
  final double quoteVolume;
  final int numberOfTrades;

  const KlineModel({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.closeTime,
    required this.isClosed,
    this.quoteVolume = 0.0,
    this.numberOfTrades = 0,
  });

  factory KlineModel.fromJson(Map<String, dynamic> json) {
    final k = (json['k'] as Map<String, dynamic>?) ?? json;
    return KlineModel(
      openTime: (k['t'] as num?)?.toInt() ?? 0,
      open: double.tryParse(k['o']?.toString() ?? '') ?? 0.0,
      high: double.tryParse(k['h']?.toString() ?? '') ?? 0.0,
      low: double.tryParse(k['l']?.toString() ?? '') ?? 0.0,
      close: double.tryParse(k['c']?.toString() ?? '') ?? 0.0,
      volume: double.tryParse(k['v']?.toString() ?? '') ?? 0.0,
      closeTime: (k['T'] as num?)?.toInt() ?? 0,
      isClosed: k['x'] as bool? ?? false,
      quoteVolume: double.tryParse(k['q']?.toString() ?? '') ?? 0.0,
      numberOfTrades: (k['n'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isBullish => close >= open;
  double get range => high - low;
}