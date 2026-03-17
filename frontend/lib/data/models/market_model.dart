class MarketModel {
  final String symbol;
  final double price;
  final double changePercent;
  final double volume;
  final double high24h;
  final double low24h;

  MarketModel({
    required this.symbol,
    required this.price,
    required this.changePercent,
    this.volume = 0.0,
    this.high24h = 0.0,
    this.low24h = 0.0,
  });

  factory MarketModel.fromJson(Map<String, dynamic> json) {
    return MarketModel(
      symbol: json['symbol'] as String,
      price: (json['price'] as num).toDouble(),
      changePercent: (json['change_percent'] as num).toDouble(),
      volume: json['volume'] != null ? (json['volume'] as num).toDouble() : 0.0,
      high24h: json['high_24h'] != null ? (json['high_24h'] as num).toDouble() : 0.0,
      low24h: json['low_24h'] != null ? (json['low_24h'] as num).toDouble() : 0.0,
    );
  }
}
